#!/usr/bin/env python3
"""
build_v25.py  —  JS-only patch of getquran_cloudflare_deploy_v10.zip -> v25.zip

Root cause of large-surah failures: the IIFE fetches Arabic ayah data from
cdn.jsdelivr.net (2KB-166KB per surah). On slow connections, the 12-second
AbortController fires and shows "Could not load ayahs".

Fix: bundle all 114 quran-json chapter files locally at /quran/{snum}.json.
Patch the two CDN fetch URLs in the IIFE and loadReadMode to use local files.
Zero external CDN dependency for page content.

Also keeps v24's per-language translation approach (47 files, fetchEdition override).

Zero HTML/CSS changes. All other files copied verbatim.
"""

import json, os, re, urllib.request, zipfile

ROOT_DIR    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR   = os.path.join(ROOT_DIR, 'assets', 'translations')
QURAN_DIR   = os.path.join(ROOT_DIR, 'assets', 'quran-chapters')
V10_ZIP     = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
OUT_ZIP     = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v25.zip')
CDN_URL     = 'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/chapters/'

# ── Download quran chapter files if not already cached ───────────────────────
os.makedirs(QURAN_DIR, exist_ok=True)
missing = [i for i in range(1, 115) if not os.path.exists(f'{QURAN_DIR}/{i}.json')]
if missing:
    print(f'Downloading {len(missing)} quran chapter files (one-time)...')
    for i in missing:
        url = f'{CDN_URL}{i}.json'
        urllib.request.urlretrieve(url, f'{QURAN_DIR}/{i}.json')
        if i % 20 == 0 or i == 114:
            print(f'  {i}/114 downloaded')
    print('Download complete.')
else:
    print(f'Quran chapter files already cached in {QURAN_DIR}')

# ── Load and restructure translation files ────────────────────────────────────
print('Loading translations...')
TRANS_DATA = {}
for fname in sorted(os.listdir(TRANS_DIR)):
    if fname.endswith('.json'):
        lang = fname[:-5]
        with open(os.path.join(TRANS_DIR, fname), encoding='utf-8') as f:
            raw = json.load(f)
        restructured = {}
        for snum_str, ayahs in raw.items():
            if not ayahs:
                restructured[snum_str] = []
                continue
            max_ayah = max(int(k) for k in ayahs.keys())
            restructured[snum_str] = [ayahs.get(str(i), '') for i in range(1, max_ayah + 1)]
        TRANS_DATA[lang] = restructured
print(f'Loaded {len(TRANS_DATA)} languages')

print(f'All 114 quran chapter files ready')


# fetchEdition override — same as v24
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
    """
    1. Replace CDN URLs for quran-json chapter files with local /quran/{snum}.json
    2. Increase AbortController timeout from 12s to 30s (slow mobile connections)
    3. Inject fetchEdition override before </body>
    """
    # Replace CDN URL in both IIFE and loadReadMode
    html = html.replace(CDN_URL, '/quran/')
    # Increase IIFE timeout: 12 seconds is too short on slow/congested mobile
    html = html.replace('},12000);', '},30000);')

    if '</body>' in html:
        html = html.replace('</body>', FETCH_OVERRIDE + '\n</body>', 1)
    else:
        html = html + '\n' + FETCH_OVERRIDE

    return html


# ── Main ──────────────────────────────────────────────────────────────────────
if not os.path.exists(V10_ZIP):
    raise SystemExit(f'ERROR: {V10_ZIP} not found')

surah_count = 0

with zipfile.ZipFile(V10_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    # Write 47 per-language translation files
    print('Writing translation files...')
    for lang, data in TRANS_DATA.items():
        json_bytes = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        zout.writestr(f'translations/{lang}.json', json_bytes)

    # Write 114 local quran chapter files
    print('Writing quran chapter files...')
    for snum in range(1, 115):
        with open(f'{QURAN_DIR}/{snum}.json', 'rb') as f:
            zout.writestr(f'quran/{snum}.json', f.read())

    # Patch surah HTML files
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
            zout.writestr(item, raw)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages — zero HTML/CSS changes')
print(f'Local quran data: 114 files in /quran/')
print(f'Translation data: {len(TRANS_DATA)} files in /translations/')
print(f'Total new files: {114 + len(TRANS_DATA)} (well under Cloudflare 1000-file limit)')
