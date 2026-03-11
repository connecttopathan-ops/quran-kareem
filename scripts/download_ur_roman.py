#!/usr/bin/env python3
"""
Download Roman Urdu translation from kanz-ul-imaan-quran-api.
Loops juz 1-30, parts 1-20, skips 404s.
Outputs assets/translations/ur-roman.json:
  {"1": {"1": "text", "2": "text", ...}, "2": {...}, ...}
"""
import json, os, re, sys, time, urllib.request, urllib.error

BASE = ('https://raw.githubusercontent.com/'
        'Zikr-Quranic-Dua-Companion/kanz-ul-imaan-quran-api/main/Quran')
OUT  = os.path.join(os.path.dirname(__file__), '..', 'assets', 'translations', 'ur-roman.json')

def clean(text):
    """Remove tabs, collapse multiple spaces/newlines to single space."""
    t = text.replace('\t', ' ').replace('\n', ' ').replace('\r', ' ')
    return re.sub(r' {2,}', ' ', t).strip()

result = {}   # surah_str → {verse_str: text}
seen_files = 0
seen_verses = 0

for juz in range(1, 31):
    for part in range(1, 21):
        url = f'{BASE}/juz_{juz}_part_{part}.json'
        try:
            with urllib.request.urlopen(url, timeout=20) as resp:
                if resp.status != 200:
                    break
                data = json.load(resp)
        except urllib.error.HTTPError as e:
            if e.code == 404:
                break        # no more parts for this juz
            print(f'  HTTP {e.code} on {url}', file=sys.stderr)
            time.sleep(1)
            continue
        except Exception as e:
            print(f'  Error {url}: {e}', file=sys.stderr)
            time.sleep(1)
            continue

        seen_files += 1
        for item in data:
            if 'surah' not in item or 'ayatNumber' not in item:
                continue  # skip empty/malformed objects
            surah = str(item['surah']['id'])
            verse = str(item['ayatNumber'])
            text  = clean(item.get('romanUrduTranslationText', ''))
            result.setdefault(surah, {})[verse] = text
            seen_verses += 1

        print(f'  juz {juz:2d} part {part}: {len(data)} verses  [total {seen_verses}]')
        time.sleep(0.03)

# Sort keys numerically before saving
sorted_result = {
    str(s): {str(v): result[str(s)][str(v)]
             for v in sorted(result[str(s)].keys(), key=int)}
    for s in sorted(result.keys(), key=int)
}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(sorted_result, f, ensure_ascii=False, separators=(',', ':'))

size_kb = os.path.getsize(OUT) // 1024
print(f'\nSaved {OUT}  ({size_kb} KB, {seen_files} files, {seen_verses} verses)')
print(f'Surahs covered: {len(sorted_result)}')

# Verify
s1v1 = sorted_result.get('1', {}).get('1', 'MISSING')
s3v1 = sorted_result.get('3', {}).get('1', 'MISSING')
print(f'\nSurah 1 Verse 1: {s1v1}')
print(f'Surah 3 Verse 1: {s3v1}')
