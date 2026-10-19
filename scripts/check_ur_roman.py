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


REFERENCE = os.path.join(REPO, "assets", "translations", "ur-roman.json")

# Words that are legitimately absent from the reference translation: proper
# nouns the tafsir introduces, and bracketed source citations.
VOCAB_EXEMPT = {
    "lahab", "muttalib", "jameel", "umm", "abu", "bin", "ghafir", "surah",
    "arabi", "lafz", "ar", "rehman", "raheem", "makkah", "islam",
}


def reference_vocab() -> Counter[str]:
    """Every word of the Roman Urdu Quran translation, with its frequency."""
    doc = json.load(open(REFERENCE, encoding="utf-8"))
    counts: Counter[str] = Counter()
    for verses in doc.values():
        for text in verses.values():
            counts.update(w.lower() for w in words(text))
    return counts


def skeletons(word: str) -> set[str]:
    """Spelling-variant keys for a word.

    Roman Urdu's variation is almost entirely vowel length and aspiration:
    makhluq/makhlooq, panah/panaah, hath/haath, qubool/qabool,
    pohanch/pahunch, guroh/giroh, bakhshne/bakshne. Collapsing long vowels
    (and, separately, stripping 'h') maps the variants onto one key, so a
    spelling with no support in the reference can be matched to the one that
    has it without hard-coding the pairs.
    """
    w = re.sub(r"[^a-z]", "", word.lower())
    bare = re.sub(r"[aeiou]", "", w)              # guroh / giroh  -> grh
    no_h = re.sub(r"[aeiou]", "", w.replace("h", ""))  # bakhshne / bakshne -> bksn
    # Keys must be long enough not to collide: a 3-letter consonant
    # skeleton matches unrelated words ("achhe"/"chahe" are both "chh").
    return {k for k in (bare, no_h) if len(k) >= 4}


def vocab_findings(text: str, ref: Counter[str], ref_keys: dict[str, tuple[str, int]],
                   ref_min: int) -> list[tuple[str, str, int]]:
    """Words absent from the reference that a well-supported variant matches."""
    out = []
    for w in set(words(text)):
        lw = w.lower()
        if lw in VOCAB_EXEMPT or len(lw) < 4:
            continue
        mine = ref[lw]
        for key in skeletons(lw):
            hit = ref_keys.get(key)
            if not hit or hit[0] == lw or hit[1] < ref_min:
                continue
            # Same opening letter, similar length — without this the
            # skeleton matches different words outright.
            if hit[0][0] != lw[0] or abs(len(hit[0]) - len(lw)) > 2:
                continue
            # Flag an unattested spelling, and also a barely-attested one
            # against a much better supported variant: "panah" has 1
            # occurrence against "panaah"'s 42, so a zero test misses it.
            if mine * 8 < hit[1]:
                out.append((w, hit[0], hit[1]))
                break
    return out


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


# Familiar (tu) forms. Correct when the worshipper addresses Allah, wrong when
# aimed at the Prophet, where Urdu wants the respectful aap form. The glossary's
# "address" section has the rule.
#
# "dekhe" is only a familiar form when "tu" governs it: in "gyarah sitare
# dekhe" it is the past tense, "saw eleven stars". Matching it bare flagged a
# correct verse, so the pronoun is required.
FAMILIAR = re.compile(
    r"\b(keh de|keh do|jaan le|jaan lo|sun le|tujhe|tujh\b|tere\b|tera\b|"
    r"teri\b|tu\b|tu [a-z]+ dekhe|tu dekhe)\b"
)
# Marks a verse as addressing the Prophet.
ADDRESSES_PROPHET = re.compile(r"Aey (Rasool|Nabi|Muhammad)")
# Marks a verse as addressing Allah, where familiar forms are correct.
ADDRESSES_ALLAH = re.compile(
    r"\b(hum|humein|hamare)\b.{0,80}\b(tere|teri|tujh|tujhe|tu)\b|"
    r"\b(tere|teri|tujh|tujhe)\b.{0,40}\b(ibadat|panah|siwa|hidayat|madad maangte)\b",
    re.I,
)


# Outright grammar errors, each verified against the reference translation
# before being listed here. Every one of these was produced by a first draft
# and missed by a checker that only looked at vocabulary.
# The em-dash is the clearest signature of machine origin in this corpus: the
# reference translation uses none in all 6236 verses, and the English source
# uses none either, so any dash here was invented rather than carried over.
# Every English appositive must become "yani X", a "jo ... hai" relative, or a
# repeated noun.
EM_DASH = re.compile(r"\u2014")

# A nominative pronoun cannot govern a perfective transitive: "Woh aaye aur
# bataya" needs "unhon ne bataya". Only flagged when the clause after "aur"
# introduces no ergative of its own.
ERGATIVE_GAP = re.compile(
    r"(?<![a-z])(?:Woh|woh)\s+(?:[a-z\u2019'-]+\s+){0,6}?"
    r"(?:aaye|aaya|hue|pahuncha|pahunche|raha|rahe|gaye)\b"
    # No ergative may intervene anywhere before the target verb: in
    # "Woh aaye, to Yusuf ne ... kaha" the subject of "kaha" is "Yusuf ne",
    # so there is nothing wrong.
    r"((?:(?!\bne\b)[^.\u201c\u201d]){0,60}?)"
    r"\baur\b((?:(?!\bne\b)[^.\u201c\u201d]){0,40}?)"
    r"\b(bataya|kaha|poocha|kar diya|de diya|daala|liya|churaya)\b")

GRAMMAR = [
    (re.compile(r"(?<![a-z])un ne(?![a-z])", re.I), "un ne", "unhon ne",
     "the ergative of the honorific/plural 'woh' — the reference uses "
     "'unhon ne' 287 times and 'un ne' never"),
    (re.compile(r"(?<![a-z])unhon ke(?![a-z])", re.I), "unhon ke", "un ke",
     "'unhon' takes only 'ne'; before any other postposition it is 'un'"),
    (re.compile(r"(?<![a-z])nafson(?![a-z])", re.I), "nafson", "nafs",
     "'nafs' is not pluralised this way; the reference has 'tumhare nafs ne'"),
    (re.compile(r"(?<![a-z])chorron(?![a-z])", re.I), "chorron", "choron",
     "spelling"),
    (re.compile(r"(?<![a-z])shaksson(?![a-z])", re.I), "shaksson", "shakson",
     "spelling"),
    (re.compile(r"(?<![a-z])mu (?=kar|phere|pher)", re.I), "mu", "munh",
     "'mu karna' is not a verb; the word is 'munh'"),
    (re.compile(r"(?<![a-z])gharr (?=liye|li)", re.I), "gharr", "ghadh",
     "spelling"),
    # Spellings this surah walked through, each verified against the reference.
    (re.compile(r"(?<![a-z])Aziz(?![a-z])"), "Aziz", "Azeez",
     "the reference spells it Azeez (10) and Aziz twice"),
    (re.compile(r"(?<![a-z])han(?![a-z])", re.I), "han", "haan",
     "'han' collides with 'haan' (yes); the reference has haan 127 to han 13"),
    (re.compile(r"(?<![a-z])bheriya(?![a-z])", re.I), "bheriya", "bhediya",
     "the reference has bhediya; bheriya never appears"),
    (re.compile(r"(?<![a-z])sooli(?![a-z])", re.I), "sooli", "suli", "spelling"),
    (re.compile(r"(?<![a-z])eteraf(?![a-z])", re.I), "eteraf", "iqrar",
     "the reference's word for confession"),
    (re.compile(r"(?<![a-z])zaroortmand", re.I), "zaroortmand", "zaroorat-mand",
     "missing vowel"),
]

# "kaha ke" was too narrow: "kehta hai ke ... keh dijiye" and "kaha ke ... laad
# dein" both slipped through. Any reporting verb, and any respectful
# imperative, now count.
REPORTED_IMPERATIVE = re.compile(
    r"(kaha|kehta hai|kehte hain|bataya|poocha|farmaya|kehne lage) ke(?![a-z])"
    r"([^.\u201c\u201d]{0,80})", re.I)
RESPECTFUL_IMPERATIVE = re.compile(
    r"(?<![a-z])([a-z\u2019']+(?:iye|ein))(?![a-z])", re.I)

# "ke" opens a subordinate clause and cannot govern an imperative or a
# second-person pronoun. "kaha ke jao" is an ungrammatical hybrid: either
# close the frame and quote, or use the subjunctive.
KAHA_KE = re.compile(
    r"(kaha|bataya|poocha|kehne lage|farmaya) ke(?![a-z])(.{0,70})", re.I)
SECOND_PERSON = re.compile(
    r"(?<![a-z])(tum|tumhein|tumhare|tumhari|aap|jao|laao|batao|le jao|"
    r"daal do|laut do|sun lo|dekho)(?![a-z])", re.I)

# An honorific belongs in narration, never inside a character's own speech:
# the brothers plotting murder do not say "peace be upon him".
# Only an opening quote opens speech. Treating the closing curly quote as an
# opener matched forward from the end of a quotation into the narration that
# followed it, flagging a correctly placed honorific.
HONORIFIC_IN_SPEECH = re.compile(
    r"[“\"]\s*[^“”\"]{0,220}?\((?:alaihis|alaihas|alaihimus) salaam\)")


def grammar_findings(surah: int, verses: dict[str, str]) -> list[str]:
    out: list[str] = []
    for v in sorted(verses, key=int):
        text = verses[v]
        for rx, bad, good, why in GRAMMAR:
            for _ in rx.finditer(text):
                out.append(f"{surah}:{v}: '{bad}' -> '{good}' ({why})")
        for m in REPORTED_IMPERATIVE.finditer(text):
            hit = SECOND_PERSON.search(m.group(2)) or RESPECTFUL_IMPERATIVE.search(m.group(2))
            if hit:
                out.append(
                    f"{surah}:{v}: '{m.group(1)} ke ... {hit.group(1)}' — 'ke' cannot "
                    f"govern a second person or an imperative; quote it directly "
                    f"or use the subjunctive")
        for _ in EM_DASH.finditer(text):
            out.append(
                f"{surah}:{v}: an em-dash — the reference uses none in 6236 verses "
                f"and neither does the English; rebuild it as 'yani X', a "
                f"'jo ... hai' relative, or a repeated noun")
        for m in ERGATIVE_GAP.finditer(text):
            out.append(
                f"{surah}:{v}: '{m.group(0)[:60]}...' — a nominative pronoun cannot "
                f"govern the perfective transitive '{m.group(3)}'; it needs 'unhon ne'")
    return out


def honorific_speech_advisories(surah: int, verses: dict[str, str]) -> list[str]:
    """Honorifics inside a quotation — advisory, because it depends on who speaks.

    Yusuf naming "Ibrahim, Ishaq aur Yaqub (alaihimus salaam)" is pious; the
    brothers plotting murder saying it of Yusuf is absurd, and Yusuf saying it
    of himself is wrong. A checker cannot tell those apart, so it reports and
    a reader decides.
    """
    out: list[str] = []
    for v in sorted(verses, key=int):
        for _ in HONORIFIC_IN_SPEECH.finditer(verses[v]):
            out.append(
                f"{surah}:{v}: an honorific sits inside direct speech — fine if "
                f"the speaker is honouring someone else, wrong if hostile or "
                f"self-referential")
    return out


def prophet_address_findings(
    surah: int, verses: dict[str, str]
) -> tuple[list[str], list[str]]:
    """Flag familiar verb forms where the verse addresses the Prophet.

    Returns (failures, advisories).

    Only a verse carrying the vocative itself is a failure. Carrying the
    address forward until a verse addressed Allah was tried and is wrong for
    narrative surahs: surah 12 says "Aey Rasool" at 12:3 and then tells a
    story for 108 verses in which Ya'qub addresses Yusuf, Yusuf addresses the
    minister's wife, and Yusuf addresses Allah. Every one of those familiar
    forms is correct, and the carry-forward flagged 16 of them.

    A continuation does exist — 110:2 and 110:3 carry on from 110:1 — so the
    two verses after a vocative are reported as advisory instead, where a
    false positive costs nothing.
    """
    failures: list[str] = []
    advisories: list[str] = []
    numbers = sorted(verses, key=int)
    vocative_at = {v for v in numbers if ADDRESSES_PROPHET.search(verses[v])}

    for i, v in enumerate(numbers):
        text = verses[v]
        forms = {m if isinstance(m, str) else m[0] for m in FAMILIAR.findall(text)}
        if not forms:
            continue
        if v in vocative_at:
            for form in sorted(forms):
                failures.append(
                    f"{surah}:{v}: '{form}' is the familiar tu form in a verse "
                    f"addressing the Prophet — use the respectful aap form"
                )
        elif any(numbers[j] in vocative_at for j in range(max(0, i - 2), i)):
            if not ADDRESSES_ALLAH.search(text):
                advisories.append(
                    f"{surah}:{v}: familiar forms {sorted(forms)} shortly after a "
                    f"vocative — check whether this still addresses the Prophet"
                )
    return failures, advisories


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--surah", type=int)
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--ref-min", type=int, default=5, dest="ref_min",
                    help="how much support a reference spelling needs before "
                         "an unattested variant is flagged against it")
    args = ap.parse_args()

    if not os.path.isdir(UR):
        print(f"nothing to check: {UR} does not exist", file=sys.stderr)
        return 1

    avoid, _gloss = load_glossary()

    ref = reference_vocab()
    # One key per spelling-variant family, held by its best-supported member.
    ref_keys: dict[str, tuple[str, int]] = {}
    for word, n in ref.most_common():
        for key in skeletons(word):
            if key not in ref_keys:
                ref_keys[key] = (word, n)
    off_register: Counter[str] = Counter()
    advisories: list[str] = []
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
        problems.extend(grammar_findings(n, ur))
        advisories.extend(honorific_speech_advisories(n, ur))
        addr_fail, addr_advise = prophet_address_findings(n, ur)
        problems.extend(addr_fail)
        advisories.extend(addr_advise)
        for v, text in ur.items():
            total += 1
            vref = f"{n}:{v}"
            if not text.strip():
                problems.append(f"{vref}: empty")
                continue

            for w in words(text):
                if w in avoid:
                    off_glossary[f"{w} -> {avoid[w]}"] += 1
                    problems.append(f"{vref}: '{w}' should be '{avoid[w]}'")
                if w.lower() in ENGLISH_LEAKS:
                    leaks[w.lower()] += 1
                    problems.append(f"{vref}: English left in: '{w}'")

            for sent in re.split(r"[.!?]+", text):
                words_in = len(sent.split())
                if words_in > 32:
                    advisories.append(
                        f"{vref}: a {words_in}-word sentence — the reference "
                        f"averages 20 words; split at a clause boundary")

            for bad, good, cnt in vocab_findings(text, ref, ref_keys, args.ref_min):
                off_register[f"{bad} -> {good}"] += 1
                advisories.append(
                    f"{vref}: '{bad}' is rare in the Roman Urdu translation, "
                    f"which mostly spells this '{good}' ({cnt}x) — check")

            # Roman Urdu runs a little longer than English; well outside
            # 0.6-2.0x usually means a truncated or padded verse.
            src = en.get(v, "")
            if src:
                ratio = len(text) / len(src)
                if ratio < 0.6:
                    short += 1
                    problems.append(f"{vref}: {ratio:.2f}x the English — truncated?")
                elif ratio > 2.0:
                    long += 1
                    problems.append(f"{vref}: {ratio:.2f}x the English — padded?")

    expected = sum(counts.values())
    print(f"translated: {done_verses} verses across {len(surahs)} surah(s)"
          f"  ({done_verses / expected:.1%} of {expected})")
    print(f"length outliers: {short} short, {long} long")
    print(f"off-glossary spellings: {sum(off_glossary.values())}"
          + (f"  {dict(off_glossary.most_common(8))}" if off_glossary else ""))
    print(f"English left in: {sum(leaks.values())}"
          + (f"  {dict(leaks.most_common(8))}" if leaks else ""))
    print(f"spelling advisories (not failures): {len(advisories)}")

    if advisories and args.verbose:
        print(f"\nadvisory — fuzzy spelling matches, many are false positives:")
        for a in advisories[:60]:
            print("  " + a)

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
