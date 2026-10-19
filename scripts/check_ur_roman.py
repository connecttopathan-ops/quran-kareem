#!/usr/bin/env python3
"""Audit the Roman Urdu tafsir against the glossary and against the English.

Roman Urdu has no standard orthography, so the failure mode is not a wrong
word but an inconsistent one — tafsir that says "Musa" above a translation
that says "Moosa". This checks for that, for English left untranslated, and
for verses that drifted far from the length of their source.

Run:  python3 scripts/check_ur_roman.py [--surah N] [--verbose]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UR = os.path.join(REPO, "assets", "tafsir", "ur-roman")
EN = os.path.join(REPO, "assets", "tafsir", "en")
GLOSSARY = os.path.join(REPO, "scripts", "ur_roman_glossary.json")

# English words that should never survive into Roman Urdu output. Short,
# unambiguous, and absent from the Roman Urdu of ur-roman.json — "to", "par",
# "in", "do", "ho" and "main" are all real Roman Urdu words, so they are not
# listed here.
ENGLISH_LEAKS = {
    "the", "and", "that", "with", "from", "they", "their", "them", "which",
    "when", "because", "about", "would", "there", "these", "those", "what",
    "who", "whom", "whose", "while", "after", "before", "upon", "shall",
    "will", "have", "has", "had", "been", "being", "were", "was", "are",
    "said", "says", "tell", "told", "believe", "believers", "disbelievers",
    "messenger", "prophet", "punishment", "mercy", "guidance", "worship",
    "earth", "heaven", "heavens", "people", "truth", "lord", "god",
}


def load_glossary() -> tuple[dict[str, str], dict[str, str]]:
    """Return (avoid_spelling -> correct_spelling, correct -> gloss)."""
    with open(GLOSSARY, encoding="utf-8") as fh:
        doc = json.load(fh)
    avoid: dict[str, str] = {}
    gloss: dict[str, str] = {}
    for section in ("names", "terms"):
        for word, meta in doc[section].items():
            if word.startswith("_") or not isinstance(meta, dict):
                continue
            gloss[word] = meta.get("gloss", "")
            for bad in meta.get("avoid", []):
                avoid[bad] = word

    # The glossary must not contradict itself. Two faults are easy to make and
    # both produce findings against correct translations: listing a word as a
    # variant of itself, and listing a real word as a variant of another real
    # word — "din" (day) is not a misspelling of "deen" (religion).
    broken = [f"'{bad}' is listed as a variant of itself"
              for bad, good in avoid.items() if bad == good]
    broken += [f"'{bad}' is a canonical spelling but listed as a variant of '{good}'"
               for bad, good in avoid.items() if bad in gloss]
    if broken:
        print("glossary is self-contradictory:", file=sys.stderr)
        for b in broken:
            print("  " + b, file=sys.stderr)
        sys.exit(2)

    return avoid, gloss


def words(text: str) -> list[str]:
    return re.findall(r"[A-Za-z][A-Za-z'’-]*", text)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--surah", type=int)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    if not os.path.isdir(UR):
        print(f"nothing to check: {UR} does not exist", file=sys.stderr)
        return 1

    avoid, _gloss = load_glossary()
    counts = {
        s["number"]: s["verses"]
        for s in json.load(open(os.path.join(REPO, "assets", "surahs.json"), encoding="utf-8"))
    }

    surahs = [args.surah] if args.surah else sorted(
        int(f[:-5]) for f in os.listdir(UR) if f.endswith(".json")
    )

    problems: list[str] = []
    off_glossary: Counter[str] = Counter()
    leaks: Counter[str] = Counter()
    total = short = long = 0
    done_verses = 0

    for n in surahs:
        ur_path = os.path.join(UR, f"{n}.json")
        if not os.path.exists(ur_path):
            problems.append(f"surah {n}: no file")
            continue
        ur = json.load(open(ur_path, encoding="utf-8"))
        en = json.load(open(os.path.join(EN, f"{n}.json"), encoding="utf-8"))

        missing = [v for v in en if v not in ur]
        extra = [v for v in ur if v not in en]
        if extra:
            problems.append(f"surah {n}: verses not in the English: {extra[:6]}")
        if missing and args.verbose:
            problems.append(f"surah {n}: {len(missing)} verses not yet translated")

        done_verses += len(ur)
        for v, text in ur.items():
            total += 1
            ref = f"{n}:{v}"
            if not text.strip():
                problems.append(f"{ref}: empty")
                continue

            for w in words(text):
                if w in avoid:
                    off_glossary[f"{w} -> {avoid[w]}"] += 1
                    problems.append(f"{ref}: '{w}' should be '{avoid[w]}'")
                if w.lower() in ENGLISH_LEAKS:
                    leaks[w.lower()] += 1
                    problems.append(f"{ref}: English left in: '{w}'")

            # Roman Urdu runs a little longer than English; well outside
            # 0.6-2.0x usually means a truncated or padded verse.
            src = en.get(v, "")
            if src:
                ratio = len(text) / len(src)
                if ratio < 0.6:
                    short += 1
                    problems.append(f"{ref}: {ratio:.2f}x the English — truncated?")
                elif ratio > 2.0:
                    long += 1
                    problems.append(f"{ref}: {ratio:.2f}x the English — padded?")

    expected = sum(counts.values())
    print(f"translated: {done_verses} verses across {len(surahs)} surah(s)"
          f"  ({done_verses / expected:.1%} of {expected})")
    print(f"length outliers: {short} short, {long} long")
    print(f"off-glossary spellings: {sum(off_glossary.values())}"
          + (f"  {dict(off_glossary.most_common(8))}" if off_glossary else ""))
    print(f"English left in: {sum(leaks.values())}"
          + (f"  {dict(leaks.most_common(8))}" if leaks else ""))

    if problems:
        print(f"\n{len(problems)} finding(s):")
        for p in problems[: (400 if args.verbose else 40)]:
            print("  " + p)
        if len(problems) > 40 and not args.verbose:
            print(f"  ... {len(problems) - 40} more (--verbose)")
        return 1

    print("\nclean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
