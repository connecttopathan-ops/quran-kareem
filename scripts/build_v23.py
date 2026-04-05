#!/usr/bin/env python3
"""
build_v23.py  —  JS-only patch of getquran_cloudflare_deploy_v10.zip -> v23.zip

Root cause fix: v22 loaded all 47 languages at once (4.8MB blocking script in <head>),
hanging the page. This version uses per-language files loaded on demand.

For each surah:
  - Creates /translations/{SNUM}/{lang}.json — one tiny JSON array per language (~5-20KB)
  - Injects a small inline fetchEdition override before </body> that fetches
    /translations/{SNUM}/{lang}.json instead of external APIs
  - Uses localStorage caching exactly like the original

Zero HTML/CSS changes. All other files copied verbatim.
"""

import json, os, re, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT_DIR, 'assets', 'translations')
V10_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
OUT_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v23.zip')

# ── Load translation files ────────────────────────────────────────────────────
print('Loading translations...')
TRANS_DATA = {}
for fname in sorted(os.listdir(TRANS_DIR)):
    if fname.endswith('.json'):
        lang = fname[:-5]
        with open(os.path.join(TRANS_DIR, fname), encoding='utf-8') as f:
            TRANS_DATA[lang] = json.load(f)
print(f'Loaded {len(TRANS_DATA)} languages')


def get_lang_array(lang, snum):
    """Return list of ayah translations for a given lang and surah number."""
    data = TRANS_DATA.get(lang, {})
    surah_data = data.get(str(snum), {})
    if not surah_data:
        return []
    max_ayah = max(int(k) for k in surah_data.keys())
    return [surah_data.get(str(i), '') for i in range(1, max_ayah + 1)]


# fetchEdition override: fetches /translations/{num}/{lang}.json on demand.
# Uses localStorage caching with same key as original (gqv2_{ed}_{num}).
# Falls back to empty array if local file not found (no crash).
FETCH_OVERRIDE = (
    '<script>'
    'async function fetchEdition(ed,num){'
    'var key="gqv2_"+ed+"_"+num;'
    'try{var c=localStorage.getItem(key);if(c)return JSON.parse(c);}catch(e){}'
    'var lang=ed.split(\'.\')[0];'
    'try{'
    'var r=await fetch("/translations/"+num+"/"+lang+".json");'
    'if(!r.ok)return[];'
    'var texts=await r.json();'
    'try{localStorage.setItem(key,JSON.stringify(texts));}catch(e){}'
    'return texts;'
    '}catch(e){return[];}'
    '}'
    '</script>'
)


def patch_html(html):
    """Inject fetchEdition override just before </body>."""
    if '</body>' in html:
        return html.replace('</body>', FETCH_OVERRIDE + '\n</body>', 1)
    return html + '\n' + FETCH_OVERRIDE


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

            # Patch HTML
            html = patch_html(html)
            zout.writestr(item, html.encode('utf-8'))

            # Write per-language JSON files for this surah
            for lang in TRANS_DATA:
                texts = get_lang_array(lang, snum)
                json_bytes = json.dumps(texts, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
                zout.writestr(f'translations/{snum}/{lang}.json', json_bytes)

            surah_count += 1
            if snum % 10 == 0 or snum == 114:
                print(f'  {snum}/114 done')
        else:
            zout.writestr(item, raw)  # copy verbatim

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages — zero HTML/CSS changes')
print(f'Per-language files: {surah_count * len(TRANS_DATA)} files (~5-20KB each)')
