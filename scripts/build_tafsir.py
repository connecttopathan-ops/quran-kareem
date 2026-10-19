#!/usr/bin/env python3
"""Build the bundled Al-Mukhtasar tafsir assets from the raw upstream editions.

Source: https://github.com/spa5k/tafsir_api (editions mirrored from QUL /
Quran.com). Al-Mukhtasar fi Tafsir al-Qur'an al-Karim, Tafsir Center for
Quranic Studies.

The upstream text needs four passes before it can ship:

  1. Encoding repair. The Italian edition has mojibake in Ya'qub / Ishaq
     ("Ya'q(u)b" arrives as "Ya'ǭub"); the Spanish edition carries
     zero-width spaces and non-breaking hyphens.
  2. Honorific glyphs. The Spanish edition encodes honorifics as bare Latin
     letters from an Arabic-honorifics font: a lone "u" after a prophet's name
     is the (peace be upon him) glyph, a lone "r" after Muhammad / the Prophet
     / the Messenger is the (sallallahu alayhi wa sallam) glyph. Rendered in a
     normal font they read as stray letters ("albricias para Jose u.").
  3. Prophet names. English, French and Spanish use localised names (Joseph,
     Moise, Jose); the Italian edition already uses the Arabic forms. We
     normalise all four to the Arabic forms the app uses elsewhere.
  4. Honorifics. Added after the FIRST mention of each prophet in each verse,
     never where the upstream text already supplies one. Per-occurrence would
     be unreadable: "Moses" alone appears 371 times in the English edition.

Run:  python3 scripts/build_tafsir.py <raw_dir> [--out assets/tafsir] [--check]

<raw_dir> holds the untouched downloads as <raw_dir>/<lang>/<surah>.json.
--check reports what would change without writing anything.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import unicodedata

LANGS = ("en", "fr", "es", "it")

# ---------------------------------------------------------------------------
# 1. Encoding repair, per language.
# ---------------------------------------------------------------------------

ENCODING_FIXES = {
    "it": [
        ("Ya'ǭùb", "Ya'qūb"),   # Ya'qǭùb -> Ya'qūb
        ("Ya'ǭūb", "Ya'qūb"),
        ("Ya'ǭub", "Ya'qūb"),
        ("Is'ħāǭ", "Is'ħāq"),
        ("Is-ħāǭ", "Is'ħāq"),
        ("ǭ", "q"),                        # any remaining stray ǭ
    ],
    "es": [
        ("​", ""),                         # zero-width space
        ("‑", "-"),                        # non-breaking hyphen
    ],
    "fr": [],
    "en": [],
}

# ---------------------------------------------------------------------------
# 2. Prophet and angel names: localised form -> the Arabic form.
#
# Case-sensitive, word-boundary matched. Audited against the real corpus:
# every capitalised Lot / John / Job in the English edition is the prophet,
# so there are no common-noun collisions. Pharaoh and Satan are deliberately
# left in each language's own form -- they are not names we are normalising.
# ---------------------------------------------------------------------------

NAME_MAP = {
    "en": {
        "Joseph": "Yusuf", "Jacob": "Ya'qub", "Moses": "Musa",
        "Abraham": "Ibrahim", "Isaac": "Ishaq", "Ishmael": "Isma'il",
        "Jesus": "Isa", "Mary": "Maryam", "Noah": "Nuh", "Jonah": "Yunus",
        "Lot": "Lut", "Aaron": "Harun", "Solomon": "Sulayman",
        "David": "Dawud", "John": "Yahya", "Zachariah": "Zakariya",
        "Zechariah": "Zakariya", "Elijah": "Ilyas", "Elias": "Ilyas",
        "Elisha": "Alyasa", "Enoch": "Idris", "Job": "Ayyub",
        "Ezekiel": "Dhul-Kifl", "Gabriel": "Jibril", "Michael": "Mika'il",
        "Eve": "Hawwa", "Saul": "Talut", "Goliath": "Jalut",
    },
    "fr": {
        "Joseph": "Yusuf", "Jacob": "Ya'qub", "Moïse": "Musa",
        "Abraham": "Ibrahim", "Isaac": "Ishaq", "Ismaël": "Isma'il",
        "Jésus": "Isa", "Marie": "Maryam", "Noé": "Nuh",
        "Jonas": "Yunus", "Loth": "Lut", "Lot": "Lut", "Aaron": "Harun",
        "Salomon": "Sulayman", "David": "Dawud", "Jean": "Yahya",
        "Zacharie": "Zakariya", "Élie": "Ilyas", "Elie": "Ilyas",
        "Élisée": "Alyasa", "Job": "Ayyub", "Gabriel": "Jibril",
        "Ève": "Hawwa", "Eve": "Hawwa",
    },
    "es": {
        "José": "Yusuf", "Jacob": "Ya'qub", "Moisés": "Musa",
        "Abraham": "Ibrahim", "Isaac": "Ishaq", "Ismael": "Isma'il",
        "Jesús": "Isa", "María": "Maryam", "Noé": "Nuh",
        "Jonás": "Yunus", "Lot": "Lut", "Aarón": "Harun",
        "Salomón": "Sulayman", "David": "Dawud", "Juan": "Yahya",
        "Zacarías": "Zakariya", "Elías": "Ilyas",
        "Eliseo": "Alyasa", "Job": "Ayyub", "Gabriel": "Jibril",
        "Adán": "Adam", "Eva": "Hawwa",
    },
    # The Italian edition already uses Arabic forms, but in its own
    # transliteration (Muhammed, Suleymen, Zekerye) and with macrons. These
    # spellings were extracted from the corpus, not guessed -- the edition
    # uses "Muhammed" 237x and never "Muhammad", for instance.
    "it": {
        "Mūsā": "Musa", "Yūsuf": "Yusuf",
        "Ibrāhīm": "Ibrahim", "Ibrahīm": "Ibrahim",
        "Nūħ": "Nuh", "Dāwūd": "Dawud",
        "Hārūn": "Harun", "Yūnus": "Yunus",
        "Jibrīl": "Jibril", "Hūd": "Hud", "Idrīs": "Idris",
        "Ayyūb": "Ayyub", "Ya'qūb": "Ya'qub",
        "Is'ħāq": "Ishaq", "Is-ħāq": "Ishaq",
        "Ismā'īl": "Isma'il", "Ismaā'īl": "Isma'il",
        "Suleymēn": "Sulayman", "Sulaymān": "Sulayman",
        "Zekeryē": "Zakariya", "Zakariyyā": "Zakariya",
        "Yeħyē": "Yahya", "Yaħyā": "Yahya",
        "Lūţ": "Lut", "Lūt": "Lut",
        "Muħammed": "Muhammad", "Muħammad": "Muhammad",
        "Sāleħ": "Salih", "Šāliħ": "Salih",
        "Sāliħ": "Salih",
    },
}

# Who gets an honorific, keyed by the Arabic form the name pass produces.
#
# This is deliberately NOT "everything in NAME_MAP": Talut (Saul) is a king,
# Jalut (Goliath) is the enemy he fought, and Hawwa is not a prophet. Taking
# the mapping's values wholesale would print "Jalut (peace be upon him)".
# The 25 prophets named in the Qur'an, plus Maryam (feminine form) and the
# two named angels.
PROPHETS = (
    "Adam", "Idris", "Nuh", "Hud", "Salih", "Ibrahim", "Lut", "Isma'il",
    "Ishaq", "Ya'qub", "Yusuf", "Ayyub", "Shu'ayb", "Musa", "Harun",
    "Dhul-Kifl", "Dawud", "Sulayman", "Ilyas", "Alyasa", "Yunus",
    "Zakariya", "Yahya", "Isa", "Muhammad",
)
ANGELS = ("Jibril", "Mika'il")
FEMININE = ("Maryam",)
NO_HONORIFIC = ("Talut", "Jalut", "Hawwa")

# Names that take the Prophet Muhammad's honorific rather than a prophet's.
MUHAMMAD_FORMS = {
    "en": ["Muhammad"],
    "fr": ["Muħammad", "Muhammad"],
    "es": ["Mujámmad", "Muhammad"],
    "it": ["Muhammad", "Muħammed", "Muħammad"],
}

# ---------------------------------------------------------------------------
# 2b. Spanish honorific glyphs (bare font letters) -> real text.
# Audited: "u" follows Moises/Abraham/Noe/Jesus/Gabriel/Lot/Jose/Salih/Hud/
# Salomon; "r" follows Mujammad/Profeta/Mensajero/Al-lah.
# ---------------------------------------------------------------------------

SALLALLAHU = "ﷺ"          # ﷺ
HONORIFIC = {
    "en": " (peace be upon him)",
    "fr": " (paix et salut sur lui)",
    "es": " (la paz sea con él)",
    "it": " (pace a lui)",
}
HONORIFIC_PL = {
    "en": " (peace be upon them)",
    "fr": " (paix et salut sur eux)",
    "es": " (la paz sea con ellos)",
    "it": " (pace a loro)",
}
HONORIFIC_F = {
    "en": " (peace be upon her)",
    "fr": " (paix sur elle)",
    "es": " (la paz sea con ella)",
    "it": " (pace a lei)",
}
# Markers that mean "an honorific is already here" — never double up.
# A verse that already honours a LIST of prophets collectively gets nothing
# added: inserting per name turns "Isma'il, Alyasa, Yunus and Lut (peace be
# upon them)" into a thicket, and leaves the plural form attached to one name.
PLURAL_PRESENT = {
    "en": [r"peace be upon them"],
    "fr": [r"paix (?:et salut )?sur eux"],
    "es": [r"la paz sea con ellos"],
    "it": [r"pace a tutti loro", r"pace a loro"],
}
HONORIFIC_PRESENT = {
    "en": [r"\(peace be upon (?:him|them|her)\)", r"peace be upon (?:him|them)", SALLALLAHU],
    "fr": [r"\(paix et salut sur (?:lui|eux)\)", r"paix sur (?:lui|eux)", SALLALLAHU],
    "es": [r"\(la paz sea con (?:él|ellos)\)", r"la paz sea con", SALLALLAHU],
    "it": [r"pace a (?:lui|loro)", r"pace e benedizione", r"la pace sia su", SALLALLAHU],
}


def fix_encoding(text: str, lang: str) -> str:
    for bad, good in ENCODING_FIXES[lang]:
        text = text.replace(bad, good)
    if lang == "it":
        # Upstream glues Arabic glyphs onto the end of Latin words
        # ("Torahالت", "Allahالله", "Al-Shamالش"). Only strip a run with no
        # space before it — standalone Arabic is a deliberate quotation.
        text = re.sub(r"(?<=[^\W\d_])[؀-ۿݐ-ݿ]+", "", text)
    return text


def fix_spanish_glyphs(text: str) -> str:
    """A lone 'u' or 'r' in the Spanish edition is an honorific glyph."""
    # "r" only after the attested preceding words, never any bare letter.
    text = re.sub(
        r"\b(Mujámmad|Muhammad|Profeta|Mensajero|Al-lah|Allah)\s+r\b",
        r"\1 " + SALLALLAHU,
        text,
    )
    text = re.sub(
        r"\b([A-ZÁÉÍÓÚ][\wáéíóúñ'‑-]*)\s+u\b",
        r"\1" + HONORIFIC["es"],
        text,
    )
    return text


def map_names(text: str, lang: str) -> str:
    mapping = NAME_MAP[lang]
    if not mapping:
        return text
    # Longest first so "Isma'il" wins before any shorter prefix.
    for src in sorted(mapping, key=len, reverse=True):
        text = re.sub(
            r"(?<![\w'’])" + re.escape(src) + r"(?![\w'’])",
            mapping[src],
            text,
        )
    return text


def already_honoured(text: str, end: int, lang: str) -> bool:
    """True if an honorific already sits just after position `end`."""
    window = text[end:end + 46]
    return any(re.match(r"[\s,]*" + pat, window) for pat in HONORIFIC_PRESENT[lang])


def add_honorifics(text: str, lang: str) -> str:
    """Add an honorific after the first mention of each name in this verse.

    If the upstream text already honours a name ANYWHERE in the verse we add
    nothing for it — checking only the first mention produced verses like
    "Yusuf (pbuh) said to his father ... good news for Yusuf (pbuh)", because
    the source happened to honour the last mention and not the first.
    """
    if any(re.search(p, text, re.I) for p in PLURAL_PRESENT[lang]):
        return text

    targets = sorted(set(PROPHETS) | set(ANGELS) | set(FEMININE))
    muhammad = set(MUHAMMAD_FORMS[lang]) | {"Muhammad"}

    spans: list[tuple[int, int, str]] = []
    honoured_names: set[str] = set()
    for name in targets:
        for m in re.finditer(r"(?<![\w'’])" + re.escape(name) + r"(?![\w'’])", text):
            spans.append((m.start(), m.end(), name))
            if already_honoured(text, m.end(), lang):
                honoured_names.add(name)
    spans.sort()

    # A run of three or more prophets is a list: honour it once, collectively,
    # after the last name — the convention the English edition itself uses at
    # 6:84 ("...Musa and his brother Harun (peace be upon them)"). Muhammad is
    # kept out of it; he takes his own honorific.
    listed = [s for s in spans if s[2] not in muhammad]
    if len({s[2] for s in listed}) >= 3 and not honoured_names:
        last_end = listed[-1][1]
        inserts = [(last_end, HONORIFIC_PL[lang])]
        for _start, end, name in spans:
            if name in muhammad:
                inserts.append((end, SALLALLAHU))
                break
        for pos, ins in sorted(inserts, reverse=True):
            text = text[:pos] + ins + text[pos:]
        return text

    seen: set[str] = set()
    inserts: list[tuple[int, str]] = []
    for _start, end, name in spans:
        if name in seen or name in honoured_names:
            continue
        seen.add(name)
        if name in muhammad:
            ins = SALLALLAHU
        elif name in FEMININE:
            ins = HONORIFIC_F[lang]
        else:
            ins = HONORIFIC[lang]
        if not ins.startswith((" ", ",")):
            ins = " " + ins
        inserts.append((end, ins))

    # Apply right-to-left so earlier offsets stay valid.
    for pos, ins in sorted(inserts, reverse=True):
        text = text[:pos] + ins + text[pos:]
    return text


def clean(text: str, lang: str) -> str:
    text = fix_encoding(text, lang)
    if lang == "es":
        text = fix_spanish_glyphs(text)
    text = map_names(text, lang)
    text = add_honorifics(text, lang)
    text = unicodedata.normalize("NFC", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" ([.,;:!?])", r"\1", text)
    return text.strip()


def load_raw(raw_dir: str, lang: str, surah: int) -> list[dict]:
    path = os.path.join(raw_dir, lang, f"{surah}.json")
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    return data.get("ayahs", data) if isinstance(data, dict) else data


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("raw_dir")
    ap.add_argument("--out", default="assets/tafsir")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    counts = {
        s["number"]: s["verses"]
        for s in json.load(open(os.path.join(repo, "assets", "surahs.json"), encoding="utf-8"))
    }

    failures: list[str] = []
    for lang in LANGS:
        out_dir = os.path.join(repo, args.out, lang)
        if not args.check:
            os.makedirs(out_dir, exist_ok=True)
        total = changed = bytes_out = 0
        for n in range(1, 115):
            rows = load_raw(args.raw_dir, lang, n)
            if len(rows) != counts[n]:
                failures.append(f"{lang} surah {n}: {len(rows)} verses, expected {counts[n]}")
                continue
            doc: dict[str, str] = {}
            for row in rows:
                ayah = int(row["ayah"])
                before = (row.get("text") or "").strip()
                after = clean(before, lang)
                if not after:
                    failures.append(f"{lang} {n}:{ayah}: empty after cleaning")
                total += 1
                if after != before:
                    changed += 1
                doc[str(ayah)] = after
            if len(doc) != counts[n]:
                failures.append(f"{lang} surah {n}: {len(doc)} keys after build")
                continue
            blob = json.dumps(doc, ensure_ascii=False, separators=(",", ":"))
            bytes_out += len(blob.encode("utf-8"))
            if not args.check:
                with open(os.path.join(out_dir, f"{n}.json"), "w", encoding="utf-8") as fh:
                    fh.write(blob)
        print(f"{lang}: {total} verses, {changed} rewritten, {bytes_out / 1048576:.2f} MB")

    if failures:
        print(f"\nFAILURES ({len(failures)}):", file=sys.stderr)
        for f in failures[:40]:
            print("  " + f, file=sys.stderr)
        return 1
    print("\nOK" + (" (check only, nothing written)" if args.check else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
