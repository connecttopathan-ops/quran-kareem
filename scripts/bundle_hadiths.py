#!/usr/bin/env python3
"""
Downloads Bukhari & Muslim hadith data from hadithapi.com at CI build time
and writes pre-processed JSON assets for the Flutter app to bundle directly.
Run once per build — users never call the API.
"""

import json
import os
import time

import requests

API_KEY = '$2y$10$i0Y8DwcA9IKOd9kM0for4eX6RGOOAFQ9Mvd8etx5p2UDWZH8rNK6'
BASE    = 'https://hadithapi.com/api'
OUT_DIR = 'assets/books'

BOOKS = [
    ('sahih-bukhari', 'bukhari', 'Sahih Al-Bukhari'),
    ('sahih-muslim',  'muslim',  'Sahih Muslim'),
]


def get(url, params, retries=4):
    for attempt in range(retries):
        try:
            r = requests.get(url, params=params, timeout=60)
            if r.status_code == 429:
                wait = 30 * (attempt + 1)
                print(f'  Rate limited — waiting {wait}s ...', flush=True)
                time.sleep(wait)
                continue
            r.raise_for_status()
            return r.json()
        except requests.RequestException as e:
            if attempt == retries - 1:
                raise
            time.sleep(5 * (attempt + 1))


def bundle_book(slug, book_id, title):
    print(f'\nBundling {title} ({slug}) ...', flush=True)

    chapters = get(f'{BASE}/{slug}/chapters', {'apiKey': API_KEY})['chapters']

    en_sections = {}
    ar_sections = {}
    ur_sections = {}
    index_books = []

    for ch in chapters:
        ch_num = int(ch['chapterNumber'])
        ch_key = str(ch_num)
        print(f'  [{ch_num:>3}/{len(chapters)}] {ch.get("chapterEnglish", "")[:60]}',
              flush=True)

        index_books.append({
            'bookNumber':   ch_num,
            'book': [
                {'lang': 'en', 'name': ch.get('chapterEnglish') or ''},
                {'lang': 'ar', 'name': ch.get('chapterArabic')  or ''},
            ],
            'hadithsCount': int(ch.get('hadithCount') or 0),
        })

        page = 1
        while True:
            paged = get(f'{BASE}/hadiths', {
                'apiKey':   API_KEY,
                'book':     slug,
                'chapter':  ch_num,
                'paginate': 100,
                'page':     page,
            })['hadiths']

            for h in paged['data']:
                h_num    = str(h.get('hadithNumber') or '')
                narrator = h.get('englishNarrator') or ''

                en_body = h.get('hadithEnglish') or ''
                if en_body:
                    en_sections.setdefault(ch_key, []).append({
                        'hadithNumber': h_num,
                        'hadith': [{'lang': 'en', 'narrator': narrator, 'body': en_body}],
                    })

                ar_body = h.get('hadithArabic') or ''
                if ar_body:
                    ar_sections.setdefault(ch_key, []).append({
                        'hadithNumber': h_num,
                        'hadith': [{'lang': 'ar', 'narrator': narrator, 'body': ar_body}],
                    })

                ur_body = h.get('hadithUrdu') or ''
                if ur_body:
                    ur_sections.setdefault(ch_key, []).append({
                        'hadithNumber': h_num,
                        'hadith': [{'lang': 'ur', 'narrator': narrator, 'body': ur_body}],
                    })

            if page >= paged['last_page']:
                break
            page += 1
            time.sleep(0.1)

    os.makedirs(OUT_DIR, exist_ok=True)

    with open(f'{OUT_DIR}/{book_id}_index.json', 'w', encoding='utf-8') as f:
        json.dump({
            'title':      title,
            'collection': slug,
            'source':     'hadithapi_v1',
            'books':      sorted(index_books, key=lambda x: x['bookNumber']),
        }, f, ensure_ascii=False)

    for lang, sections in [('en', en_sections), ('ar', ar_sections), ('ur', ur_sections)]:
        with open(f'{OUT_DIR}/{book_id}_{lang}.json', 'w', encoding='utf-8') as f:
            json.dump({
                'source':   'hadithapi_v1',
                'lang':     lang,
                'sections': sections,
            }, f, ensure_ascii=False)

    print(f'  Done — {len(index_books)} chapters bundled.', flush=True)


if __name__ == '__main__':
    for slug, book_id, title in BOOKS:
        bundle_book(slug, book_id, title)
    print('\nAll hadith books bundled successfully.', flush=True)
