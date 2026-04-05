#!/usr/bin/env python3
"""
build_v27.py  —  JS-only patch of getquran_cloudflare_deploy_v10.zip -> v27.zip

Fixes large-surah loading on slow mobile connections.

Key fix: patch IIFE to check localStorage cache FIRST before any network fetch.
- Repeat visits: instant rendering (no network needed)
- First visit: still fetches from network, but caches result for next time

The IIFE already WRITES to localStorage (gq_ar_N, gq_tl_N) but never READS from it.
This patch adds the read-first logic.

Also keeps: local /quran/ files, 30s timeout, per-language translations, fetchEdition override.
Zero HTML/CSS changes. All other files copied verbatim.
"""

import json, os, re, urllib.request, zipfile

# Regex to match the IIFE fetch block (handles variable whitespace/newlines across surahs)
IIFE_PATTERN = re.compile(
    r'var res=await fetch\("/quran/"\+SNUM\+"\.json",\{signal:ctrl\.signal\}\);'
    r'\s*clearTimeout\(tmr\);if\(!res\.ok\)throw new Error\("HTTP "\+res\.status\);'
    r'\s*var data=await res\.json\(\),vs=data\.verses\|\|\[\];'
    r'\s*try\{localStorage\.setItem\("gq_ar_"\+SNUM,JSON\.stringify\(vs\.map\(function\(v\)\{return v\.text;\}\)\)\);\}catch\(e\)\{\}'
    r'\s*try\{localStorage\.setItem\("gq_tl_"\+SNUM,JSON\.stringify\(vs\.map\(function\(v\)\{return v\.transliteration;\}\)\)\);\}catch\(e\)\{\}'
)

ROOT_DIR    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR   = os.path.join(ROOT_DIR, 'assets', 'translations')
QURAN_DIR   = os.path.join(ROOT_DIR, 'assets', 'quran-chapters')
V10_ZIP     = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
OUT_ZIP     = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v27.zip')
CDN_URL     = 'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/chapters/'

# ── Download quran chapter files if not already cached ───────────────────────
os.makedirs(QURAN_DIR, exist_ok=True)
missing = [i for i in range(1, 115) if not os.path.exists(f'{QURAN_DIR}/{i}.json')]
if missing:
    print(f'Downloading {len(missing)} quran chapter files (one-time)...')
    for i in missing:
        urllib.request.urlretrieve(f'{CDN_URL}{i}.json', f'{QURAN_DIR}/{i}.json')
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


# ── IIFE localStorage patch ───────────────────────────────────────────────────
# The IIFE already saves arabic+transliteration to localStorage after fetching,
# but never reads from it. This replacement makes it check cache first:
# - If cache hit: build vs[] from cache, skip network fetch entirely
# - If cache miss: fetch from /quran/SNUM.json as before, save to cache

IIFE_NEW = (
    'var _ca=localStorage.getItem("gq_ar_"+SNUM),_ct=localStorage.getItem("gq_tl_"+SNUM);'
    'var vs;'
    'if(_ca&&_ct){try{'
    'var _a=JSON.parse(_ca),_t=JSON.parse(_ct);'
    'vs=_a.map(function(t,i){return{text:t,transliteration:_t[i]||""};});'
    'clearTimeout(tmr);'
    '}catch(e){vs=null;}}'
    'if(!vs){'
    'var res=await fetch("/quran/"+SNUM+".json",{signal:ctrl.signal});'
    'clearTimeout(tmr);if(!res.ok)throw new Error("HTTP "+res.status);'
    'var data=await res.json();vs=data.verses||[];'
    'try{localStorage.setItem("gq_ar_"+SNUM,JSON.stringify(vs.map(function(v){return v.text;})));}catch(e){}'
    'try{localStorage.setItem("gq_tl_"+SNUM,JSON.stringify(vs.map(function(v){return v.transliteration;})));}catch(e){}'
    '}'
)

# fetchEdition override
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
    # 1. Replace CDN URL with local /quran/
    html = html.replace(CDN_URL, '/quran/')
    # 2. Increase timeout 12s -> 30s
    html = html.replace('},12000);', '},30000);')
    # 3. Patch IIFE to check localStorage first (regex handles whitespace variations)
    html, n = IIFE_PATTERN.subn(IIFE_NEW, html, count=1)
    if n == 0:
        print('  WARNING: IIFE pattern not found — localStorage patch skipped')
    # 4. Inject fetchEdition override before </body>
    if '</body>' in html:
        html = html.replace('</body>', FETCH_OVERRIDE + '\n</body>', 1)
    else:
        html = html + '\n' + FETCH_OVERRIDE
    return html


# ── Main ──────────────────────────────────────────────────────────────────────
if not os.path.exists(V10_ZIP):
    raise SystemExit(f'ERROR: {V10_ZIP} not found')

surah_count = 0
iife_patched = 0

with zipfile.ZipFile(V10_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    for lang, data in TRANS_DATA.items():
        json_bytes = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        zout.writestr(f'translations/{lang}.json', json_bytes)

    for snum in range(1, 115):
        with open(f'{QURAN_DIR}/{snum}.json', 'rb') as f:
            zout.writestr(f'quran/{snum}.json', f.read())

    for item in zin.infolist():
        raw = zin.read(item.filename)
        m = re.match(r'surah/[^/]+/index\.html$', item.filename)
        if m:
            html = raw.decode('utf-8')
            snum_match = re.search(r'\bSNUM\s*=\s*(\d+)', html)
            if not snum_match:
                zout.writestr(item, raw)
                continue
            snum = int(snum_match.group(1))
            before = html
            html = patch_html(html)
            if IIFE_NEW in html:
                iife_patched += 1
            zout.writestr(item, html.encode('utf-8'))
            surah_count += 1
            if snum % 10 == 0 or snum == 114:
                print(f'  {snum}/114 done')
        else:
            zout.writestr(item, raw)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages, IIFE localStorage patch applied to {iife_patched}')
print(f'Zero HTML/CSS changes')
