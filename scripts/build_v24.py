#!/usr/bin/env python3
"""
build_v24.py  —  JS-only patch of getquran_cloudflare_deploy_v10.zip -> v24.zip

Fix for v23's 5,358-file count (exceeded Cloudflare's 1,000-file drag-and-drop limit).

Uses 47 per-language files instead of 5,358 per-surah-per-language files:
  /translations/en.json  ->  {"1": ["ayah1",...], "2": [...], ..., "114": [...]}
  /translations/ur.json  ->  same structure
  ... (47 files total)

fetchEdition override:
  - Checks localStorage first (same gqv2_{ed}_{num} key as original)
  - Fetches /translations/{lang}.json (served from browser HTTP cache after first load)
  - Extracts the surah array, caches it in localStorage
  - Returns [] on any error (graceful fallback)

Total new files: 47 translation JSON files + 114 patched HTML files
Zero HTML/CSS changes. All other files copied verbatim.
"""

import json, os, re, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT_DIR, 'assets', 'translations')
V10_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
OUT_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v24.zip')

# ── Load and restructure translation files ────────────────────────────────────
print('Loading translations...')
TRANS_DATA = {}   # lang -> {snum_str -> [ayah1, ayah2, ...]}
for fname in sorted(os.listdir(TRANS_DIR)):
    if fname.endswith('.json'):
        lang = fname[:-5]
        with open(os.path.join(TRANS_DIR, fname), encoding='utf-8') as f:
            raw = json.load(f)
        # Convert {snum: {ayah_num: text}} -> {snum: [text1, text2, ...]}
        restructured = {}
        for snum_str, ayahs in raw.items():
            if not ayahs:
                restructured[snum_str] = []
                continue
            max_ayah = max(int(k) for k in ayahs.keys())
            restructured[snum_str] = [ayahs.get(str(i), '') for i in range(1, max_ayah + 1)]
        TRANS_DATA[lang] = restructured
print(f'Loaded {len(TRANS_DATA)} languages')


# fetchEdition override — fetches /translations/{lang}.json (all surahs for that lang),
# extracts the needed surah array, caches it in localStorage with original key scheme.
FETCH_OVERRIDE = (
    '<script>'
    'async function fetchEdition(ed,num){'
    'var key="gqv2_"+ed+"_"+num;'
    'try{var c=localStorage.getItem(key);if(c)return JSON.parse(c);}catch(e){}'
    'var lang=ed.split(\'.\')[0];'
    'try{'
    'var r=await fetch("/translations/"+lang+".json");'
    'if(!r.ok)return[];'
    'var all=await r.json();'
    'var texts=all[String(num)]||[];'
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

translation_files_written = set()
surah_count = 0

with zipfile.ZipFile(V10_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    # Write all 47 per-language translation files first
    for lang, data in TRANS_DATA.items():
        json_bytes = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        zout.writestr(f'translations/{lang}.json', json_bytes)
        translation_files_written.add(lang)

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
            html = patch_html(html)
            zout.writestr(item, html.encode('utf-8'))

            surah_count += 1
            if snum % 10 == 0 or snum == 114:
                print(f'  {snum}/114 done')
        else:
            zout.writestr(item, raw)  # copy verbatim

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages — zero HTML/CSS changes')
print(f'Translation files: {len(translation_files_written)} (one per language, all surahs)')
