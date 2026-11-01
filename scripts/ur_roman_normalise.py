#!/usr/bin/env python3
"""Normalise a batch of Roman Urdu tafsir before it is written.

The same handful of faults reappear in every batch no matter how carefully
the text is written — em-dashes above all, which the reference translation
never uses in 6236 verses and the English source never uses either. Rather
than find them with the checker and repair them afterwards, apply this when
the text is produced.

    from ur_roman_normalise import normalise
    verses = {k: normalise(v) for k, v in verses.items()}

It only fixes what can be fixed mechanically without judgement. Everything
that needs a reader — meaning, register, clause order — is still the
checker's job and then a human's.
"""

from __future__ import annotations

import re

# Spellings the reference settles. Keyed wrong -> right; each pair was
# verified by counting both forms in assets/translations/ur-roman.json.
SPELLINGS = [
    ("Isma'il", "Ismail"), ("Dawud", "Dawood"), ("Musa", "Moosa"),
    ("Nuh", "Nooh"), ("Harun", "Haroon"), ("Ayyub", "Ayub"),
    ("Shu'ayb", "Shoaib"), ("Sulayman", "Sulaiman"), ("Ya'qub", "Yaqub"),
    ("Aziz", "Azeez"), ("makhluq", "makhlooq"), ("panah", "panaah"),
    ("qubool", "qabool"), ("pohanch", "pahunch"), ("guroh", "giroh"),
    ("qaayam", "qayam"), ("bakhshne", "bakshne"), ("jadoogar", "jaadugar"),
    ("meherban", "meharban"), ("ghafil", "gaafil"), ("ghaflat", "gaflat"),
    ("insanon", "insaano"), ("bheriya", "bhediya"), ("sooli", "suli"),
    ("eteraf", "iqrar"), ("zaroortmand", "zaroorat-mand"),
    ("nafson", "nafs"), ("chorron", "choron"), ("shaksson", "shakson"),
    ("gharr ", "ghadh "), ("daman", "daaman"), ("izhaar", "izhar"),
    ("bharakti", "bhadakti"), ("bharakne", "bhadakne"),
    ("un ne ", "unhon ne "), ("Un ne ", "Unhon ne "),
    ("kaun\u012b", "kauni"), ("Qur\u2019\u0101n", "Quran"),
    ("unhon ke", "un ke"), ("mu pher", "munh pher"), ("mu kar", "munh kar"),
]

# Words that must never be written, with what to write instead. "akela"
# means lonely; using it of Allah is doctrinally wrong, and it has come back
# twice now at volume.
BANNED = [
    (re.compile(r"(?<![a-z])akela(?![a-z])", re.I), "yakta"),
    # Settled by counting both forms in assets/translations/ur-roman.json and
    # in the tafsir surahs already shipped.
    (re.compile(r"(?<![a-z])(?=[Kk])([Kk])aafir"), r"\1afir"),
    (re.compile(r"(?<![a-z])([Rr])ahmat(?![a-z])"), r"\1ehmat"),
    (re.compile(r"(?<![a-z])([Gg])unaah(?![a-z])"), r"\1unah"),
    (re.compile(r"(?<![a-z])([Gg])unaahon(?![a-z])"), r"\1unahon"),
    (re.compile(r"(?<![a-z-])([Hh])aq(?![a-z-])"), r"\1aqq"),
    (re.compile(r"(?<![a-z-])([Hh])an(?![a-z-])"), r"\1aan"),
    (re.compile(r"(?<![a-z])(?<!y)ilah(?![a-z])"), "maabood"),
]


# The corpus writes the Prophet's honorific as the ligature, never spelled out,
# and uses the oblique plural "mominon" everywhere but the vocative "Aey momino".
HONORIFIC = re.compile(
    r"\s*\((?:sallallahu|salallahu)\s+alaihi\s+wa\s?sallam\)|"
    r"\s*\(peace be upon him\)|"
    r"\s*\u0635\u0644\u0649 \u0627\u0644\u0644\u0647 \u0639\u0644\u064a\u0647 \u0648\u0633\u0644\u0645")
VOCATIVE_MOMINO = re.compile(r"(?<!Aey )(?<![a-z])momino(?![a-z])")


def fix_honorific(text: str) -> str:
    text = HONORIFIC.sub(" \ufdfa", text)
    text = re.sub(r"(?:\s*\ufdfa){2,}", " \ufdfa", text)
    return re.sub(r"\s+\ufdfa", " \ufdfa", text)


def strip_em_dashes(text: str) -> str:
    """Rebuild every em-dash as Urdu punctuation.

    A paired dash becomes a pair of commas, a dash before a connective
    becomes a comma, and anything left becomes a colon, which is usually
    what the dash was standing in for.
    """
    text = re.sub(r"\s*—\s*(woh paak hai|jo paak hai)\s*—\s*",
                  ", jo paak hai, ", text)
    text = re.sub(r"\s*—\s*([^—]{1,60}?)\s*—\s*", r", \1, ", text)
    text = re.sub(
        r"\s*—\s*(?=(?:aur|to|kyunke|jab|agar|jaise|jaisa|woh|un|us|"
        r"haalanke|chahe|siwaye|jo|warna|yani|magar|balke|yeh|phir|taake|"
        r"jin|jis|is|in)\b)", ", ", text)
    return re.sub(r"\s*—\s*", ": ", text)


def normalise(text: str) -> str:
    text = fix_honorific(text)
    text = VOCATIVE_MOMINO.sub("mominon", text)
    text = strip_em_dashes(text)
    for bad, good in SPELLINGS:
        text = text.replace(bad, good)
    for rx, good in BANNED:
        text = rx.sub(good, text)
    text = re.sub(r",\s*,", ",", text)
    text = re.sub(r",\s*:", ":", text)
    text = re.sub(r"\s+([,.:;!?])", r"\1", text)
    text = re.sub(r"[ \t]{2,}", " ", text)
    return text.strip()


if __name__ == "__main__":
    import json
    import sys

    for path in sys.argv[1:]:
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh)
        changed = sum(1 for k in doc if normalise(doc[k]) != doc[k])
        doc = {k: normalise(doc[k]) for k in sorted(doc, key=int)}
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(json.dumps(doc, ensure_ascii=False, separators=(",", ":")))
        print(f"{path}: {changed} verses normalised")
