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
| 30 curated ayahs — excerpt + reflection | `curated_ayahs.dart` | en fr es it de pt | **No** |
| Hasanat promises, labels, conditions | `hasanat_promises.dart` | en fr es it de pt | **No** |
| 51 duas — titles + meanings | `../screens/duas_screen.dart` | en fr es it de pt | **No** |

## The most important caveat: provenance

Where this file says a translation "follows Hamidullah" or "follows
Bubenheim", that means **the assistant reproduced what it believed those
translators say, working from recall rather than from a copy of the text.**

The sense and register should be right. The exact wording may drift from the
printed edition in word order, particles and punctuation. **Before release,
every Quranic passage should be checked against an actual edition.** This
applies to:

- all 30 curated ayah excerpts
- the four Quran verses in `hasanat_promises.dart`

It does not apply to the Names, the reflections, or the hadith, which were
never claimed to come from a specific published text.

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

## Curated ayahs — specific items

### Deliberate departures from the published text
- **103:1** — Cortés reads *¡Por la tarde!* and Bubenheim *Bei der
  Nachmittagszeit!*, both taking *al-'asr* as the afternoon. The English
  excerpt says "By time", so Spanish and German follow the English with *¡Por
  el tiempo!* / *Bei der Zeit!*. An editorial call, not a recall error —
  reverse it if fidelity to the translator matters more than matching the card.
- **Allah, not God.** Cortés' *Alá*, García's *Dios* and El Hayek's *Deus*
  were all replaced with *Allah* to match the app's convention. Verified: no
  *Dieu*, *Dios* or *Deus* remains in any verse. German and Italian keep
  *Gott* / *dio* only where those render *ilāh* ("deity"), which mirrors what
  the English does with "no deity except Him" — that is correct, not a miss.

### Mixed translators within one language
- **3:173 German** uses Rassoul, not Bubenheim, whose *der Obhutgebende* for
  *al-wakīl* reads oddly on a card. Everything else German is Bubenheim.
- **94:5 Spanish** uses García; Cortés' rendering does not match the shape of
  the English excerpt at all.
- **29:45 Spanish** uses *la oración* rather than Cortés' *la azalá*.

### Least confident
**23:1 Italian** is the weakest item in the file. Also unsure: 23:1 Spanish,
94:5 Italian, 67:2 and 30:21 Portuguese.

### Reflections where the English idiom did not carry
- **40:60 "Allah is waiting for your du'a"** — rendered with *attend* /
  *espera* / *wartet auf*. A literal "waiting" is theologically awkward in
  some registers, implying need on Allah's part. Reads as warm invitation in
  English; may want softening.
- **25:63 "True strength is gentleness"** — English *gentleness* splits in the
  Romance languages between *douceur* (softness) and
  *mansedumbre*/*mitezza* (meekness). Not the same note; worth a native read.
- **55:13 "Count your blessings"** is an English idiom rendered literally
  everywhere; understandable but not idiomatic.

### Transliteration
*dhikr*, *du'a*, *tawakkul*, *istiqamah*, *Ayat al-Kursi* and *Jannah* are
kept untranslated, with each language applying its own scheme — Spanish
*Yannah* (matching its *Yumu'ah*), German *Schafi* (matching its *Ischa*).
Checked: none of these terms appear anywhere in the ARB files, so there is no
cross-file conflict. The one loose end is Italian, which writes *Jannah* here
but *Giumu'ah* in the ARB — the same Arabic letter two ways, though the two
never appear together.

## Duas — specific items

26 of the 51 are Quranic and follow a published rendering. **25 are hadith or
widely-reported supplications and are the assistant's own plain translation,
not a published one** — category 0 indices 19–23, and all of Daily Duas,
Special Occasions, and Success & Protection. Those 25 are where a
native-speaker pass matters most.

### Problems in the English source, found while translating

These affect English users now and should probably be fixed in the English
first, since the translations faithfully reproduce them:

- **1.7** — "from evil and the evil ones" flattens *al-khubuth wal-khabā'ith*,
  which means the male and female unclean jinn. The Roman Urdu field glosses
  it correctly; the English does not, so **the distinction is lost in all six
  languages**. Reword the English and the translations can follow.
- **0.10** — compresses four verses (20:25–28) into one sentence and drops
  *waj'al lī wazīran min ahlī*, so the citation range overstates what is
  actually quoted.
- **4.1** — a double-length explanatory rendering rather than a translation;
  the translations mirror its length, making it the longest body text here.
- **0.21** — the Arabic itself is truncated mid-supplication. The English
  matches the quoted part, so the two are consistent; it is the Arabic that
  is short.
- **1.8** — "my physical form" / "my character" for *khalqī* / *khuluqī* is
  accurate but loses the Arabic wordplay. No language preserves it.

### Deity vs Allah
**0.8** (Quran 21:87) and **3.2** (Day of Arafah) render *ilāh* as German
*Gott* / French *dieu* / Spanish *dios* / Italian *dio* — "deity" — while
*Allāh* stays "Allah". This matches what the English does with "no deity
except Him" and what the curated ayahs do. If the rule is meant to bar the
word outright, these become *Gottheit* / *divinité* / *divinidad* /
*divinità*.

### Smaller calls
- **0.16** (17:80) — *sultānan nasīra* follows Hamidullah's *autorité
  secourable*; *pouvoir secourable* is the alternative.
- **0.21** — *nāsiyatī* is literally the forelock; French keeps the literal
  *toupet* (standard in French hadith translations, odd-sounding), while the
  others use forehead/hair. Worth one decision across all five.
- **4.2** is marked *Athari — widely reported*, i.e. not a graded hadith. The
  attribution is what needs checking, not the wording.
- **Shaytan** is left transliterated (es *Shaytán*, de *Schaitan*). Normalise
  if the app has a house spelling.

### Titles that will strain a single-line header
French runs 15–25% longer than the English. The worst: **0.23** *Dua pour
redresser la religion et la vie d'ici-bas* (50 chars) and **0.16** *Dua pour
une entrée et une sortie véridiques* (45). Shorter forms exist — *Dua pour la
religion et la vie*, *Dua de l'entrée et de la sortie* — if the header does
not wrap.

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

---

# Tafsir (Al-Mukhtasar) — what the build script changes

`assets/tafsir/<lang>/<surah>.json` is Al-Mukhtasar fi Tafsir al-Qur'an
al-Karim (Tafsir Center for Quranic Studies), reproduced from the upstream
editions. Unlike the other religious content in this repo it is **not a
machine translation** — the wording is the Tafsir Center's own published text
in each of the four languages.

What `scripts/build_tafsir.py` does change, and so what a reviewer should
check, is limited to four passes. Re-running the script reproduces the assets
exactly, so any correction belongs in the script rather than in the JSON.

## 1. Encoding repair

- **Italian** arrived with mojibake in two names — `Ya'qǭùb` for Ya'qūb and
  `Is'ħāǭ` for Is'ħāq — and with Arabic glyphs glued onto the end of Latin
  words (`Torāhالت`, `Allāhالله`, `Al-Shāmالش`, ~22 places).
- **Spanish** carried zero-width spaces and non-breaking hyphens.

## 2. Honorific glyphs converted to text

The **Spanish** edition encodes honorifics as bare Latin letters from an
Arabic-honorifics font: a lone `u` after a prophet's name, a lone `r` after
Mujámmad / Profeta / Mensajero / Al-lah. In an ordinary font these render as
stray letters — *"albricias para José u."* About 700 occurrences, now
`(la paz sea con él)` and `ﷺ`.

**Check:** whether `r` after *Al-lah* (17 places) is really the Prophet's
honorific or something else. It is treated as ﷺ.

## 3. Prophet names normalised to their Arabic forms

English, French and Spanish used localised names; Italian already used Arabic
forms but in its own transliteration. All four now read Yusuf, Ya'qub, Musa,
Ibrahim, Nuh, Isa, Maryam, Sulayman, Dawud, Harun, Lut, Isma'il, Ishaq, Yunus,
Zakariya, Yahya, Ayyub, Idris, Hud, Salih, Shu'ayb, Ilyas, Alyasa, Dhul-Kifl.

Name spellings were extracted from the corpus, not assumed — the Italian
edition uses `Muħammed` 237 times and `Muħammad` never.

**Checks:**
- *Pharaoh*, *Satan* and *Iblis* are deliberately left in each language's own
  form; *Talut* (Saul) and *Jalut* (Goliath) are mapped but take no honorific.
- English 21:85 lists "Ishmael, Enoch and Ezekiel"; the third is read as
  **Dhul-Kifl**, which is the usual identification but not the only one.
- *Eve* → **Hawwa**, and the angels *Gabriel* → **Jibril**, *Michael* →
  **Mika'il**. Mapping angel names was a judgement call.
- Italian keeps `Allāh`, `Torāh`, `Islām`, `Isrāīl` with macrons, so it is
  internally consistent but differs from the other three editions.

## 4. Honorifics added where the source supplies none

French and Spanish had effectively no honorifics in running text; English had
about 500 and Italian about 200. The script adds one **per name per verse**,
never where the source already honours that name anywhere in the same verse.
Per occurrence would be unreadable: *Moses* alone appears 371 times.

A verse naming **three or more** prophets takes a single collective honorific
after the last name — the convention the English edition itself uses at 6:84.
The Prophet Muhammad takes ﷺ; Maryam takes the feminine form.

**Checks:**
- Whether a spelled-out *(peace be upon him)* is preferred over *(PBUH)* or
  ﷺ for prophets other than Muhammad. `HONORIFIC` in the script is the one
  place to change it.
- Spanish still honours each name individually in list verses such as 6:84,
  because its own glyphs did; the other three use the collective form there.
- Whether the three-or-more threshold is right.

## Not covered

German and Portuguese have **no tafsir in any of the 123 upstream editions**,
not merely no Al-Mukhtasar. Those locales fall back to English.

---

# Roman Urdu tafsir — status and what to review

`assets/tafsir/ur-roman/` is a **machine translation of the English
Al-Mukhtasar**, not a published work. Unlike the four bundled editions, no
scholar has reviewed a word of it. It is labelled in the app, and a verse with
no entry falls back to English per verse rather than per language.

**Coverage: 682 of 6236 verses (10.9%)** — Al-Fatihah, Surah Yusuf, and all of
Juz 30 (surahs 78–114). Everything else shows English.

## How it was produced

Three independent audits drove three rewrites. Their trajectory, because it
says where the remaining risk is:

| | word choice | sentence construction |
|---|---|---|
| audit 1 (30 short-surah verses) | ~85% | ~60% |
| audit 2 (surah 12, first pass) | ~90% | ~65% |
| audit 3 (surah 12, rewritten) | ~93% | ~79% |

Construction was the hard part. Each audit found the previous fix had moved
the fault rather than removed it: English clause order became English
sentence boundaries, which became em-dashes, which became referent collapse
under the honorific plural.

## The four rules the text follows

1. **No em-dash.** Every English appositive becomes `yani X`, a `jo … hai`
   relative, or a repeated noun. The reference translation uses no em-dash in
   6236 verses and neither does the English source, so a dash is invented
   punctuation and the clearest signature of machine origin.
2. **Two parties, two names.** Where two referents would both surface as
   `un` / `unhon ne` / `unhein`, one is named outright.
3. **Split only at coordinators.** An English `When X, Y` or `Just as X, Y`
   stays one Urdu sentence (`Jab … to …`, `Jis tarah … usi tarah …`).
4. **The quote ends where the speaker stops.** Closing theological formulas
   belong inside it, in the speaker's person (`mera Rubb`, not `un ka Rubb`).
   Nothing the English marks as thought becomes addressed speech.

Plus the address rule: the Prophet takes the respectful `aap`, Allah takes
`tu` in du'a, people in general take `tum`, and characters in a narrative take
whatever suits their relationship.

## What a reviewer should check first

- **Doctrinal wording.** Four errors of this kind were caught and fixed; there
  may be more. The pattern was rendering a divine attribute word-for-word:
  `akela` (lonely) for al-Ahad, where the right word is `yakta`.
- **Whether `aap` for the Prophet is right.** It diverges deliberately from
  the reference, which uses `tum` for him in 186 verses and never `aap`. The
  reasoning is that tafsir is editorial voice rather than scripture; it is
  written down so nobody "corrects" it back.
- **Honorific density.** 59 `(alaihis salaam)` in surah 12 against the
  reference's zero in that surah. Narration only, never inside a quotation —
  though a prophet honouring prophets inside his own speech was kept.
- **12:52–53 and 12:110** diverge from the reference's reading of those
  verses, following the English source instead. Both are deliberate.

## Checking it mechanically

`python3 scripts/check_ur_roman.py [--surah N] [--verbose]` covers glossary
spellings, English left untranslated, length ratios against the source,
familiar-vs-respectful forms for the Prophet, seven grammar forms, reported
imperatives, em-dashes, ergative omission and over-long sentences. It reports
clean on all 682 verses.

It cannot see everything: two typos in this corpus were found by eye, not by
it (`Tumhara tumhara deen hai`, and a doubled `ki`). `scripts/ur_roman_glossary.json`
is the vocabulary and style contract it enforces.
