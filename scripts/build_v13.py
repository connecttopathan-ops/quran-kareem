#!/usr/bin/env python3
"""
build_v13.py  —  JS-only patch of getquran_cloudflare_deploy_v10.zip -> v13.zip

For each surah/*/index.html in v10:
  1. Read SNUM from existing JS
  2. Build TRANSLATIONS from assets/translations/*.json for that surah
  3. Inject <script>var TRANSLATIONS={...};</script> just before </body>
  4. Replace fetchEdition function body -> reads from TRANSLATIONS
  5. In playAyah onended handler -> add if(n<TOTAL) playAyah(n+1)

Zero HTML/CSS changes. All other files copied verbatim.
"""

import json, os, re, zipfile

ROOT_DIR  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANS_DIR = os.path.join(ROOT_DIR, 'assets', 'translations')
V10_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v10.zip')
OUT_ZIP   = os.path.expanduser('~/Downloads/getquran_cloudflare_deploy_v13.zip')

# ── Load translation files ────────────────────────────────────────────────────
print('Loading translations...')
TRANS_DATA = {}
for fname in sorted(os.listdir(TRANS_DIR)):
    if fname.endswith('.json'):
        lang = fname[:-5]
        with open(os.path.join(TRANS_DIR, fname), encoding='utf-8') as f:
            TRANS_DATA[lang] = json.load(f)
print(f'Loaded {len(TRANS_DATA)} languages')


def find_function_end(text, func_start):
    """Return index just after the closing } of the function starting at func_start."""
    depth = 0
    i = text.index('{', func_start)
    while i < len(text):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return len(text)


def patch_html(html, snum):
    # ── 1. Build TRANSLATIONS for this surah ─────────────────────────────────
    trans = {}
    for lang, data in TRANS_DATA.items():
        surah_data = data.get(str(snum), {})
        if surah_data:
            max_ayah = max(int(k) for k in surah_data.keys())
            trans[lang] = [surah_data.get(str(i), '') for i in range(1, max_ayah + 1)]
        else:
            trans[lang] = []

    trans_json = json.dumps(trans, ensure_ascii=False, separators=(',', ':'))

    # ── 2. Inject TRANSLATIONS just before </body> ────────────────────────────
    script_tag = f'<script>var TRANSLATIONS={trans_json};</script>'
    if '</body>' in html:
        html = html.replace('</body>', script_tag + '\n</body>', 1)
    else:
        html += '\n' + script_tag

    # ── 3. Replace fetchEdition function ──────────────────────────────────────
    # Match:  function fetchEdition(<args>) { ... }
    fe_match = re.search(r'function\s+fetchEdition\s*\([^)]*\)\s*\{', html)
    if fe_match:
        func_start = fe_match.start()
        func_end   = find_function_end(html, func_start)
        # Extract original arg name (e.g. "ed", "edition", "lang")
        arg_match  = re.search(r'function\s+fetchEdition\s*\(([^)]*)\)', html[func_start:func_end])
        arg        = arg_match.group(1).strip() if arg_match else 'ed'
        new_func   = (
            f'function fetchEdition({arg}){{\n'
            f'  return Promise.resolve(TRANSLATIONS[{arg}]||[]);\n'
            f'}}'
        )
        html = html[:func_start] + new_func + html[func_end:]
    else:
        print(f'  WARNING surah {snum}: fetchEdition not found')

    # ── 4. Add continuous audio in playAyah onended ───────────────────────────
    # Find playAyah function, then find onended handler inside it
    pa_match = re.search(r'function\s+playAyah\s*\([^)]*\)\s*\{', html)
    if pa_match:
        pa_start = pa_match.start()
        pa_end   = find_function_end(html, pa_start)
        pa_body  = html[pa_start:pa_end]

        # Find onended = function() { ... } inside playAyah
        oe_match = re.search(r'\.onended\s*=\s*function\s*\([^)]*\)\s*\{', pa_body)
        if oe_match:
            oe_brace_open    = pa_body.index('{', oe_match.start())
            # find closing } of onended handler
            depth = 0
            i = oe_brace_open
            while i < len(pa_body):
                if pa_body[i] == '{':
                    depth += 1
                elif pa_body[i] == '}':
                    depth -= 1
                    if depth == 0:
                        oe_close = i
                        break
                i += 1
            else:
                oe_close = len(pa_body) - 1

            # Only inject if not already present
            oe_content = pa_body[oe_brace_open:oe_close]
            continuous_line = 'if(n<TOTAL)playAyah(n+1);'
            if 'playAyah(n+1)' not in oe_content:
                # Insert just before closing brace
                pa_body = (
                    pa_body[:oe_close]
                    + '\n    ' + continuous_line
                    + pa_body[oe_close:]
                )
            html = html[:pa_start] + pa_body + html[pa_end:]
        else:
            # Arrow function style: .onended = () => { ... }  or  .onended=()=>{...}
            oe_match2 = re.search(r'\.onended\s*=\s*(?:\([^)]*\)|[a-z_]\w*)\s*=>\s*\{', pa_body)
            if oe_match2:
                oe_brace_open    = pa_body.index('{', oe_match2.start())
                depth = 0
                i = oe_brace_open
                while i < len(pa_body):
                    if pa_body[i] == '{':
                        depth += 1
                    elif pa_body[i] == '}':
                        depth -= 1
                        if depth == 0:
                            oe_close = i
                            break
                    i += 1
                else:
                    oe_close = len(pa_body) - 1

                oe_content = pa_body[oe_brace_open:oe_close]
                continuous_line = 'if(n<TOTAL)playAyah(n+1);'
                if 'playAyah(n+1)' not in oe_content:
                    pa_body = (
                        pa_body[:oe_close]
                        + '\n    ' + continuous_line
                        + pa_body[oe_close:]
                    )
                html = html[:pa_start] + pa_body + html[pa_end:]
            else:
                print(f'  WARNING surah {snum}: onended handler not found in playAyah')
    else:
        print(f'  WARNING surah {snum}: playAyah not found')

    return html


# ── Main ──────────────────────────────────────────────────────────────────────
if not os.path.exists(V10_ZIP):
    raise SystemExit(f'ERROR: {V10_ZIP} not found')

surah_count = 0
with zipfile.ZipFile(V10_ZIP, 'r') as zin, \
     zipfile.ZipFile(OUT_ZIP, 'w', zipfile.ZIP_DEFLATED) as zout:

    for item in zin.infolist():
        raw = zin.read(item.filename)

        m = re.match(r'surah/[^/]+/index\.html$', item.filename)
        if m:
            html = raw.decode('utf-8')

            # Read SNUM from the JS in the page
            snum_match = re.search(r'\bSNUM\s*=\s*(\d+)', html)
            if not snum_match:
                print(f'  WARNING: SNUM not found in {item.filename}, skipping')
                zout.writestr(item, raw)
                continue
            snum = int(snum_match.group(1))

            html = patch_html(html, snum)
            zout.writestr(item, html.encode('utf-8'))
            surah_count += 1
            if snum % 10 == 0 or snum == 114:
                print(f'  {snum}/114 patched')
        else:
            # Copy everything else verbatim — no changes
            zout.writestr(item, raw)

size_mb = os.path.getsize(OUT_ZIP) / 1_000_000
print(f'\nDone! {OUT_ZIP} ({size_mb:.1f} MB)')
print(f'Patched {surah_count} surah pages — zero HTML/CSS changes')
