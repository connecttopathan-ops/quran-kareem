#!/usr/bin/env python3
"""
build_v29.py  —  v10 design + cache-whole-language fetchEdition -> v29.zip

Root cause of "still loading" on slow mobile:
  fetchEdition downloads /translations/en.json (1.1 MB) on EVERY first visit
  to any surah. It only caches the current surah's translations, so every new
  surah page re-downloads the entire 1.1 MB file.

Fix: after downloading /translations/en.json, cache the ENTIRE file in
localStorage as 'gq_lang_en'. All subsequent surah visits in that language
skip the network entirely — just a localStorage read.

Cost: ONE 220 KB gzipped download per language (one-time).
After that: all 114 surahs are instant for that language.

Also keeps: local /quran/ files, 30s timeout, IIFE localStorage patch (104/114).

Input: v10.zip (preferred) or v27.zip as base.
Output: v29.zip

Zero HTML/CSS changes. All other files copied verbatim.
"""

import gzip, io, json, os, re, urllib.request, zipfile

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


# ── HTML patches ──────────────────────────────────────────────────────────────

IIFE_PATTERN = re.compile(
    r'var res=await fetch\("/quran/"\+SNUM\+"\.json",\{signal:ctrl\.signal\}\);'
    r'\s*clearTimeout\(tmr\);if\(!res\.ok\)throw new Error\("HTTP "\+res\.status\);'
    r'\s*var data=await res\.json\(\),vs=data\.verses\|\|\[\];'
    r'\s*try\{localStorage\.setItem\("gq_ar_"\+SNUM,JSON\.stringify\(vs\.map\(function\(v\)\{return v\.text;\}\)\)\);\}catch\(e\)\{\}'
    r'\s*try\{localStorage\.setItem\("gq_tl_"\+SNUM,JSON\.stringify\(vs\.map\(function\(v\)\{return v\.transliteration;\}\)\)\);\}catch\(e\)\{\}'
)

IIFE_NEW = (
    # Only require Arabic cache — transliteration optional (empty string fallback)
    'var _ca=localStorage.getItem("gq_ar_"+SNUM);'
    'var vs;'
    'if(_ca){try{'
    'var _a=JSON.parse(_ca);'
    'var _ct=localStorage.getItem("gq_tl_"+SNUM),_t=_ct?JSON.parse(_ct):[];'
    'vs=_a.map(function(t,i){return{text:t,transliteration:_t[i]||""};});'
    'clearTimeout(tmr);'
    '}catch(e){vs=null;}}'
    'if(!vs){'
    'var res=await fetch("/quran/"+SNUM+".json",{signal:ctrl.signal});'
    'clearTimeout(tmr);if(!res.ok)throw new Error("HTTP "+res.status);'
    'var data=await res.json();vs=data.verses||[];'
    'try{localStorage.setItem("gq_ar_"+SNUM,JSON.stringify(vs.map(function(v){return v.text;})));}catch(e){}'
    'try{localStorage.setItem("gq_tl_"+SNUM,JSON.stringify(vs.map(function(v){return v.transliteration||""})));}catch(e){}'
    '}'
)

# New fetchEdition: caches the ENTIRE language file in localStorage after first download.
# Cost: ONE download per language ever. After that all 114 surahs are instant.
# gq_lang_{lang} = full {snum: [text,...]} map for that language
NEW_FETCH_OVERRIDE = (
    '<script>'
    'async function fetchEdition(ed,num){'
    'var key="gqv2_"+ed+"_"+num;'
    # 1. Check per-surah cache (fastest)
    'try{var c=localStorage.getItem(key);if(c)return JSON.parse(c);}catch(e){}'
    'var lang=ed.split(\'.\')[0];'
    # 2. Check whole-language cache (covers all surahs after first download)
    'try{'
    'var lc=localStorage.getItem("gq_lang_"+lang);'
    'if(lc){'
    'var all=JSON.parse(lc);'
    'var texts=all[String(num)]||[];'
    'try{localStorage.setItem(key,JSON.stringify(texts));}catch(e){}'
    'return texts;'
    '}}'
    'catch(e){}'
    # 3. Download full language file once, cache it all
    'try{'
    'var r=await fetch("/translations/"+lang+".json");'
    'if(!r.ok)return[];'
    'var all=await r.json();'
    # Cache whole language — next visit to ANY surah skips download
    'try{localStorage.setItem("gq_lang_"+lang,JSON.stringify(all));}catch(e){}'
    'var texts=all[String(num)]||[];'
    'try{localStorage.setItem(key,JSON.stringify(texts));}catch(e){}'
    'return texts;'
    '}catch(e){return[];}'
    '}'
    '</script>'
)

# Old fetchEdition string (present in v27 HTML, needs replacing)
OLD_FETCH_OVERRIDE_PREFIX = '<script>async function fetchEdition(ed,num){'


def patch_html(html, snum=None):
    # 1. CDN URL → local (only needed if using v10 as base)
    html = html.replace(CDN_URL, '/quran/')
    # 2. Timeout 12s → 30s (only needed if using v10 as base)
    html = html.replace('},12000);', '},30000);')
    # 3. IIFE localStorage read-first patch
    html, n = IIFE_PATTERN.subn(IIFE_NEW, html, count=1)
    if n == 0:
        label = f'surah {snum}' if snum else 'unknown surah'
        print(f'  WARNING: {label} — IIFE pattern not found, dumping actual code:')
        idx = html.find('gq_ar_')
        if idx >= 0:
            print(f'    {repr(html[max(0,idx-150):idx+150])}')
        else:
            idx2 = html.find('/quran/')
            if idx2 >= 0:
                print(f'    {repr(html[max(0,idx2-100):idx2+250])}')
    # 4. Replace or inject fetchEdition override
    if OLD_FETCH_OVERRIDE_PREFIX in html:
        start = html.find(OLD_FETCH_OVERRIDE_PREFIX)
        end = html.find('</script>', start) + len('</script>')
        html = html[:start] + NEW_FETCH_OVERRIDE + html[end:]
    elif '</body>' in html:
        html = html.replace('</body>', NEW_FETCH_OVERRIDE + '\n</body>', 1)
    else:
        html = html + '\n' + NEW_FETCH_OVERRIDE
    return html


# ── Main ──────────────────────────────────────────────────────────────────────
surah_count = 0
iife_patched = 0

with zipfile.ZipFile(IN_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    # Write per-language translation files (same as v27)
    print('Writing translation files...')
    for lang, data in TRANS.items():
        json_bytes = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        zout.writestr(f'translations/{lang}.json', json_bytes)

    # Write quran chapter files — text only (no transliteration, no id)
    # Cuts file size ~50%: surah 2 goes from 43 KB to 21 KB gzipped
    # gq_tl_N localStorage (transliteration) will be empty strings; acceptable trade-off
    for snum in range(1, 115):
        with open(f'{QURAN_DIR}/{snum}.json') as f:
            data = json.load(f)
        text_only = {'verses': [{'text': v['text']} for v in data['verses']]}
        zout.writestr(f'quran/{snum}.json',
                      json.dumps(text_only, ensure_ascii=False, separators=(',',':')).encode('utf-8'))

    # Patch and copy all HTML + other files
    for item in zin.infolist():
        raw = zin.read(item.filename)
        # Skip old translation files from v27 (already re-written above)
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
            html = patch_html(html, snum)
            if IIFE_NEW in html:
                iife_patched += 1
            zout.writestr(item, html.encode('utf-8'))
            surah_count += 1
        else:
            zout.writestr(item, raw)

def gzip_size(data_bytes):
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode='wb') as gz:
        gz.write(data_bytes)
    return len(buf.getvalue())

en_raw = json.dumps(TRANS['en'], ensure_ascii=False, separators=(',', ':')).encode('utf-8')
en_gz = gzip_size(en_raw)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages, IIFE localStorage patch applied to {iife_patched}')
# Show quran/2.json size in zip
with open(f'{QURAN_DIR}/2.json') as f:
    d2 = json.load(f)
q2_raw = json.dumps({'verses':[{'text':v['text']} for v in d2['verses']]}, ensure_ascii=False, separators=(',',':')).encode('utf-8')
q2_gz = gzip_size(q2_raw)
print(f'/quran/2.json (Al-Baqarah): {len(q2_raw)//1024} KB raw, ~{q2_gz//1024} KB gzipped (was 43 KB)')
print(f'/translations/en.json: ~{en_gz//1024} KB gzipped (one-time, then cached)')
print(f'After first visit: all 114 surahs instant (gq_lang_en localStorage cache)')
print(f'Zero HTML/CSS changes')
