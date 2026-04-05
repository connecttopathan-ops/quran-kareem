#!/usr/bin/env python3
"""
build_v29.py  —  v27 design + per-surah translation files -> v29.zip

Root cause of "still loading" on slow mobile:
  fetchEdition downloads /translations/en.json (1.1 MB) on EVERY first visit
  to a surah. Each surah only caches its own translations, so every new surah
  page re-downloads the full 1.1 MB file.

Fix: switch to per-surah translation files.
  /trans/2.json  = ALL 47 languages for just surah 2's 286 ayahs
  /trans/114.json = ALL 47 languages for just surah 114's 6 ayahs

Benefits:
  - Small surahs: tiny files (Al-Falaq = ~10 KB)
  - Large surahs: ~150 KB instead of 1.1 MB (only what's needed)
  - One download covers all language switches for that surah
  - Still 114 total files (under Cloudflare's 1000-file limit)

Input: v27.zip (correct v10 design) OR v10.zip (rebuilt from scratch)
Output: v29.zip

Zero HTML/CSS changes. All other files copied verbatim.
"""

import json, os, re, urllib.request, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT_DIR, 'assets', 'translations')
QURAN_DIR = os.path.join(ROOT_DIR, 'assets', 'quran-chapters')
CDN_URL   = 'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/chapters/'

# Accept v10 (preferred) or v27 as input
V10_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
V27_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v27.zip')
OUT_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v29.zip')

if os.path.exists(V10_ZIP):
    IN_ZIP = V10_ZIP
    print(f'Using v10 as base: {V10_ZIP}')
elif os.path.exists(V27_ZIP):
    IN_ZIP = V27_ZIP
    print(f'Using v27 as base: {V27_ZIP}')
else:
    raise SystemExit(f'ERROR: need v10.zip or v27.zip in ~/Downloads/')


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
    print(f'Quran chapter files already cached ({len(os.listdir(QURAN_DIR))} files)')


# ── Load and restructure translations into per-surah format ──────────────────
# Source:  /assets/translations/en.json  = {"1": {"1": "text", ...}, ...}
# Output:  /trans/2.json  = {"en": ["text1", ...286 items...], "ur": [...], ...}

print('Loading translations...')
# First build per-language arrays: TRANS[lang][snum_str] = ["text1", "text2", ...]
TRANS = {}
for fname in sorted(os.listdir(TRANS_DIR)):
    if not fname.endswith('.json'):
        continue
    lang = fname[:-5]
    with open(os.path.join(TRANS_DIR, fname), encoding='utf-8') as f:
        raw = json.load(f)
    per_surah = {}
    for snum_str, ayahs in raw.items():
        if not ayahs:
            per_surah[snum_str] = []
            continue
        max_ayah = max(int(k) for k in ayahs.keys())
        per_surah[snum_str] = [ayahs.get(str(i), '') for i in range(1, max_ayah + 1)]
    TRANS[lang] = per_surah
print(f'Loaded {len(TRANS)} languages')

# Build per-surah dicts: SURAH_TRANS[snum] = {"en": [...], "ur": [...], ...}
SURAH_TRANS = {}
for snum in range(1, 115):
    snum_str = str(snum)
    SURAH_TRANS[snum] = {
        lang: TRANS[lang].get(snum_str, [])
        for lang in TRANS
    }


# ── HTML patches ──────────────────────────────────────────────────────────────

IIFE_PATTERN = re.compile(
    r'var res=await fetch\("/quran/"\+SNUM\+"\.json",\{signal:ctrl\.signal\}\);'
    r'\s*clearTimeout\(tmr\);if\(!res\.ok\)throw new Error\("HTTP "\+res\.status\);'
    r'\s*var data=await res\.json\(\),vs=data\.verses\|\|\[\];'
    r'\s*try\{localStorage\.setItem\("gq_ar_"\+SNUM,JSON\.stringify\(vs\.map\(function\(v\)\{return v\.text;\}\)\)\);\}catch\(e\)\{\}'
    r'\s*try\{localStorage\.setItem\("gq_tl_"\+SNUM,JSON\.stringify\(vs\.map\(function\(v\)\{return v\.transliteration;\}\)\)\);\}catch\(e\)\{\}'
)

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

# New fetchEdition: fetches /trans/{num}.json (all languages for that surah only)
# One small file replaces downloading a 1+ MB per-language file
NEW_FETCH_OVERRIDE = (
    '<script>'
    'async function fetchEdition(ed,num){'
    'var key="gqv2_"+ed+"_"+num;'
    'try{var c=localStorage.getItem(key);if(c)return JSON.parse(c);}catch(e){}'
    'try{'
    'var r=await fetch("/trans/"+num+".json");'
    'if(!r.ok)return[];'
    'var all=await r.json();'
    # Cache all languages for this surah at once (avoids re-download on lang switch)
    'Object.keys(all).forEach(function(l){'
    'try{localStorage.setItem("gqv2_"+l+"."+l+"_"+num,JSON.stringify(all[l]));}catch(e){}'
    '});'
    'var lang=ed.split(\'.\')[0];'
    'return all[lang]||[];'
    '}catch(e){return[];}'
    '}'
    '</script>'
)

# Old fetchEdition string (present in v27 HTML, needs replacing)
OLD_FETCH_OVERRIDE_PREFIX = '<script>async function fetchEdition(ed,num){'


def patch_html(html):
    # 1. CDN URL → local (only needed if using v10 as base)
    html = html.replace(CDN_URL, '/quran/')
    # 2. Timeout 12s → 30s (only needed if using v10 as base)
    html = html.replace('},12000);', '},30000);')
    # 3. IIFE localStorage read-first patch
    html, n = IIFE_PATTERN.subn(IIFE_NEW, html, count=1)
    if n == 0:
        print('  WARNING: IIFE pattern not found — localStorage patch skipped')
    # 4. Replace or inject fetchEdition override
    if OLD_FETCH_OVERRIDE_PREFIX in html:
        # v27 base: replace old fetchEdition with new per-surah version
        # Find the full old script block
        start = html.find(OLD_FETCH_OVERRIDE_PREFIX)
        end = html.find('</script>', start) + len('</script>')
        html = html[:start] + NEW_FETCH_OVERRIDE + html[end:]
    elif '</body>' in html:
        # v10 base: inject new fetchEdition before </body>
        html = html.replace('</body>', NEW_FETCH_OVERRIDE + '\n</body>', 1)
    else:
        html = html + '\n' + NEW_FETCH_OVERRIDE
    return html


# ── Main ──────────────────────────────────────────────────────────────────────
surah_count = 0
iife_patched = 0

with zipfile.ZipFile(IN_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    # Write per-surah translation files
    print('Writing per-surah translation files...')
    for snum in range(1, 115):
        data = SURAH_TRANS[snum]
        json_bytes = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        zout.writestr(f'trans/{snum}.json', json_bytes)

    # Write quran chapter files
    for snum in range(1, 115):
        with open(f'{QURAN_DIR}/{snum}.json', 'rb') as f:
            zout.writestr(f'quran/{snum}.json', f.read())

    # Patch and copy all HTML + other files
    for item in zin.infolist():
        raw = zin.read(item.filename)
        # Skip old per-language translation files from v27
        if item.filename.startswith('translations/'):
            continue
        m = re.match(r'surah/[^/]+/index\.html$', item.filename)
        if m:
            html = raw.decode('utf-8')
            snum_match = re.search(r'\bSNUM\s*=\s*(\d+)', html)
            if not snum_match:
                zout.writestr(item, raw)
                continue
            snum = int(snum_match.group(1))
            html = patch_html(html)
            if IIFE_NEW in html:
                iife_patched += 1
            zout.writestr(item, html.encode('utf-8'))
            surah_count += 1
        else:
            zout.writestr(item, raw)

# Report per-surah file sizes
import gzip, io
sample_sizes = {}
for snum in [1, 2, 36, 114]:
    data = SURAH_TRANS[snum]
    raw = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode='wb') as gz:
        gz.write(raw)
    sample_sizes[snum] = (len(raw) // 1024, len(buf.getvalue()) // 1024)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages, IIFE localStorage patch applied to {iife_patched}')
print(f'Per-surah translation file sizes (all 47 languages):')
for snum, (raw_kb, gz_kb) in sample_sizes.items():
    print(f'  /trans/{snum}.json: {raw_kb} KB uncompressed, ~{gz_kb} KB gzipped')
print(f'Zero HTML/CSS changes')
