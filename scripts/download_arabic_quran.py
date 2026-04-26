#!/usr/bin/env python3
"""
Download the full Quran Arabic text (Uthmani script) and English transliteration
from alquran.cloud and bundle them as assets/quran_text.json.

One request per edition (all 114 surahs in a single call) — fast and polite.

Run from project root: python3 scripts/download_arabic_quran.py
Produces assets/quran_text.json with structure:
  {
    "arabic":         {"1": {"1": "بِسْمِ...", "2": "..."}, ...},
    "transliteration": {"1": {"1": "Bismillah...",  "2": "..."}, ...}
  }
"""
import json, os, sys, time, urllib.request, urllib.error

OUT_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'quran_text.json')
BASE     = 'https://api.alquran.cloud/v1/quran'
EDITIONS = {
    'arabic':          'quran-uthmani',
    'transliteration': 'en.transliteration',
}

def fetch_edition(name, edition):
    url = f'{BASE}/{edition}'
    for attempt in range(4):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'quran-kareem/1.0'})
            with urllib.request.urlopen(req, timeout=60) as resp:
                body = json.load(resp)
            surahs = body['data']['surahs']
            result = {}
            for s in surahs:
                snum = str(s['number'])
                result[snum] = {str(a['numberInSurah']): a['text'] for a in s['ayahs']}
            total_verses = sum(len(v) for v in result.values())
            print(f'  {name} ({edition}): {len(result)} surahs, {total_verses} verses')
            return result
        except urllib.error.HTTPError as e:
            print(f'  HTTP {e.code} for {name}, attempt {attempt+1}', file=sys.stderr)
        except Exception as e:
            print(f'  Error for {name}: {e}, attempt {attempt+1}', file=sys.stderr)
        if attempt < 3:
            time.sleep(2 ** attempt)
    return None

print('Downloading Quran Arabic text + transliteration...')
result = {}
failed = []
for key, edition in EDITIONS.items():
    data = fetch_edition(key, edition)
    if data:
        result[key] = data
    else:
        failed.append(key)
    time.sleep(0.5)

if failed:
    print(f'FAILED: {", ".join(failed)}', file=sys.stderr)
    sys.exit(1)

os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
with open(OUT_PATH, 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, separators=(',', ':'))

size_kb = os.path.getsize(OUT_PATH) // 1024
print(f'Written {OUT_PATH} ({size_kb} KB)')
