#!/usr/bin/env python3
"""
build_v11.py
Build getquran_cloudflare_deploy_v11.zip

For each of 114 surahs:
  - embed var TRANSLATIONS = {"lang": ["ayah1",...], ...}  (all 47 lang files)
  - fetchEdition reads from TRANSLATIONS (no API calls for translations)
  - playAyah onended: if(n<TOTAL) playAyah(n+1)  (continuous audio)
Arabic text is fetched from alquran.cloud API on page load.
"""

import json, os, re, zipfile

ROOT_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR  = os.path.join(ROOT_DIR, 'assets', 'translations')
OUT_ZIP    = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v11.zip')
WORK_DIR   = os.path.join(os.path.expanduser('~'), 'Downloads', 'quran_site_v11_tmp')

# ── Surah metadata from quran_data.dart ───────────────────────────────────────
with open(os.path.join(ROOT_DIR, 'lib', 'data', 'quran_data.dart')) as f:
    dart = f.read()

SURAHS = {}  # number -> {ar, translit, en, verses}
for m in re.finditer(
    r'Surah\(number: (\d+), nameArabic: \'([^\']+)\', '
    r'nameTransliteration: (\"[^\"]+\"|\'[^\']+\'), '
    r'nameTranslation: (\"[^\"]+\"|\'[^\']+\'), verses: (\d+)',
    dart
):
    n, ar, tlit, en, v = m.groups()
    SURAHS[int(n)] = {
        'ar':      ar,
        'translit': tlit.strip('"\''),
        'en':      en.strip('"\''),
        'verses':  int(v),
    }

# ── Cumulative verse offsets (1-indexed; OFFSETS[s] = abs verse of s,ayah1-1) ─
verse_counts = [SURAHS[s]['verses'] for s in range(1, 115)]
OFFSETS = [0, 0]  # pad so OFFSETS[1]=0
acc = 0
for vc in verse_counts[:-1]:
    acc += vc
    OFFSETS.append(acc)
# OFFSETS[s] + ayah_num = absolute verse number (1-based)

# ── Load all translation files ─────────────────────────────────────────────────
print('Loading translation files...')
TRANS_DATA = {}   # lang -> {surah_str -> {ayah_str -> text}}
for fname in sorted(os.listdir(TRANS_DIR)):
    if not fname.endswith('.json'):
        continue
    lang = fname[:-5]  # strip .json
    with open(os.path.join(TRANS_DIR, fname), encoding='utf-8') as f:
        TRANS_DATA[lang] = json.load(f)
    print(f'  {lang}: {len(TRANS_DATA[lang])} surahs')

print(f'Loaded {len(TRANS_DATA)} languages')

# ── HTML template ─────────────────────────────────────────────────────────────
def build_surah_html(snum, info, translations_json):
    prev_link = f'<a href="/surah/{snum-1}/" class="nav-btn">&#8592; {SURAHS[snum-1]["translit"]}</a>' if snum > 1 else ''
    next_link = f'<a href="/surah/{snum+1}/" class="nav-btn">{SURAHS[snum+1]["translit"]} &#8594;</a>' if snum < 114 else ''
    back_link = '<a href="/" class="nav-btn home-btn">&#8962; All Surahs</a>'
    offsets_js = json.dumps(OFFSETS)

    return f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Surah {info["translit"]} ({info["en"]}) — GetQuran</title>
<style>
*{{box-sizing:border-box;margin:0;padding:0}}
body{{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#0f1117;color:#e2e8f0;min-height:100vh}}
header{{background:#1a1f2e;padding:12px 16px;position:sticky;top:0;z-index:100;border-bottom:1px solid #2d3748;display:flex;align-items:center;gap:10px;flex-wrap:wrap}}
.surah-title{{flex:1;min-width:200px}}
.surah-title h1{{font-size:1.1rem;color:#f6c90e}}
.surah-title .meta{{font-size:0.75rem;color:#718096}}
.surah-arabic{{font-size:1.4rem;direction:rtl;color:#f6c90e;margin-left:auto}}
.controls{{display:flex;align-items:center;gap:8px;flex-wrap:wrap}}
select{{background:#2d3748;color:#e2e8f0;border:1px solid #4a5568;border-radius:6px;padding:5px 8px;font-size:0.8rem;cursor:pointer}}
.play-all-btn{{background:#f6c90e;color:#0f1117;border:none;border-radius:6px;padding:6px 14px;font-size:0.85rem;font-weight:700;cursor:pointer}}
.play-all-btn:hover{{background:#e5b800}}
.stop-btn{{background:#e53e3e;color:#fff;border:none;border-radius:6px;padding:6px 14px;font-size:0.85rem;font-weight:700;cursor:pointer;display:none}}
nav{{display:flex;gap:8px;padding:10px 16px;background:#151923;border-bottom:1px solid #2d3748;flex-wrap:wrap}}
.nav-btn{{color:#90cdf4;text-decoration:none;font-size:0.8rem;padding:4px 8px;border-radius:4px;border:1px solid #2d3748}}
.nav-btn:hover{{background:#2d3748}}
.home-btn{{color:#f6c90e;border-color:#f6c90e33}}
.bismillah{{text-align:center;font-size:1.8rem;direction:rtl;color:#f6c90e;padding:24px 16px 8px;font-family:"Scheherazade New","Amiri","Traditional Arabic",serif;letter-spacing:2px}}
#ayahs{{max-width:800px;margin:0 auto;padding:8px 12px 40px}}
.ayah{{border-bottom:1px solid #1e2535;padding:18px 12px;cursor:pointer;border-radius:8px;margin-bottom:4px;transition:background 0.15s}}
.ayah:hover{{background:#1a1f2e}}
.ayah.playing{{background:#1a2744;border-left:3px solid #f6c90e}}
.ayah-top{{display:flex;justify-content:space-between;align-items:flex-start;gap:12px}}
.arabic-text{{font-size:1.6rem;direction:rtl;line-height:2;color:#f0e6c0;font-family:"Scheherazade New","Amiri","Traditional Arabic",serif;flex:1;text-align:right}}
.ayah-num{{background:#2d3748;color:#718096;border-radius:50%;width:28px;height:28px;display:flex;align-items:center;justify-content:center;font-size:0.7rem;flex-shrink:0;margin-top:8px}}
.translation{{color:#a0aec0;font-size:0.9rem;line-height:1.6;margin-top:10px;padding-left:4px}}
.loading{{text-align:center;color:#718096;padding:40px;font-size:0.9rem}}
.error{{text-align:center;color:#fc8181;padding:40px;font-size:0.9rem}}
footer{{text-align:center;color:#4a5568;font-size:0.75rem;padding:24px;border-top:1px solid #1e2535}}
@media(max-width:480px){{
  .arabic-text{{font-size:1.3rem}}
  header{{padding:8px 12px}}
}}
</style>
</head>
<body>

<header>
  <div class="surah-title">
    <h1>Surah {info["translit"]}</h1>
    <div class="meta">{snum} · {info["en"]} · {info["verses"]} Ayahs</div>
  </div>
  <div class="surah-arabic">{info["ar"]}</div>
  <div class="controls">
    <select id="langSel" onchange="onLangChange()"></select>
    <button class="play-all-btn" onclick="playAll()">&#9654; Play All</button>
    <button class="stop-btn" id="stopBtn" onclick="stopAudio()">&#9646;&#9646; Stop</button>
  </div>
</header>

<nav>
  {back_link}
  {prev_link}
  {next_link}
</nav>

{('<div class="bismillah">بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ</div>' if snum != 9 else '')}

<div id="ayahs"><div class="loading">Loading ayahs…</div></div>

<footer>GetQuran · Surah {snum} of 114</footer>

<script>
const SNUM = {snum};
const TOTAL = {info["verses"]};
var TRANSLATIONS = {translations_json};
var OFFSETS = {offsets_js};

// fetchEdition reads from embedded TRANSLATIONS — no API call needed
function fetchEdition(lang) {{
  return Promise.resolve(TRANSLATIONS[lang] || []);
}}

// ── Language selector ─────────────────────────────────────────────────────────
var LANG_LABELS = {{
  ar:'Arabic (Tafsir)',az:'Azerbaijani',bg:'Bulgarian',bn:'Bengali',bs:'Bosnian',
  cs:'Czech',da:'Danish',de:'German',el:'Greek',en:'English',es:'Spanish',
  et:'Estonian',fa:'Persian',fi:'Finnish',fr:'French',hi:'Hindi',hr:'Croatian',
  hu:'Hungarian',hy:'Armenian',id:'Indonesian',it:'Italian',ja:'Japanese',
  ka:'Georgian',ko:'Korean',lt:'Lithuanian',lv:'Latvian',ml:'Malayalam',
  ms:'Malay',nl:'Dutch',no:'Norwegian',pl:'Polish',pt:'Portuguese',
  ro:'Romanian',ru:'Russian',sk:'Slovak',sl:'Slovenian',sq:'Albanian',
  sr:'Serbian',sv:'Swedish',sw:'Swahili',ta:'Tamil',th:'Thai',tr:'Turkish',
  uk:'Ukrainian',ur:'Urdu','ur-roman':'Urdu (Roman)',zh:'Chinese'
}};

var currentLang = localStorage.getItem('ql_lang') || 'en';
var arabicAyahs = [];
var audioEl = null;
var playingAyah = 0;

function buildLangSel() {{
  var sel = document.getElementById('langSel');
  var langs = Object.keys(TRANSLATIONS).sort();
  sel.innerHTML = langs.map(l =>
    '<option value="' + l + '"' + (l === currentLang ? ' selected' : '') + '>' +
    (LANG_LABELS[l] || l) + '</option>'
  ).join('');
}}

function onLangChange() {{
  currentLang = document.getElementById('langSel').value;
  localStorage.setItem('ql_lang', currentLang);
  renderAyahs();
}}

// ── Render ────────────────────────────────────────────────────────────────────
function renderAyahs() {{
  var trans = TRANSLATIONS[currentLang] || [];
  var container = document.getElementById('ayahs');
  if (!arabicAyahs.length) {{
    container.innerHTML = '<div class="loading">Loading Arabic text…</div>';
    return;
  }}
  container.innerHTML = arabicAyahs.map(function(a, i) {{
    var n = i + 1;
    return '<div class="ayah' + (n === playingAyah ? ' playing' : '') +
           '" id="a' + n + '" onclick="playAyah(' + n + ')">' +
           '<div class="ayah-top">' +
           '<div class="arabic-text">' + a.text + '</div>' +
           '<div class="ayah-num">' + n + '</div>' +
           '</div>' +
           '<div class="translation">' + (trans[i] || '') + '</div>' +
           '</div>';
  }}).join('');
}}

// ── Fetch Arabic text ─────────────────────────────────────────────────────────
async function loadArabic() {{
  try {{
    var r = await fetch('https://api.alquran.cloud/v1/surah/' + SNUM + '/quran-uthmani');
    var j = await r.json();
    arabicAyahs = j.data.ayahs;
    renderAyahs();
  }} catch(e) {{
    document.getElementById('ayahs').innerHTML =
      '<div class="error">Failed to load Arabic text. Check your connection.</div>';
  }}
}}

// ── Audio ─────────────────────────────────────────────────────────────────────
function absVerse(surah, ayah) {{ return OFFSETS[surah] + ayah; }}

function playAyah(n) {{
  if (audioEl) {{ audioEl.pause(); audioEl.onended = null; }}
  playingAyah = n;
  // Highlight playing ayah
  document.querySelectorAll('.ayah.playing').forEach(function(el) {{ el.classList.remove('playing'); }});
  var el = document.getElementById('a' + n);
  if (el) {{ el.classList.add('playing'); el.scrollIntoView({{behavior:'smooth', block:'nearest'}}); }}
  document.getElementById('stopBtn').style.display = 'inline-block';

  audioEl = new Audio('https://cdn.islamic.network/quran/audio/128/ar.alafasy/' + absVerse(SNUM, n) + '.mp3');
  audioEl.onended = function() {{
    if (n < TOTAL) playAyah(n + 1);
    else stopAudio();
  }};
  audioEl.play().catch(function() {{}});
}}

function playAll() {{ playAyah(1); }}

function stopAudio() {{
  if (audioEl) {{ audioEl.pause(); audioEl.onended = null; audioEl = null; }}
  playingAyah = 0;
  document.querySelectorAll('.ayah.playing').forEach(function(el) {{ el.classList.remove('playing'); }});
  document.getElementById('stopBtn').style.display = 'none';
}}

// ── Init ──────────────────────────────────────────────────────────────────────
buildLangSel();
loadArabic();
</script>
</body>
</html>'''


def build_index_html():
    rows = []
    for n in range(1, 115):
        s = SURAHS[n]
        rows.append(
            f'<a href="/surah/{n}/" class="surah-card">'
            f'<span class="num">{n}</span>'
            f'<span class="names"><span class="translit">{s["translit"]}</span>'
            f'<span class="en">{s["en"]}</span></span>'
            f'<span class="ar">{s["ar"]}</span>'
            f'<span class="verses">{s["verses"]} ayahs</span>'
            f'</a>'
        )
    cards = '\n'.join(rows)
    return f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>GetQuran — Read the Holy Quran</title>
<style>
*{{box-sizing:border-box;margin:0;padding:0}}
body{{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#0f1117;color:#e2e8f0;min-height:100vh}}
header{{background:#1a1f2e;padding:20px 16px;text-align:center;border-bottom:1px solid #2d3748}}
header h1{{font-size:1.6rem;color:#f6c90e;margin-bottom:4px}}
header p{{font-size:0.85rem;color:#718096}}
.search-wrap{{max-width:600px;margin:16px auto 0;padding:0 16px}}
.search-wrap input{{width:100%;background:#2d3748;border:1px solid #4a5568;border-radius:8px;padding:10px 14px;color:#e2e8f0;font-size:0.9rem;outline:none}}
.search-wrap input:focus{{border-color:#f6c90e}}
#list{{max-width:700px;margin:12px auto;padding:0 12px 40px;display:flex;flex-direction:column;gap:4px}}
.surah-card{{display:flex;align-items:center;gap:12px;background:#1a1f2e;border:1px solid #2d3748;border-radius:8px;padding:12px 14px;text-decoration:none;color:inherit;transition:background 0.15s}}
.surah-card:hover{{background:#232a3e;border-color:#f6c90e44}}
.num{{background:#2d3748;color:#718096;border-radius:50%;width:34px;height:34px;display:flex;align-items:center;justify-content:center;font-size:0.75rem;flex-shrink:0;font-weight:600}}
.names{{flex:1;min-width:0}}
.translit{{display:block;font-size:0.95rem;font-weight:600;color:#f6c90e}}
.en{{display:block;font-size:0.75rem;color:#718096;margin-top:1px}}
.ar{{font-size:1.2rem;color:#f0e6c0;font-family:"Scheherazade New","Amiri",serif;direction:rtl}}
.verses{{font-size:0.72rem;color:#4a5568;flex-shrink:0;text-align:right}}
footer{{text-align:center;color:#4a5568;font-size:0.75rem;padding:24px}}
.hidden{{display:none!important}}
</style>
</head>
<body>
<header>
  <h1>&#9654; GetQuran</h1>
  <p>The Holy Quran — All 114 Surahs</p>
  <div class="search-wrap">
    <input type="search" id="search" placeholder="Search surah name…" oninput="filterSurahs(this.value)">
  </div>
</header>
<div id="list">
{cards}
</div>
<footer>GetQuran · 114 Surahs · 46 Translations</footer>
<script>
function filterSurahs(q) {{
  q = q.toLowerCase();
  document.querySelectorAll('.surah-card').forEach(function(c) {{
    var text = c.textContent.toLowerCase();
    c.classList.toggle('hidden', q.length > 0 && !text.includes(q));
  }});
}}
</script>
</body>
</html>'''


# ── Main build ─────────────────────────────────────────────────────────────────
os.makedirs(ROOT := WORK_DIR, exist_ok=True)

print('Building index.html...')
with open(os.path.join(ROOT, 'index.html'), 'w', encoding='utf-8') as f:
    f.write(build_index_html())

# _headers for Cloudflare Pages
with open(os.path.join(ROOT, '_headers'), 'w') as f:
    f.write('''/*
  Cache-Control: public, max-age=86400
  X-Content-Type-Options: nosniff
/surah/*/index.html
  Cache-Control: public, max-age=3600
''')

total = 114
for snum in range(1, 115):
    info = SURAHS[snum]
    # Build TRANSLATIONS for this surah: {"lang": ["ayah1", "ayah2", ...], ...}
    trans = {}
    for lang, data in TRANS_DATA.items():
        surah_data = data.get(str(snum), {})
        # Convert {"1": "text", "2": "text"} -> ordered list
        if surah_data:
            max_ayah = max(int(k) for k in surah_data.keys())
            arr = [surah_data.get(str(i), '') for i in range(1, max_ayah + 1)]
            trans[lang] = arr
        else:
            trans[lang] = []

    trans_json = json.dumps(trans, ensure_ascii=False, separators=(',', ':'))
    html = build_surah_html(snum, info, trans_json)

    outdir = os.path.join(ROOT, 'surah', str(snum))
    os.makedirs(outdir, exist_ok=True)
    with open(os.path.join(outdir, 'index.html'), 'w', encoding='utf-8') as f:
        f.write(html)

    if snum % 10 == 0 or snum == total:
        print(f'  {snum}/{total} surahs done')

# ── Zip ────────────────────────────────────────────────────────────────────────
os.makedirs(os.path.dirname(OUT_ZIP), exist_ok=True)
print(f'Zipping to {OUT_ZIP}...')
with zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zf:
    for dirpath, dirnames, filenames in os.walk(ROOT):
        for fname in filenames:
            fpath = os.path.join(dirpath, fname)
            arcname = os.path.relpath(fpath, ROOT)
            zf.write(fpath, arcname)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'Done! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Contains: index.html + {total} surah pages + _headers')

# ── Cleanup temp dir ───────────────────────────────────────────────────────────
import shutil
shutil.rmtree(WORK_DIR, ignore_errors=True)
