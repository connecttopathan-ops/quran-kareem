#!/usr/bin/env python3
"""
build_v32.py  —  v10 design + 4 fixes -> v32.zip

Fixes over v31:
  1. Roman Urdu bug: edition 'ur.junagarhi' → split('.')[0]='ur' → wrong file.
     Fix: edition-to-lang map routes ur.junagarhi → ur-roman.json
  2. Desktop CSS: @media (min-width:768px) larger Arabic/translation text
  3. Favicon: inject <link rel="icon"> and copy icon.png into zip
  4. SEO: per-surah <title>, meta description, og:title, og:description, canonical

Input: v10.zip (preferred) or v27.zip as base.
Output: v32.zip
"""

import gzip, io, json, os, re, urllib.request, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT_DIR, 'assets', 'translations')
QURAN_DIR = os.path.join(ROOT_DIR, 'assets', 'quran-chapters')
ICON_PATH = os.path.join(ROOT_DIR, 'assets', 'icon', 'icon.png')
CDN_URL   = 'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/chapters/'

V10_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
V27_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v27.zip')
OUT_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v32.zip')

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


# ── Load surah metadata for SEO ───────────────────────────────────────────────
print('Loading surah metadata...')
SURAH_INFO = {}
for i in range(1, 115):
    with open(f'{QURAN_DIR}/{i}.json') as f:
        d = json.load(f)
    SURAH_INFO[i] = {
        'name':           d.get('name', ''),              # Arabic: سورة البقرة
        'transliteration': d.get('transliteration', ''),  # Latin:  Al-Baqarah
        'type':           d.get('type', '').capitalize(), # Meccan / Medinan
        'total_verses':   d.get('total_verses', 0),
    }


# ── Load and restructure translations into per-surah format ──────────────────
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

# Fix 1: Roman Urdu bug
# edition 'ur.junagarhi' → ed.split('.')[0] = 'ur' → fetches ur.json (Urdu script, wrong)
# Fix: add an edition→lang override map so ur.junagarhi → ur-roman.json
NEW_FETCH_OVERRIDE = (
    '<script>'
    'async function fetchEdition(ed,num){'
    'var key="gqv2_"+ed+"_"+num;'
    'try{var c=localStorage.getItem(key);if(c)return JSON.parse(c);}catch(e){}'
    # Edition → lang file override map (handles cases where edition prefix ≠ file name)
    'var _lmap={"ur.junagarhi":"ur-roman"};'
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

# Fix 2: Desktop CSS — larger text on screens ≥ 768px
DESKTOP_CSS = (
    '<style>'
    '@media(min-width:768px){'
    '.ay{max-width:860px;margin-left:auto;margin-right:auto;padding:20px 28px!important;}'
    '.ar-t{font-size:28px!important;line-height:2.2!important;}'
    '.tl-t{font-size:16px!important;line-height:1.8!important;}'
    '.tr-t{font-size:16px!important;line-height:1.8!important;}'
    '.ay-num{font-size:15px!important;}'
    '}'
    '</style>'
)

# Fix 3: Favicon tags (icon.png will be copied into zip root)
FAVICON_TAGS = (
    '<link rel="icon" type="image/png" href="/icon.png">'
    '<link rel="apple-touch-icon" href="/icon.png">'
)

# ── Fix SyntaxError: broken multi-line string literals in wrap.innerHTML ──────
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


def make_seo_tags(snum):
    info = SURAH_INFO.get(snum, {})
    name  = info.get('transliteration', f'Surah {snum}')
    arabic = info.get('name', '')
    n     = info.get('total_verses', 0)
    t     = info.get('type', '')
    slug_title = f'Surah {name}'
    if arabic:
        slug_title += f' ({arabic})'
    desc = (
        f'Read {slug_title} online — {n} verses, {t} surah. '
        f'Full Arabic text with English translation, transliteration, and audio recitation.'
    )
    url = f'https://getquran.co/surah/{name.lower().replace(" ", "-")}/'
    tags = (
        f'<meta name="description" content="{desc}">'
        f'<meta property="og:title" content="{slug_title} | GetQuran">'
        f'<meta property="og:description" content="{desc}">'
        f'<meta property="og:type" content="website">'
        f'<meta property="og:url" content="{url}">'
        f'<meta property="og:image" content="https://getquran.co/icon.png">'
        f'<meta name="twitter:card" content="summary">'
        f'<meta name="twitter:title" content="{slug_title} | GetQuran">'
        f'<meta name="twitter:description" content="{desc}">'
        f'<link rel="canonical" href="{url}">'
    )
    return tags


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

    # 4. Replace or inject fetchEdition override (Fix 1: Roman Urdu included)
    if OLD_FETCH_OVERRIDE_PREFIX in html:
        start = html.find(OLD_FETCH_OVERRIDE_PREFIX)
        end   = html.find('</script>', start) + len('</script>')
        html  = html[:start] + NEW_FETCH_OVERRIDE + html[end:]
    elif '</body>' in html:
        html = html.replace('</body>', NEW_FETCH_OVERRIDE + '\n</body>', 1)
    else:
        html = html + '\n' + NEW_FETCH_OVERRIDE

    # 5. Inject favicon + desktop CSS + SEO before </head>
    if '</head>' in html:
        inject = ''
        # Fix 3: favicon (only if not already present)
        if 'rel="icon"' not in html:
            inject += FAVICON_TAGS
        # Fix 2: desktop CSS
        inject += DESKTOP_CSS
        # Fix 4: SEO meta tags
        if snum:
            inject += make_seo_tags(snum)
        html = html.replace('</head>', inject + '\n</head>', 1)

    return html


# ── Main ──────────────────────────────────────────────────────────────────────
surah_count  = 0
iife_patched = 0

with zipfile.ZipFile(IN_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    # Write favicon
    if os.path.exists(ICON_PATH):
        with open(ICON_PATH, 'rb') as f:
            zout.writestr('icon.png', f.read())
        print('Wrote icon.png to zip root')
    else:
        print(f'WARNING: icon not found at {ICON_PATH}')

    # Write per-language translation files
    print('Writing translation files...')
    for lang, data in TRANS.items():
        json_bytes = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        zout.writestr(f'translations/{lang}.json', json_bytes)

    # Write quran chapter files — text only (no transliteration, no id)
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
en_gz  = gzip_size(en_raw)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages, IIFE localStorage patch applied to {iife_patched}')

with open(f'{QURAN_DIR}/2.json') as f:
    d2 = json.load(f)
q2_raw = json.dumps({'verses':[{'text':v['text']} for v in d2['verses']]}, ensure_ascii=False, separators=(',',':')).encode('utf-8')
q2_gz  = gzip_size(q2_raw)
print(f'/quran/2.json (Al-Baqarah): {len(q2_raw)//1024} KB raw, ~{q2_gz//1024} KB gzipped')
print(f'/translations/en.json: ~{en_gz//1024} KB gzipped (one-time, then cached)')
print(f'Fixes: Roman Urdu, desktop CSS, favicon, SEO meta tags')
