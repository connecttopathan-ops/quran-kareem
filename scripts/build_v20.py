#!/usr/bin/env python3
"""
build_v19.py  —  JS-only patch of getquran_cloudflare_deploy_v10.zip -> v19.zip

For each surah/*/index.html in v10:
  1. Read SNUM from existing JS
  2. Build translations/{SNUM}.js containing:
       - var TRANSLATIONS = {lang: [ayah1, ...], ...}
       - fetchEdition override (reads TRANSLATIONS instead of API)
  3. Inject <script src="/translations/{SNUM}.js" defer></script> before </body>

Zero HTML/CSS changes. All other files copied verbatim.
The defer attribute ensures the translations file loads without blocking
the ayah CDN fetch. Being defer, it executes after inline scripts and
naturally overrides the original fetchEdition.
"""

import json, os, re, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT_DIR, 'assets', 'translations')
V10_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
OUT_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v20.zip')

# ── Load translation files ────────────────────────────────────────────────────
print('Loading translations...')
TRANS_DATA = {}
for fname in sorted(os.listdir(TRANS_DIR)):
    if fname.endswith('.json'):
        lang = fname[:-5]
        with open(os.path.join(TRANS_DIR, fname), encoding='utf-8') as f:
            TRANS_DATA[lang] = json.load(f)
print(f'Loaded {len(TRANS_DATA)} languages')


def build_trans_js(snum):
    """Build translations/SNUM.js content."""
    trans = {}
    for lang, data in TRANS_DATA.items():
        surah_data = data.get(str(snum), {})
        if surah_data:
            max_ayah = max(int(k) for k in surah_data.keys())
            trans[lang] = [surah_data.get(str(i), '') for i in range(1, max_ayah + 1)]
        else:
            trans[lang] = []

    trans_json = json.dumps(trans, ensure_ascii=False, separators=(',', ':'))

    # fetchEdition override — runs after inline scripts (defer), overrides original.
    # Edition IDs are like "en.muhammadali"; split on '.' to get the lang key.
    fetch_override = (
        'async function fetchEdition(ed,num){'
        'var lang=ed.split(\'.\')[0];'
        'return TRANSLATIONS[lang]||TRANSLATIONS[ed]||[];'
        '}'
    )

    return f'var TRANSLATIONS={trans_json};\n{fetch_override}\n'


def patch_html(html, snum):
    """Inject <script src> into </head> — loads before body scripts run,
    so TRANSLATIONS is defined before the ayah-loading IIFE calls changeLang."""
    tag = f'<script src="/translations/{snum}.js"></script>'
    if '</head>' in html:
        return html.replace('</head>', tag + '\n</head>', 1)
    # fallback: before </body>
    if '</body>' in html:
        return html.replace('</body>', tag + '\n</body>', 1)
    return html + '\n' + tag


# ── Main ──────────────────────────────────────────────────────────────────────
if not os.path.exists(V10_ZIP):
    raise SystemExit(f'ERROR: {V10_ZIP} not found')

surah_count = 0
with zipfile.ZipFile(V10_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    for item in zin.infolist():
        raw = zin.read(item.filename)

        m = re.match(r'surah/[^/]+/index\.html$', item.filename)
        if m:
            html = raw.decode('utf-8')
            snum_match = re.search(r'\bSNUM\s*=\s*(\d+)', html)
            if not snum_match:
                print(f'  WARNING: SNUM not found in {item.filename}, skipping')
                zout.writestr(item, raw)
                continue
            snum = int(snum_match.group(1))

            # Patch HTML (inject script tag only)
            html = patch_html(html, snum)
            zout.writestr(item, html.encode('utf-8'))

            # Write translations JS file with TRANSLATIONS + fetchEdition override
            js = build_trans_js(snum)
            zout.writestr(f'translations/{snum}.js', js.encode('utf-8'))

            surah_count += 1
            if snum % 10 == 0 or snum == 114:
                print(f'  {snum}/114 done')
        else:
            zout.writestr(item, raw)  # copy verbatim

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages — zero HTML/CSS changes')
