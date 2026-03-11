#!/usr/bin/env python3
"""
Download all bundled Quran translations (all app languages except ur-roman).
Uses alquran.cloud /v1/quran/{edition} — one request per language (all 114 surahs).
ur-roman is skipped here; it is handled by scripts/download_ur_roman.py.

Run from project root: python3 scripts/download_all_translations.py
Produces assets/translations/{lang}.json with structure:
  {"1": {"1": "verse text", "2": "..."}, "2": {...}, ...}
"""
import json, os, sys, time, urllib.request, urllib.error

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'translations')
os.makedirs(OUT_DIR, exist_ok=True)

# alquran.cloud edition IDs for every app language (ur-roman excluded).
EDITIONS = {
    'en':  'en.asad',
    'ur':  'ur.jalandhry',
    'zh':  'zh.majian',
    'hi':  'hi.hindi',
    'es':  'es.asad',
    'ar':  'ar.muyassar',
    'fr':  'fr.hamidullah',
    'bn':  'bn.bengali',
    'pt':  'pt.elhayek',
    'ru':  'ru.kuliev',
    'id':  'id.indonesian',
    'tr':  'tr.ates',
    'fa':  'fa.ansarian',
    'ms':  'ms.basmeih',
    'de':  'de.bubenheim',
    'nl':  'nl.keyzer',
    'it':  'it.piccardo',
    'pl':  'pl.bielawskiego',
    'sv':  'sv.bernstrom',
    'cs':  'cs.hrbek',
    'ro':  'ro.grigore',
    'hu':  'hu.simon',
    'fi':  'fi.efendi',
    'da':  'da.aburida',
    'no':  'no.berg',
    'sk':  'sk.hrbek',
    'bg':  'bg.theophanov',
    'hr':  'hr.mlivo',
    'lt':  'lt.mickiewicz',
    'lv':  'lv.shakova',
    'et':  'et.tahkeem',
    'sl':  'sl.krizanic',
    'el':  'el.papadopoulos',
    'sq':  'sq.nahi',
    'bs':  'bs.korkut',
    'sr':  'sr.obic',
    'uk':  'uk.culturemap',
    'az':  'az.mammadaliyev',
    'ka':  'ka.georgian',
    'hy':  'hy.armenian',
    'ta':  'ta.tamil',
    'th':  'th.thai',
    'ja':  'ja.japanese',
    'ko':  'ko.korean',
    'sw':  'sw.barwani',
    'ml':  'ml.abdulhameed',
}

BASE = 'https://api.alquran.cloud/v1/quran'

total = len(EDITIONS)
done  = 0
failed = []

for lang, edition in EDITIONS.items():
    out_path = os.path.join(OUT_DIR, f'{lang}.json')
    url = f'{BASE}/{edition}'
    success = False

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
            with open(out_path, 'w', encoding='utf-8') as f:
                json.dump(result, f, ensure_ascii=False, separators=(',', ':'))
            size_kb = os.path.getsize(out_path) // 1024
            done += 1
            print(f'[{done}/{total}] {lang} ({edition}) — {size_kb} KB, {len(result)} surahs')
            success = True
            break
        except urllib.error.HTTPError as e:
            print(f'  HTTP {e.code} for {lang} ({edition}), attempt {attempt+1}', file=sys.stderr)
            if attempt < 3:
                time.sleep(2 ** attempt)
        except Exception as e:
            print(f'  Error for {lang}: {e}, attempt {attempt+1}', file=sys.stderr)
            if attempt < 3:
                time.sleep(2 ** attempt)

    if not success:
        failed.append(lang)
        # Write empty placeholder so Flutter asset bundle doesn't break.
        with open(out_path, 'w') as f:
            f.write('{}')

    time.sleep(0.3)  # polite rate limit

print(f'\nDone. {done}/{total} languages downloaded.')
if failed:
    print(f'FAILED: {", ".join(failed)}', file=sys.stderr)
    sys.exit(1)
