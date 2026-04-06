#!/usr/bin/env python3
"""
build_v33.py  —  v10 design, all fixes -> v33.zip

Fixes over v32:
  1. Roman Urdu: correct edition key ur.abulaalamaududi-la → ur-roman.json
     (v32 had wrong key ur.junagarhi)
  2. Cache version bump gqv2→gqv3: invalidates stale wrong-Urdu per-surah caches
  3. Default English: add US/GB/CA/AU/NZ/IE to geo map; change Middle East
     SA/AE/QA/KW/BH/OM/EG/JO/LB/IQ from ar.muyassar → en.asad
  4. Desktop CSS: Arabic 38px (was 28px < original 1.92rem=30.7px — regression fixed)
     Translation 20px (was 16px = same as original, no improvement)
  5. Favicon: SVG circle (gold #c8a84b with Arabic ق) + fallback PNG
  6. SEO: skip injection — original HTML already has excellent SEO meta tags

Input: v10.zip (preferred) or v27.zip as base.
Output: v33.zip
"""

import gzip, io, json, os, re, urllib.request, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT_DIR, 'assets', 'translations')
QURAN_DIR = os.path.join(ROOT_DIR, 'assets', 'quran-chapters')
ICON_PATH = os.path.join(ROOT_DIR, 'assets', 'icon', 'icon.png')
CDN_URL   = 'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/chapters/'

V10_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
V27_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v27.zip')
OUT_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v33.zip')

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


# ── Load and restructure translations ────────────────────────────────────────
print('Loading translations...')
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

# Fix 1+2: fetchEdition with correct Roman Urdu key + cache version bump gqv2→gqv3
# gqv3 invalidates stale per-surah caches that had wrong Urdu text cached under
# gqv2_ur.abulaalamaududi-la_N keys.
NEW_FETCH_OVERRIDE = (
    '<script>'
    'async function fetchEdition(ed,num){'
    'var key="gqv3_"+ed+"_"+num;'                          # bumped gqv2→gqv3
    'try{var c=localStorage.getItem(key);if(c)return JSON.parse(c);}catch(e){}'
    # Fix 1: correct edition→lang file mapping for Roman Urdu
    'var _lmap={"ur.abulaalamaududi-la":"ur-roman"};'
    'var lang=_lmap[ed]||ed.split(\'.\')[0];'
    'try{'
    'var lc=localStorage.getItem("gq_lang_"+lang);'
    'if(lc){'
    'var all=JSON.parse(lc);'
    'var texts=all[String(num)]||[];'
    'try{localStorage.setItem(key,JSON.stringify(texts));}catch(e){}'
    'return texts;'
    '}}'
    'catch(e){}'
    'try{'
    'var r=await fetch("/translations/"+lang+".json");'
    'if(!r.ok)return[];'
    'var all=await r.json();'
    'try{localStorage.setItem("gq_lang_"+lang,JSON.stringify(all));}catch(e){}'
    'var texts=all[String(num)]||[];'
    'try{localStorage.setItem(key,JSON.stringify(texts));}catch(e){}'
    'return texts;'
    '}catch(e){return[];}'
    '}'
    '</script>'
)

# Fix 3: Updated geo map — English for Middle East + English-speaking countries.
# Original map had SA/AE/QA/KW/EG→ar.muyassar and US/GB/CA/AU not in map at all
# (missing = changeLang never called = translations never load for those users).
OLD_GEO_MAP = (
    'var map={"PK":"ur.abulaalamaududi-la","IN":"ur.abulaalamaududi-la",'
    '"BD":"bn.bengali","ID":"id.indonesian","TR":"tr.diyanet","IR":"fa.ayati",'
    '"SA":"ar.muyassar","AE":"ar.muyassar","QA":"ar.muyassar","KW":"ar.muyassar",'
    '"EG":"ar.muyassar","FR":"fr.hamidullah","DE":"de.bubenheim","RU":"ru.kuliev",'
    '"MY":"ms.basmeih","NG":"ha.gumi","SO":"so.abduh","CN":"zh.majian",'
    '"JP":"ja.japanese","KR":"ko.korean","AZ":"az.musayev","KZ":"kk.altai",'
    '"UZ":"uz.sodik","TJ":"tg.ayni","KG":"ky.nasiri","AL":"sq.nahi","ET":"am.sadiq"};'
)

NEW_GEO_MAP = (
    'var map={"PK":"ur.abulaalamaududi-la","IN":"ur.abulaalamaududi-la",'
    '"BD":"bn.bengali","ID":"id.indonesian","TR":"tr.diyanet","IR":"fa.ayati",'
    # Middle East → English (most useful for meaning; Arabic text already shown)
    '"SA":"en.asad","AE":"en.asad","QA":"en.asad","KW":"en.asad","BH":"en.asad",'
    '"OM":"en.asad","JO":"en.asad","LB":"en.asad","IQ":"en.asad","EG":"en.asad",'
    '"SY":"en.asad","YE":"en.asad","LY":"en.asad","TN":"en.asad","MA":"en.asad","DZ":"en.asad",'
    # English-speaking countries (were missing → translations never loaded)
    '"US":"en.asad","GB":"en.asad","CA":"en.asad","AU":"en.asad","NZ":"en.asad",'
    '"IE":"en.asad","ZA":"en.asad","SG":"en.asad","PH":"en.asad","NG":"en.asad",'
    '"FR":"fr.hamidullah","DE":"de.bubenheim","RU":"ru.kuliev","MY":"ms.basmeih",'
    '"CN":"zh.majian","JP":"ja.japanese","KR":"ko.korean","AZ":"az.musayev",'
    '"KZ":"kk.altai","UZ":"uz.sodik","TJ":"tg.ayni","KG":"ky.nasiri","AL":"sq.nahi","ET":"am.sadiq"};'
)

# Fix 4: Desktop CSS — Arabic 38px (original 1.92rem≈30px, v32 wrongly used 28px)
# Translation 20px (original 1rem=16px)
DESKTOP_CSS = (
    '<style>'
    '@media(min-width:768px){'
    '.ay{max-width:900px;margin-left:auto;margin-right:auto;padding:24px 32px!important;}'
    '.ar-t{font-size:38px!important;line-height:2.3!important;}'
    '.tl-t{font-size:18px!important;line-height:1.9!important;}'
    '.tr-t{font-size:20px!important;line-height:1.9!important;}'
    '.ay-num{font-size:14px!important;}'
    '}'
    '</style>'
)

# Fix 5: SVG favicon — gold circle with Arabic qaf (ق), renders as circle in all browsers
FAVICON_SVG = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
    '<circle cx="50" cy="50" r="50" fill="#c8a84b"/>'
    '<text x="50" y="72" text-anchor="middle" font-size="60" '
    'font-family="Georgia,\'Times New Roman\',serif" fill="#fff" font-weight="bold">'
    '\u0642'   # Arabic letter Qaf — ق
    '</text>'
    '</svg>'
)

# Inject SVG favicon + fallback PNG, replace old PNG-only favicon tags
FAVICON_TAGS = (
    '<link rel="icon" type="image/svg+xml" href="/favicon.svg">'
    '<link rel="icon" type="image/png" href="/icon.png">'
    '<link rel="apple-touch-icon" href="/icon.png">'
)

RENDER_BROKEN = re.compile(
    r'wrap\.innerHTML=vs\.map\(function\(v,i\)\{.*?\}\)\.join\(""\);',
    re.DOTALL
)

RENDER_FIXED = (
    """wrap.innerHTML=vs.map(function(v,i){"""
    """var ae=(v.text||"").split('"').join("&quot;");"""
    """return '<div class="ay" data-n="'+(i+1)+'">"""
    """<div class="ay-top"><span class="ay-num">'+(i+1)+'</span>"""
    """<div class="ay-acts">"""
    """<button class="ay-play" data-n="'+(i+1)+'" onclick="playAyah('+(i+1)+')" title="Play verse">"""
    """<svg width="9" height="9" viewBox="0 0 16 16" fill="currentColor"><path d="M3 2.5v11l10-5.5z"/></svg>"""
    """</button>"""
    """<button class="cp-btn" data-ar="'+(ae)+'">Copy</button>"""
    """<a href="https://apps.apple.com/app/apple-store/id6760704164" class="app-a" target="_blank">App</a>"""
    """</div></div>"""
    """<div class="ar-t" dir="rtl">'+(v.text||"")+' <span class="ay-e">&#64830;'+(i+1)+'&#64831;</span></div>"""
    """<div class="tl-t">'+(v.transliteration||"")+'</div>"""
    """<div class="tr-t">'+(v.translation||"")+'</div>"""
    """</div>';}).join("");"""
)

OLD_FETCH_OVERRIDE_PREFIX = '<script>async function fetchEdition(ed,num){'


def patch_html(html, snum=None):
    # 0. Fix SyntaxError: collapse broken multi-line wrap.innerHTML template
    html, r = RENDER_BROKEN.subn(RENDER_FIXED, html, count=1)
    if r == 0 and 'wrap.innerHTML=vs.map' in html:
        print(f'  WARNING: surah {snum} — render template not fixed')

    # 1. CDN URL → local
    html = html.replace(CDN_URL, '/quran/')

    # 2. Timeout 12s → 30s
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

    # 4. Replace fetchEdition (Fix 1+2: Roman Urdu key + cache version bump)
    if OLD_FETCH_OVERRIDE_PREFIX in html:
        start = html.find(OLD_FETCH_OVERRIDE_PREFIX)
        end   = html.find('</script>', start) + len('</script>')
        html  = html[:start] + NEW_FETCH_OVERRIDE + html[end:]
    elif '</body>' in html:
        html = html.replace('</body>', NEW_FETCH_OVERRIDE + '\n</body>', 1)
    else:
        html = html + '\n' + NEW_FETCH_OVERRIDE

    # 5. Fix 3: Update geo country→language map
    if OLD_GEO_MAP in html:
        html = html.replace(OLD_GEO_MAP, NEW_GEO_MAP, 1)
    else:
        print(f'  WARNING: surah {snum} — geo map not found (may already be patched or different format)')

    # 6. Fix 4+5: Inject desktop CSS + favicon before </head>
    if '</head>' in html:
        inject = ''
        # Replace old favicon tags or inject new ones
        if 'rel="icon"' in html:
            # Remove old favicon tags and replace
            html = re.sub(r'<link rel="icon"[^>]*>', '', html)
            html = re.sub(r'<link rel="apple-touch-icon"[^>]*>', '', html)
        inject += FAVICON_TAGS
        inject += DESKTOP_CSS
        html = html.replace('</head>', inject + '\n</head>', 1)

    return html


# ── Main ──────────────────────────────────────────────────────────────────────
surah_count  = 0
iife_patched = 0
geo_patched  = 0

with zipfile.ZipFile(IN_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    # Write SVG favicon (circular gold icon)
    zout.writestr('favicon.svg', FAVICON_SVG.encode('utf-8'))
    print('Wrote favicon.svg (circular gold icon)')

    # Write PNG icon (for apple-touch-icon fallback)
    if os.path.exists(ICON_PATH):
        with open(ICON_PATH, 'rb') as f:
            zout.writestr('icon.png', f.read())
        print('Wrote icon.png')

    # Write per-language translation files
    print('Writing translation files...')
    for lang, data in TRANS.items():
        json_bytes = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        zout.writestr(f'translations/{lang}.json', json_bytes)

    # Write quran chapter files — text only
    for snum in range(1, 115):
        with open(f'{QURAN_DIR}/{snum}.json') as f:
            data = json.load(f)
        text_only = {'verses': [{'text': v['text']} for v in data['verses']]}
        zout.writestr(f'quran/{snum}.json',
                      json.dumps(text_only, ensure_ascii=False, separators=(',',':')).encode('utf-8'))

    # Patch and copy all HTML + other files
    for item in zin.infolist():
        raw = zin.read(item.filename)
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
            before = html
            html = patch_html(html, snum)
            if IIFE_NEW in html:
                iife_patched += 1
            if NEW_GEO_MAP in html:
                geo_patched += 1
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
en_gz  = gzip_size(en_raw)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Surah pages: {surah_count} patched')
print(f'  IIFE localStorage patch: {iife_patched}')
print(f'  Geo map updated: {geo_patched}')
print(f'/translations/en.json: ~{en_gz//1024} KB gzipped (one-time, then cached)')
print(f'Fixes: Roman Urdu key, gqv3 cache, English defaults (Middle East+EN), desktop CSS 38px/20px, SVG favicon')
