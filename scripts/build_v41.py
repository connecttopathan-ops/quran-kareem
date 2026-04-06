#!/usr/bin/env python3
"""
build_v41.py  —  v10 design, all fixes -> v41.zip

Fixes over v39:
  1. /app URL: create app/index.html from scratch with real content.
     app.html has a server-side 307 redirect (Cloudflare Pretty URLs) so
     it can never be served at a URL — any copy of it loops.
     New page matches site design: dark theme, gold accents, iOS + Android
     download buttons, app feature list.

All previous fixes retained:
  - sitemap.xml (114 surahs) + robots.txt
  - Transliteration restored + gq_cv=38 cache invalidation
  - Circular black favicon
  - Roman Urdu key fix, gqv3 cache bump
  - English defaults for Middle East + English-speaking countries
  - Desktop CSS (Arabic 38px, translation 20px)

Input: v10.zip (preferred) or v27.zip as base.
Output: v41.zip
"""

import base64, gzip, io, json, os, re, urllib.request, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT_DIR, 'assets', 'translations')
QURAN_DIR = os.path.join(ROOT_DIR, 'assets', 'quran-chapters')
ICON_PATH = os.path.join(ROOT_DIR, 'assets', 'icon', 'icon.png')
CDN_URL   = 'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/chapters/'

V10_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
V27_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v27.zip')
OUT_ZIP  = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v41.zip')

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

# Fix 2: Circular favicon — clips actual icon.png (black bg + gold crescent) to a circle.
# Uses base64-embedded PNG inside SVG clipPath so it works as a standalone favicon
# without external resource requests (which some browsers block for favicons).
def make_circular_favicon_svg():
    with open(ICON_PATH, 'rb') as f:
        b64 = base64.b64encode(f.read()).decode('ascii')
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 100 100">'
        '<defs><clipPath id="c"><circle cx="50" cy="50" r="50"/></clipPath></defs>'
        f'<image href="data:image/png;base64,{b64}" '
        'width="100" height="100" clip-path="url(#c)"/>'
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

SITE_URL = 'https://getquran.co'

def to_slug(name):
    s = name.lower()
    s = re.sub(r"['\u2019\u02bc]", '', s)      # remove apostrophes
    s = re.sub(r'[^a-z0-9\s-]', '', s)
    s = re.sub(r'\s+', '-', s.strip())
    return s

def build_sitemap():
    from datetime import date
    today = date.today().isoformat()
    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
             f'  <url><loc>{SITE_URL}/</loc><changefreq>monthly</changefreq><priority>1.0</priority></url>']
    for i in range(1, 115):
        with open(f'{QURAN_DIR}/{i}.json') as f:
            d = json.load(f)
        slug = to_slug(d.get('transliteration', f'surah-{i}'))
        lines.append(
            f'  <url>'
            f'<loc>{SITE_URL}/surah/{slug}/</loc>'
            f'<lastmod>{today}</lastmod>'
            f'<changefreq>monthly</changefreq>'
            f'<priority>0.9</priority>'
            f'</url>'
        )
    lines.append('</urlset>')
    return '\n'.join(lines)

ROBOTS_TXT = f'User-agent: *\nAllow: /\nSitemap: {SITE_URL}/sitemap.xml\n'

# app/index.html — built from scratch so /app works without redirect loops.
# app.html in v10.zip gets a server-side 307 (Cloudflare Pretty URLs) so it
# can never be served directly; any copy of it loops. This page is original.
APP_PAGE_HTML = '''<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=5">
<title>Get the Quran App — 45+ Languages | GetQuran.co</title>
<meta name="description" content="Free Quran app with full Arabic text in 45+ languages including Roman Urdu, English, Hindi, Bengali. Prayer times, Qibla compass, Adhan alerts. No ads, completely free.">
<link rel="canonical" href="https://getquran.co/app">
<meta property="og:title" content="Get the Quran App — GetQuran.co">
<meta property="og:description" content="Free Quran app — 45+ languages, prayer times, Qibla, Adhan. Available on iOS and Android.">
<meta property="og:url" content="https://getquran.co/app">
<meta property="og:image" content="https://getquran.co/screenshot-1.jpg">
<link rel="icon" type="image/svg+xml" href="/favicon.svg">
<link rel="icon" type="image/png" href="/icon.png">
<link rel="apple-touch-icon" href="/icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&family=Cinzel:wght@400;600&family=EB+Garamond:wght@400;500&display=swap" rel="stylesheet">
<script async src="https://www.googletagmanager.com/gtag/js?id=G-LY07NK00LJ"></script>
<script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag('js',new Date());gtag('config','G-LY07NK00LJ');</script>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
[data-theme="dark"]{
  --bg:#0f0e0b;--bg2:#141209;
  --b1:rgba(200,170,80,.09);--b2:rgba(200,170,80,.18);
  --gd:#c8a84b;--glt:#e2c97e;--gdk:#8a6820;--gdim:rgba(200,168,75,.12);
  --ink:#f5f0e8;--txt:#e8e0cc;--txm:#a89070;--txd:#6e6252;
  --nav:rgba(15,14,11,.97);
}
[data-theme="light"]{
  --bg:#fdfcf8;--bg2:#f7f4ed;
  --b1:rgba(140,110,60,.1);--b2:rgba(140,110,60,.2);
  --gd:#c8a84b;--glt:#e2c97e;--gdk:#8a6820;--gdim:rgba(200,168,75,.12);
  --ink:#06080a;--txt:#1c1a14;--txm:#5c5444;--txd:#a09070;
  --nav:rgba(253,252,248,.97);
}
body{background:var(--bg);color:var(--txt);font-family:"EB Garamond",Georgia,serif;min-height:100vh;}
nav{position:sticky;top:0;z-index:200;height:52px;background:var(--nav);
  backdrop-filter:blur(18px);border-bottom:.5px solid var(--b2);
  padding:0 20px;display:flex;align-items:center;gap:10px;}
.brand{display:flex;align-items:center;gap:6px;text-decoration:none;}
.cres{color:var(--gd);font-size:.9rem;}
.bname{font-family:"Cinzel",serif;font-size:.72rem;font-weight:600;
  letter-spacing:.14em;text-transform:uppercase;color:var(--glt);}
.nav-r{margin-left:auto;display:flex;align-items:center;gap:10px;}
.nav-r a{font-family:"Cinzel",serif;font-size:.6rem;font-weight:600;
  letter-spacing:.1em;text-transform:uppercase;color:var(--txm);text-decoration:none;}
.nav-r a:hover{color:var(--gd);}
.hero{text-align:center;padding:72px 20px 48px;max-width:700px;margin:0 auto;}
.hero-icon{width:96px;height:96px;border-radius:50%;margin:0 auto 28px;display:block;}
.hero h1{font-family:"Cinzel",serif;font-size:2rem;font-weight:600;
  color:var(--glt);letter-spacing:.06em;margin-bottom:12px;line-height:1.3;}
.hero p{font-size:1.15rem;color:var(--txm);line-height:1.8;margin-bottom:36px;}
.badges{display:flex;gap:14px;justify-content:center;flex-wrap:wrap;}
.badge{display:flex;align-items:center;gap:12px;
  background:var(--ink);color:var(--bg);
  padding:13px 22px;text-decoration:none;border-radius:12px;
  transition:opacity .2s;min-width:160px;}
.badge:hover{opacity:.85;}
.badge-ios{background:linear-gradient(135deg,#1a1a1a,#000);}
.badge-android{background:linear-gradient(135deg,#1a2a1a,#0d1a0d);}
.badge svg{flex-shrink:0;}
.badge-text{text-align:left;}
.badge-sub{display:block;font-size:.68rem;opacity:.7;font-family:"Cinzel",serif;
  letter-spacing:.08em;text-transform:uppercase;color:#fff;}
.badge-name{display:block;font-size:1.05rem;font-weight:700;color:#fff;
  font-family:"Cinzel",serif;letter-spacing:.04em;}
.features{max-width:860px;margin:56px auto;padding:0 20px;
  display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;}
.feat{background:var(--bg2);border:.5px solid var(--b1);padding:22px 20px;}
.feat-icon{font-size:1.6rem;margin-bottom:10px;}
.feat h3{font-family:"Cinzel",serif;font-size:.78rem;letter-spacing:.1em;
  color:var(--gd);text-transform:uppercase;margin-bottom:7px;}
.feat p{font-size:.95rem;color:var(--txm);line-height:1.7;}
.cta{text-align:center;padding:48px 20px 72px;}
.cta a{font-family:"Cinzel",serif;font-size:.7rem;font-weight:600;
  letter-spacing:.14em;text-transform:uppercase;color:var(--txd);
  text-decoration:none;border-bottom:.5px solid var(--b2);padding-bottom:3px;}
.cta a:hover{color:var(--gd);}
@media(max-width:600px){
  .hero h1{font-size:1.5rem;}
  .badges{flex-direction:column;align-items:center;}
  .badge{min-width:220px;}
}
</style>
</head>
<body>
<nav>
  <a href="/" class="brand"><span class="cres">&#9789;</span><span class="bname">GetQuran</span></a>
  <div class="nav-r">
    <a href="/quran/">Read Quran</a>
    <a href="/app" style="color:var(--gd)">Get the App</a>
  </div>
</nav>
<div class="hero">
  <img src="/icon.png" alt="GetQuran App Icon" class="hero-icon">
  <h1>The Holy Quran<br>in Your Pocket</h1>
  <p>Full Arabic text with translations in 45+ languages.<br>
     Prayer times, Qibla compass, Adhan alerts &mdash; completely free.</p>
  <div class="badges">
    <a href="https://apps.apple.com/app/apple-store/id6760704164?pt=128662757&ct=getquran.co&mt=8"
       class="badge badge-ios" target="_blank" rel="noopener">
      <svg width="28" height="28" viewBox="0 0 814 1000" fill="#fff">
        <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76 0-103.7 40.8-165.9 40.8s-105-57.8-155.5-127.4C46 790.7 0 663 0 541.8c0-207.8 135.4-317.7 269-317.7 70.1 0 128.4 46.4 172.5 46.4 42.8 0 109.6-49 192.5-49 31 0 113.4 2.5 174.6 65.7zm-234.6-72.5c-24.6 29.7-64.7 52.8-104.5 52.8-5.8 0-11.5-.6-17.4-1.9 0-40.8 19.4-82.9 45.2-109.7 31-33.2 85-59 131.5-60.3 5.2 38.2-11.3 77.9-54.8 118.1z"/>
      </svg>
      <div class="badge-text">
        <span class="badge-sub">Download on the</span>
        <span class="badge-name">App Store</span>
      </div>
    </a>
    <a href="https://play.google.com/store/apps/details?id=co.getquran.app"
       class="badge badge-android" target="_blank" rel="noopener">
      <svg width="28" height="28" viewBox="0 0 512 512" fill="#fff">
        <path d="M325.3 234.3L104.6 13l280.8 161.2-60.1 60.1zM47 0C34 6.8 25.3 19.2 25.3 35.3v441.3c0 16.1 8.7 28.5 21.7 35.3l236.6-256L47 0zm425.2 225.6l-58.9-34.1-65.7 64.5 65.7 64.5 60.1-34.1c17-9.7 17-35.4-.2-44.8v-20zM104.6 499l280.8-161.2-60.1-60.1L104.6 499z"/>
      </svg>
      <div class="badge-text">
        <span class="badge-sub">Get it on</span>
        <span class="badge-name">Google Play</span>
      </div>
    </a>
  </div>
</div>
<div class="features">
  <div class="feat"><div class="feat-icon">&#x1F4D6;</div>
    <h3>Full Quran</h3>
    <p>Complete Arabic text with translations in 45+ languages including English, Roman Urdu, Hindi, Bengali, and more.</p>
  </div>
  <div class="feat"><div class="feat-icon">&#x1F54C;</div>
    <h3>Prayer Times</h3>
    <p>Accurate prayer times based on your GPS location. Multiple calculation methods supported.</p>
  </div>
  <div class="feat"><div class="feat-icon">&#x1F9ED;</div>
    <h3>Qibla Compass</h3>
    <p>Find the direction of Mecca from anywhere in the world with the built-in Qibla compass.</p>
  </div>
  <div class="feat"><div class="feat-icon">&#x1F50A;</div>
    <h3>Adhan Alerts</h3>
    <p>Beautiful Adhan notifications for all five daily prayers. Choose between Makkah and Madinah recitations.</p>
  </div>
  <div class="feat"><div class="feat-icon">&#x1F319;</div>
    <h3>Dark Mode</h3>
    <p>Elegant dark and light themes optimised for comfortable reading day and night.</p>
  </div>
  <div class="feat"><div class="feat-icon">&#x2728;</div>
    <h3>Completely Free</h3>
    <p>No ads, no subscriptions, no limits. The full Quran experience for everyone, always free.</p>
  </div>
</div>
<div class="cta">
  <a href="/quran/">Read Quran online &rarr;</a>
</div>
<script>
(function(){
  var t=localStorage.getItem('gq_theme')||'dark';
  document.documentElement.setAttribute('data-theme',t);
})();
</script>
</body>
</html>'''

# Cache invalidation: clears gq_ar_N and gq_tl_N caches from v31-v33 which
# had empty transliteration. Runs once per device, keyed by version '34'.
CACHE_INVALIDATION = (
    '<script>'
    '(function(){'
    'if(localStorage.getItem("gq_cv")==="38")return;'
    'var keys=[];'
    'for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k)keys.push(k);}'
    'keys.forEach(function(k){'
    'if(k.indexOf("gq_ar_")===0||k.indexOf("gq_tl_")===0)localStorage.removeItem(k);'
    '});'
    'localStorage.setItem("gq_cv","38");'
    '})();'
    '</script>'
)


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

    # 5. Fix nav "Get the App" → /app on surah pages
    html = html.replace('<a href="#app">Get the App</a>',
                        '<a href="/app">Get the App</a>')

    # 7. Fix geo country→language map
    if OLD_GEO_MAP in html:
        html = html.replace(OLD_GEO_MAP, NEW_GEO_MAP, 1)
    else:
        print(f'  WARNING: surah {snum} — geo map not found (may already be patched or different format)')

    # 8. Inject desktop CSS + favicon + cache invalidation before </head>
    if '</head>' in html:
        # Remove old favicon tags so we don't duplicate
        if 'rel="icon"' in html:
            html = re.sub(r'<link rel="icon"[^>]*>', '', html)
            html = re.sub(r'<link rel="apple-touch-icon"[^>]*>', '', html)
        inject = CACHE_INVALIDATION + FAVICON_TAGS + DESKTOP_CSS
        html = html.replace('</head>', inject + '\n</head>', 1)

    return html


# ── Main ──────────────────────────────────────────────────────────────────────
surah_count  = 0
iife_patched = 0
geo_patched  = 0

with zipfile.ZipFile(IN_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    # Write sitemap.xml, robots.txt, and app/index.html
    sitemap_xml = build_sitemap()
    zout.writestr('sitemap.xml', sitemap_xml.encode('utf-8'))
    zout.writestr('robots.txt', ROBOTS_TXT.encode('utf-8'))
    zout.writestr('app/index.html', APP_PAGE_HTML.encode('utf-8'))
    print(f'Wrote sitemap.xml ({sitemap_xml.count("<url>")} URLs) + robots.txt + app/index.html')

    # Write SVG favicon (circular black icon — actual icon.png clipped to circle)
    favicon_svg = make_circular_favicon_svg()
    zout.writestr('favicon.svg', favicon_svg.encode('utf-8'))
    print(f'Wrote favicon.svg (circular, {len(favicon_svg)//1024} KB)')

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

    # Write quran chapter files — text + transliteration (no id field)
    # Transliteration was stripped in v31-v33, causing it to be empty for large surahs.
    # Restored here: IIFE path reads transliteration from this file and caches in gq_tl_N.
    for snum in range(1, 115):
        with open(f'{QURAN_DIR}/{snum}.json') as f:
            data = json.load(f)
        verses = [{'text': v['text'], 'transliteration': v.get('transliteration', '')}
                  for v in data['verses']]
        zout.writestr(f'quran/{snum}.json',
                      json.dumps({'verses': verses}, ensure_ascii=False, separators=(',',':')).encode('utf-8'))

    # Patch and copy all HTML + other files
    for item in zin.infolist():
        raw = zin.read(item.filename)
        # Skip files we've already written our own versions of
        if item.filename.startswith('translations/'):
            continue
        if item.filename in ('sitemap.xml', 'robots.txt', 'favicon.svg', 'icon.png',
                             'app/index.html', 'app.html'):
            continue  # our versions already written above; don't let v10 overwrite them
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
            # Fix nav "Get the App" link on ALL non-surah HTML pages (index.html, app.html, etc.)
            if item.filename.endswith('.html'):
                html = raw.decode('utf-8')
                html = html.replace('<a href="#app">Get the App</a>',
                                    '<a href="/app">Get the App</a>')
                raw = html.encode('utf-8')
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
with open(f'{QURAN_DIR}/2.json') as f:
    d2 = json.load(f)
q2_raw = json.dumps({'verses':[{'text':v['text'],'transliteration':v.get('transliteration','')} for v in d2['verses']]}, ensure_ascii=False, separators=(',',':')).encode('utf-8')
q2_gz  = gzip_size(q2_raw)
print(f'/quran/2.json: {len(q2_raw)//1024} KB raw, ~{q2_gz//1024} KB gzipped (text+transliteration)')
print(f'/translations/en.json: ~{en_gz//1024} KB gzipped (one-time, then cached)')
print(f'Fixes: transliteration restored, cache invalidated (gq_cv=38), circular black favicon')
