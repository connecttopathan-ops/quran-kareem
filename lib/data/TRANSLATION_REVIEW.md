# Religious content — review needed before release

The translations of religious content in this directory were produced by an AI
assistant and **have not been checked by a qualified person**. The UI chrome in
`lib/l10n/*.arb` is ordinary product copy and carries no such caveat; this file
is only about scripture, supplications, and the Names of Allah.

A wrong button label is a bug. A wrong rendering of a Name of Allah is not the
same kind of thing. Please have someone qualified read the items below before
this ships.

## Status

| Content | Where | Languages | Reviewed |
|---|---|---|---|
| 99 Names of Allah — meanings | `asma_ul_husna.dart` | en fr es it de pt | **No** |
| 51 duas — translations | `../screens/duas_screen.dart` | en only | n/a |
| 30 curated ayahs — translation + reflection | `curated_ayahs.dart` | en only | n/a |
| Hasanat promises — Quran/hadith quotations | `hasanat_promises.dart` | en only | n/a |

Only the Names have been translated so far. The rest are still English-only.

## Pre-existing problems in the English source

Found while translating; **these affect English users today** and are not
translation artefacts:

- **Names 10 (Al-Mutakabbir) and 41 (Al-Jalil) both read "The Majestic".**
  Two distinct Names, one English string. All five translations distinguish
  them, so English is now the odd one out.
- **Names 12 (Al-Bari') and 58 (Al-Mubdi') both read "The Originator".** Same
  problem.
- **Name 68 (As-Samad) reads "The Eternal".** The usual reading is "the
  Absolute" or "the Self-Sufficient"; "Eternal" also nearly collides with 96
  (Al-Baqi, "The Everlasting"). The five translations deliberately follow the
  Absolute/Self-Sufficient reading, so **they diverge from the English here on
  purpose** — that is not a mapping error.
- **Transliteration collisions:** 55 and 77 are both written `Al-Wali` though
  they are different words (وليّ / والي), and 48 and 65 are both `Al-Majid`
  (مَجِيد / مَاجِد). The meanings differ correctly; only the transliterations
  collide.

## Names flagged as uncertain

Roughly 37 of 99 were flagged. The ones most worth a reviewer's time:

### German — the least uniform tradition of the five
- **10 Al-Mutakabbir → "Der Stolze".** German 99-names lists do print this, but
  *stolz* carries a negative connotation in German that the Arabic does not.
  Alternatives: *Der Hoheitsvolle*, *Der Überlegene*, *Der Hocherhabene*.
  **Highest-priority item in the whole set.**
- **94 Al-Hadi → "Der Rechtleitende"**, deliberately *not* *Der Führer*, which
  is not usable in German. Knock-on: 98 Ar-Rashid became *Der
  Richtungweisende*, which is a coinage rather than an established form.
- **8 Al-Aziz → "Der Allmächtige"** rather than Rassoul's *Der Erhabene*, which
  was needed for the Al-'Ali / Al-Muta'ali pair. If a reviewer moves 8, then
  69 and 70 should move with it.
- **9 / 15 (Al-Jabbar, Al-Qahhar)** are both *Bezwinger* in German lists; the
  Al-/All- prefix separating them here is this translation's device, not an
  established distinction.
- **86 Al-Muqsit → "Der gerecht Handelnde"** is clumsy; *Der Gerechte* was
  already taken by 29.

### Italian
- **8 / 36 / 78 (Al-Aziz, Al-'Ali, Al-Muta'ali)** form the shakiest triangle in
  the set: *L'Eccelso* / *L'Altissimo* / *Il Supremo*.
- **94 and 98 use feminine nouns** (*La Guida*, *La Guida al Retto Sentiero*),
  breaking the *Il/L'* pattern of every other entry. Deliberate — *Il
  Guidatore* is not idiomatic — but it looks inconsistent in a list.

### Spanish
- **1 / 83 (Ar-Rahman, Ar-Ra'uf).** *El Compasivo* for Ar-Rahman follows
  Cortés/Melara, which forced Ar-Ra'uf off its natural word; it became *El
  Piadoso*. *El Benigno* is the alternative.
- **6 Al-Mu'min → "El Dador de Seguridad"** vs *El Fiel*; the English
  "Guardian of Faith" matches neither cleanly.

### French
- **26 As-Sami' → "L'Audient"** is Hamidullah's word but opaque to a general
  reader; *Celui qui entend tout* is clearer and longer.
- **5 As-Salam → "La Paix"** drops the "Source of" in the English.

### Portuguese
- **1 / 2** follow Samir El Hayek: Ar-Rahman is *O Clemente*, not
  *O Misericordioso*. Correct for that translation, but readers used to other
  lists may flinch.

## Where every tradition is thin

- **Forgiveness cluster (14 Al-Ghaffar, 34 Al-Ghafur, 82 Al-'Afuw):** no
  language has three settled distinct words. All five use an
  intensive/plain/pardon split carried by an intensifier rather than separate
  established terms. That reflects the real state of the traditions, but it is
  thin.
- **Counting pair (40 Al-Hasib, 57 Al-Muhsi):** distinguished as
  reckoning-to-account vs enumerating; no language has crisp single words for
  both.

## Layout note

**85 (Dhul-Jalali wal-Ikram)** is the longest entry in every language — 47
characters in French. It cannot be shortened faithfully and will wrap on a
card. Several French participle names use the established `Celui qui …`
construction and run long for the same reason.

## How to apply corrections

Each name's renderings sit together on its `AsmaEntry` in
`asma_ul_husna.dart`, so a correction is a one-line edit next to the Arabic it
translates — no cross-referencing by key. `'en'` is the fallback, so removing a
language's line shows English rather than an empty card.
