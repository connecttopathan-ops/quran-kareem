#!/usr/bin/env python3
"""
Download Roman Urdu translation from fawazahmed0 (urd-abulaalamaududi-la).
Produces assets/translations/ur-roman.json with structure:
  {"1": {"1": "text", "2": "text", ...}, "2": {...}, ...}
Run from project root: python3 scripts/download_ur_roman.py
"""
import json, os, sys, time, urllib.request, urllib.error

BASE   = 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/urd-abulaalamaududi-la'
OUT    = os.path.join(os.path.dirname(__file__), '..', 'assets', 'translations', 'ur-roman.json')

result = {}
errors = 0

for n in range(1, 115):
    url = f'{BASE}/{n}.json'
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=20) as resp:
                data = json.load(resp)
            verses = {str(v['verse']): v['text'] for v in data['chapter']}
            result[str(n)] = verses
            sys.stdout.write(f'\r  {n}/114 ({len(verses)} verses)  ')
            sys.stdout.flush()
            break
        except urllib.error.HTTPError as e:
            if attempt == 2:
                print(f'\n  HTTP {e.code} surah {n}', file=sys.stderr)
                result[str(n)] = {}
                errors += 1
            else:
                time.sleep(1)
        except Exception as e:
            if attempt == 2:
                print(f'\n  Error surah {n}: {e}', file=sys.stderr)
                result[str(n)] = {}
                errors += 1
            else:
                time.sleep(1)
    time.sleep(0.05)

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, separators=(',', ':'))

size_kb = os.path.getsize(OUT) // 1024
print(f'\nSaved {OUT} ({size_kb} KB, {len(result)} surahs, {errors} errors)')
print(f'Surah 1:1  → {result.get("1", {}).get("1", "MISSING")}')
print(f'Surah 67:1 → {result.get("67", {}).get("1", "MISSING")}')
