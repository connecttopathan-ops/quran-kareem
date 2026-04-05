#!/usr/bin/env python3
"""
build_v28.py  —  JS-only patch of getquran_cloudflare_deploy_v11.zip -> v28.zip

v11 already has:
  - TRANSLATIONS embedded per surah (47 langs × N ayahs, no external fetch)
  - fetchEdition() reads from embedded TRANSLATIONS (no override needed)
  - playAyah() already has continuous audio (if n < TOTAL, no patch needed)

Only remaining problem: loadArabic() fetches from alquran.cloud external API,
which fails on slow/roaming mobile connections.

This patch:
  1. Replaces loadArabic() to check localStorage cache first, then fetch from
     local /quran/{snum}.json (bundled in this zip).
  2. Bundles all 114 quran-json chapter files at /quran/{snum}.json.

Result:
  - Repeat visits: instant Arabic text rendering (no network needed)
  - First visit: fetches from local /quran/ (fast, same origin, no CDN dependency)
  - Zero external API calls for page content

Zero HTML/CSS changes. All other files copied verbatim.
"""

import os, re, urllib.request, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QURAN_DIR = os.path.join(ROOT_DIR, 'assets', 'quran-chapters')
V11_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v11.zip')
OUT_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v28.zip')
CDN_URL   = 'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/chapters/'

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


# ── Replacement for loadArabic() ─────────────────────────────────────────────
# Original fetches from alquran.cloud (external API, fails on slow connections).
# Replacement: check localStorage first, then fetch from local /quran/{snum}.json.
# quran-json format: {verses: [{text: "...", transliteration: "..."}, ...]}
# Both formats have .text on each ayah, so renderAyahs() works unchanged.

LOAD_ARABIC_OLD = (
    "async function loadArabic() {\n"
    "  try {\n"
    "    var r = await fetch('https://api.alquran.cloud/v1/surah/' + SNUM + '/quran-uthmani');\n"
    "    var j = await r.json();\n"
    "    arabicAyahs = j.data.ayahs;\n"
    "    renderAyahs();\n"
    "  } catch(e) {\n"
    "    document.getElementById('ayahs').innerHTML =\n"
    "      '<div class=\"error\">Failed to load Arabic text. Check your connection.</div>';\n"
    "  }\n"
    "}"
)

LOAD_ARABIC_NEW = (
    "async function loadArabic() {\n"
    "  var cached = localStorage.getItem('gq_ar_' + SNUM);\n"
    "  if (cached) {\n"
    "    try {\n"
    "      var texts = JSON.parse(cached);\n"
    "      arabicAyahs = texts.map(function(t) { return {text: t}; });\n"
    "      renderAyahs();\n"
    "      return;\n"
    "    } catch(e) {}\n"
    "  }\n"
    "  try {\n"
    "    var r = await fetch('/quran/' + SNUM + '.json');\n"
    "    var j = await r.json();\n"
    "    arabicAyahs = j.verses || [];\n"
    "    try { localStorage.setItem('gq_ar_' + SNUM, JSON.stringify(arabicAyahs.map(function(v) { return v.text; }))); } catch(e) {}\n"
    "    renderAyahs();\n"
    "  } catch(e) {\n"
    "    document.getElementById('ayahs').innerHTML =\n"
    "      '<div class=\"error\">Failed to load Arabic text. Check your connection.</div>';\n"
    "  }\n"
    "}"
)


def patch_html(html):
    if LOAD_ARABIC_OLD not in html:
        return html, False
    return html.replace(LOAD_ARABIC_OLD, LOAD_ARABIC_NEW, 1), True


# ── Main ──────────────────────────────────────────────────────────────────────
if not os.path.exists(V11_ZIP):
    raise SystemExit(f'ERROR: {V11_ZIP} not found')

surah_count = 0
patched_count = 0

with zipfile.ZipFile(V11_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    # Bundle all 114 quran chapter files at /quran/{snum}.json
    print('Writing quran chapter files...')
    for snum in range(1, 115):
        with open(f'{QURAN_DIR}/{snum}.json', 'rb') as f:
            zout.writestr(f'quran/{snum}.json', f.read())

    # Patch surah HTML files
    for item in zin.infolist():
        raw = zin.read(item.filename)

        m = re.match(r'surah/(\d+)/index\.html$', item.filename)
        if m:
            snum = int(m.group(1))
            html = raw.decode('utf-8')
            html, patched = patch_html(html)
            zout.writestr(item, html.encode('utf-8'))
            surah_count += 1
            if patched:
                patched_count += 1
            else:
                print(f'  WARNING: loadArabic pattern not found in surah {snum}')
            if snum % 10 == 0 or snum == 114:
                print(f'  {snum}/114 done')
        else:
            zout.writestr(item, raw)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages, loadArabic patched in {patched_count}')
print(f'Zero HTML/CSS changes')
