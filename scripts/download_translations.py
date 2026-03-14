#!/usr/bin/env python3
"""
Download 4 bundled Quran translations (en, ur, hi, ar) from fawazahmed0 CDN.
NOTE: ur-roman is downloaded separately via scripts/download_ur_roman.py
      from the kanz-ul-imaan-quran-api (GitHub raw), which works in CI.
Run from the project root: python3 scripts/download_translations.py

Produces assets/translations/{lang}.json with structure:
  { "1": { "1": "verse text", "2": "..." }, "2": { ... }, ... }
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

# ur-roman is intentionally excluded — it comes from kanz-ul-imaan via
# download_ur_roman.py and is committed directly to the repo.
EDITIONS = {
    'ur':       'urd-maududi',
    'en':       'eng-muhammadali',
    'hi':       'hin-muhammadali',
    'ar':       'ara-qurancom',
}

BASE_URL = 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions'
OUT_DIR  = os.path.join(os.path.dirname(__file__), '..', 'assets', 'translations')

os.makedirs(OUT_DIR, exist_ok=True)

for lang, edition in EDITIONS.items():
    print(f'Downloading {lang} ({edition})...')
    result = {}
    errors = 0

    for n in range(1, 115):
        url = f'{BASE_URL}/{edition}/{n}.json'
        for attempt in range(3):
            try:
                with urllib.request.urlopen(url, timeout=20) as resp:
                    data = json.load(resp)
                chapter = data.get('chapter', [])
                result[str(n)] = {str(v['verse']): v['text'] for v in chapter}
                break
            except Exception as e:
                if attempt == 2:
                    print(f'  ERROR surah {n}: {e}', file=sys.stderr)
                    result[str(n)] = {}
                    errors += 1
                else:
                    time.sleep(1)
        if n % 20 == 0:
            print(f'  {n}/114')
        time.sleep(0.05)  # polite rate limit

    out_path = os.path.join(OUT_DIR, f'{lang}.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, separators=(',', ':'))

    size_kb = os.path.getsize(out_path) // 1024
    print(f'  Saved {out_path} ({size_kb} KB, {errors} errors)')

print('Done!')
