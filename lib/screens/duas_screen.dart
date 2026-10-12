import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

// ═══════════════════════════════════════════════════════════════
// DATA — 51 authentic duas across 5 categories
// Each dua map keys: title, arabic, transliteration, english,
//   romanUrdu, source, [prophet] (category 1 only)
//
// `title` and `english`, and each category's `name`, hold a
// {languageCode: text} map rather than a plain string. Everything else —
// the Arabic, the transliteration, the Roman Urdu, the source citation — is
// the same in every locale and stays a string.
// ═══════════════════════════════════════════════════════════════

/// Reads a possibly-localised field out of an untyped dua or category map.
///
/// This data is a `const List<Map<String, dynamic>>`, so there is no class to
/// hang an accessor on the way the Names and the curated ayahs have one.
///
/// Accepts both shapes on purpose: a translated field holds a
/// `{languageCode: text}` map, an untranslated one still holds a plain
/// String. That lets a field be localised without touching every call site
/// in the same change, and means a half-finished pass degrades to English
/// rather than throwing.
String duaField(Map<String, dynamic> entry, String key, String languageCode) {
  final value = entry[key];
  if (value is Map) {
    return (value[languageCode] ?? value['en'] ?? '') as String;
  }
  return (value as String?) ?? '';
}

const List<Map<String, dynamic>> duasCategories = [
  // ── 1. Duas of the Prophets (24 duas) ──────────────────────
  {
    'id': 'prophets',
    'name': {
            'en': 'Duas of the Prophets',
            'fr': 'Duas des prophètes',
            'es': 'Duas de los profetas',
            'it': 'Dua dei profeti',
            'de': 'Duas der Propheten',
            'pt': 'Duas dos profetas',
          },
    'emoji': '🕌',
    'watermark': 'الأنبياء',
    'hasProphetSections': true,
    'duas': [
      // Adam
      {
        'prophet': 'Prophet Adam (عليه السلام)',
        'title': {
            'en': 'Dua of Repentance',
            'fr': 'Dua du repentir',
            'es': 'Dua del arrepentimiento',
            'it': 'Dua del pentimento',
            'de': 'Dua der Reue',
            'pt': 'Dua do arrependimento',
          },
        'arabic':
            'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
        'transliteration':
            'Rabbana zalamna anfusana wa illam taghfir lana wa tarhamna lanakunanna minal khasireen',
        'english': {
            'en': 'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
            'fr': 'Notre Seigneur, nous avons fait du tort à nous-mêmes. Et si Tu ne nous pardonnes pas et ne nous fais pas miséricorde, nous serons très certainement du nombre des perdants.',
            'es': 'Señor nuestro, hemos sido injustos con nosotros mismos; y si no nos perdonas y no Te apiadas de nosotros, seremos ciertamente de los perdedores.',
            'it': 'Signore nostro, abbiamo mancato contro noi stessi; se non ci perdoni e non hai misericordia di noi, saremo certamente tra i perdenti.',
            'de': 'Unser Herr, wir haben uns selbst Unrecht zugefügt. Wenn Du uns nicht vergibst und Dich unser nicht erbarmst, werden wir ganz gewiss zu den Verlierern gehören.',
            'pt': 'Senhor nosso, fomos injustos com nós mesmos e, se não nos perdoares e não Te compadeceres de nós, seremos certamente dos perdedores.',
          },
        'romanUrdu':
            'Ae hamare Rabb, hum ne apne aap par zulm kiya aur agar Tu ne hamen maaf na kiya aur hum par raham na kiya to hum yaqeenan nuqsaan uthaane walon mein se honge.',
        'source': 'Quran 7:23',
      },
      // Nuh
      {
        'prophet': 'Prophet Nuh (عليه السلام)',
        'title': {
            'en': 'Dua for Help Against Disbelievers',
            'fr': 'Dua pour le secours contre les mécréants',
            'es': 'Dua por auxilio contra los incrédulos',
            'it': 'Dua per il soccorso contro i miscredenti',
            'de': 'Dua um Hilfe gegen die Ungläubigen',
            'pt': 'Dua por socorro contra os incrédulos',
          },
        'arabic': 'رَبِّ إِنِّي مَغْلُوبٌ فَانتَصِرْ',
        'transliteration': 'Rabbi inni maghlubun fantasir',
        'english': {
            'en': 'My Lord, I am overpowered, so help me.',
            'fr': 'Seigneur, je suis vaincu, accorde-moi Ton secours.',
            'es': 'Señor mío, estoy vencido, ¡auxíliame!',
            'it': 'Signore, sono sopraffatto: dammi il Tuo soccorso!',
            'de': 'Mein Herr, ich bin unterlegen, so hilf mir.',
            'pt': 'Senhor meu, estou vencido; socorre-me!',
          },
        'romanUrdu':
            'Ae mere Rabb, main maghlub ho gaya hoon, pas Tu meri madad farma.',
        'source': 'Quran 54:10',
      },
      {
        'prophet': 'Prophet Nuh (عليه السلام)',
        'title': {
            'en': 'Dua for Forgiveness',
            'fr': 'Dua pour le pardon',
            'es': 'Dua por el perdón',
            'it': 'Dua per il perdono',
            'de': 'Dua um Vergebung',
            'pt': 'Dua pelo perdão',
          },
        'arabic':
            'رَّبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَن دَخَلَ بَيْتِيَ مُؤْمِنًا وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ',
        'transliteration':
            "Rabbigh-fir li wa liwaalidayya wa liman dakhala baytiya mu'minan wa lil-mu'mineena wal-mu'minaat",
        'english': {
            'en': 'My Lord, forgive me and my parents and whoever enters my house as a believer and the believing men and believing women.',
            'fr': "Seigneur, pardonne-moi, ainsi qu'à mes père et mère et à celui qui entre dans ma demeure comme croyant, ainsi qu'aux croyants et aux croyantes.",
            'es': 'Señor mío, perdóname a mí, a mis padres, a quien entre en mi casa como creyente, y a los creyentes y las creyentes.',
            'it': 'Signore, perdona a me, ai miei genitori, a chi entra nella mia casa come credente, ai credenti e alle credenti.',
            'de': 'Mein Herr, vergib mir und meinen Eltern und jedem, der mein Haus als Gläubiger betritt, und den gläubigen Männern und den gläubigen Frauen.',
            'pt': 'Senhor meu, perdoa-me, e a meus pais, e a quem entrar em minha casa como crente, e aos crentes e às crentes.',
          },
        'romanUrdu':
            'Ae mere Rabb, mujhe aur mere walidain ko aur jo bhi mere ghar mein imaan ke saath daakhil ho aur tamaam momin mardon aur momin aurton ko maaf farma.',
        'source': 'Quran 71:28',
      },
      // Ibrahim
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': {
            'en': 'Dua for a Righteous Child',
            'fr': 'Dua pour un enfant vertueux',
            'es': 'Dua por un hijo justo',
            'it': 'Dua per un figlio devoto',
            'de': 'Dua um ein rechtschaffenes Kind',
            'pt': 'Dua por um filho virtuoso',
          },
        'arabic': 'رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ',
        'transliteration': 'Rabbi hab li minas-saliheen',
        'english': {
            'en': 'My Lord, grant me a child from among the righteous.',
            'fr': "Seigneur, fais-moi don d'une descendance d'entre les vertueux.",
            'es': 'Señor mío, concédeme un hijo de entre los justos.',
            'it': 'Signore, donami un figlio tra i devoti.',
            'de': 'Mein Herr, schenke mir einen von den Rechtschaffenen.',
            'pt': 'Senhor meu, concede-me um filho dentre os virtuosos.',
          },
        'romanUrdu':
            'Ae mere Rabb, mujhe naik logon mein se (aulaad) ata farma.',
        'source': 'Quran 37:100',
      },
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': {
            'en': 'Dua for Acceptance of Worship',
            'fr': "Dua pour l'acceptation du culte",
            'es': 'Dua por la aceptación del culto',
            'it': "Dua per l'accettazione del culto",
            'de': 'Dua um Annahme der Anbetung',
            'pt': 'Dua pela aceitação do culto',
          },
        'arabic':
            'رَبَّنَا تَقَبَّلْ مِنَّا ۖ إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ',
        'transliteration':
            'Rabbana taqabbal minna innaka antas-samee ul-aleem',
        'english': {
            'en': 'Our Lord, accept from us. Indeed You are the Hearing, the Knowing.',
            'fr': "Notre Seigneur, accepte cela de notre part. Certes, c'est Toi l'Audient, l'Omniscient.",
            'es': 'Señor nuestro, acéptalo de nosotros. Tú eres, ciertamente, Quien todo lo oye, Quien todo lo sabe.',
            'it': "Signore nostro, accettalo da noi. In verità Tu sei l'Audiente, il Sapiente.",
            'de': 'Unser Herr, nimm es von uns an. Du bist ja der Allhörende und Allwissende.',
            'pt': 'Senhor nosso, aceita-o de nós. Tu és, em verdade, o Oniouvinte, o Onisciente.',
          },
        'romanUrdu':
            'Ae hamare Rabb, hum se qabool farma. Beshak Tu hi sunne wala aur jaanne wala hai.',
        'source': 'Quran 2:127',
      },
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': {
            'en': 'Dua for a City of Peace',
            'fr': 'Dua pour une cité de paix',
            'es': 'Dua por una ciudad de paz',
            'it': 'Dua per una città di pace',
            'de': 'Dua für eine Stadt des Friedens',
            'pt': 'Dua por uma cidade de paz',
          },
        'arabic':
            'رَبِّ اجْعَلْ هَٰذَا بَلَدًا آمِنًا وَارْزُقْ أَهْلَهُ مِنَ الثَّمَرَاتِ',
        'transliteration':
            'Rabbij-al hadha baladan aminan war-zuq ahlahu minat-thamarat',
        'english': {
            'en': 'My Lord, make this a secure city and provide its people with fruits.',
            'fr': 'Seigneur, fais de cette cité un lieu de sécurité et nourris de fruits ses habitants.',
            'es': 'Señor mío, haz de esta una ciudad segura y provee de frutos a sus habitantes.',
            'it': 'Signore, fai di questa una città sicura e provvedi di frutti la sua gente.',
            'de': 'Mein Herr, mache dies zu einer sicheren Stadt und versorge ihre Bewohner mit Früchten.',
            'pt': 'Senhor meu, faz desta uma cidade segura e provê de frutos os seus habitantes.',
          },
        'romanUrdu':
            'Ae mere Rabb, is shahar ko amn wala bana aur iske bashindon ko phalon ka rizq de.',
        'source': 'Quran 2:126',
      },
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': {
            'en': 'Dua for Steadfastness in Prayer',
            'fr': "Dua pour l'assiduité dans la prière",
            'es': 'Dua por la constancia en la oración',
            'it': 'Dua per la costanza nella preghiera',
            'de': 'Dua um Beständigkeit im Gebet',
            'pt': 'Dua pela constância na oração',
          },
        'arabic':
            'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي ۚ رَبَّنَا وَتَقَبَّلْ دُعَاءِ',
        'transliteration':
            "Rabbij-alni muqimas-salati wa min dhurriyyati rabbana wa taqabbal du'a",
        'english': {
            'en': 'My Lord, make me an establisher of prayer, and from my descendants. Our Lord, and accept my supplication.',
            'fr': "Seigneur, fais de moi quelqu'un qui accomplit assidûment la prière, ainsi qu'une partie de ma descendance. Notre Seigneur, exauce ma prière.",
            'es': 'Señor mío, hazme de los que cumplen la oración, y también a mi descendencia. Señor nuestro, acepta mi súplica.',
            'it': "Signore, fai di me uno che assolve all'orazione, e anche della mia discendenza. Signore nostro, accogli la mia supplica.",
            'de': 'Mein Herr, mache mich zu einem, der das Gebet verrichtet, und auch einige von meinen Nachkommen. Unser Herr, und nimm mein Bittgebet an.',
            'pt': 'Senhor meu, faz de mim e de minha descendência observantes da oração. Senhor nosso, aceita a minha súplica.',
          },
        'romanUrdu':
            'Ae mere Rabb, mujhe namaaz qaim karne wala bana aur meri aulaad ko bhi. Ae hamare Rabb, aur meri dua qabool farma.',
        'source': 'Quran 14:40',
      },
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': {
            'en': 'Dua for Forgiveness on Judgement Day',
            'fr': 'Dua pour le pardon au Jour du Jugement',
            'es': 'Dua por el perdón en el Día del Juicio',
            'it': 'Dua per il perdono nel Giorno del Giudizio',
            'de': 'Dua um Vergebung am Tag des Gerichts',
            'pt': 'Dua pelo perdão no Dia do Juízo',
          },
        'arabic':
            'رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
        'transliteration':
            "Rabbanaghfir li wa liwaalidayya wa lil-mu'mineena yawma yaqumul hisab",
        'english': {
            'en': 'Our Lord, forgive me and my parents and the believers the Day the account is established.',
            'fr': "Notre Seigneur, pardonne-moi, ainsi qu'à mes père et mère et aux croyants, le jour où aura lieu le Jugement.",
            'es': 'Señor nuestro, perdóname a mí, a mis padres y a los creyentes el Día en que se establezca la Cuenta.',
            'it': 'Signore nostro, perdona a me, ai miei genitori e ai credenti nel Giorno in cui si farà il Rendiconto.',
            'de': 'Unser Herr, vergib mir und meinen Eltern und den Gläubigen an dem Tag, da die Abrechnung stattfindet.',
            'pt': 'Senhor nosso, perdoa-me, e a meus pais, e aos crentes, no Dia da Prestação de Contas.',
          },
        'romanUrdu':
            'Ae hamare Rabb, mujhe aur mere walidain ko aur tamam mominon ko us din maaf farma jis din hisaab qaim hoga.',
        'source': 'Quran 14:41',
      },
      // Yunus
      {
        'prophet': 'Prophet Yunus (عليه السلام)',
        'title': {
            'en': 'Dua from the Darkness',
            'fr': 'Dua depuis les ténèbres',
            'es': 'Dua desde la oscuridad',
            'it': 'Dua dalle tenebre',
            'de': 'Dua aus der Finsternis',
            'pt': 'Dua das trevas',
          },
        'arabic':
            'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
        'transliteration':
            'La ilaha illa anta subhanaka inni kuntu minaz-zalimeen',
        'english': {
            'en': 'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
            'fr': "Il n'y a de divinité que Toi ! Pureté à Toi ! J'ai été vraiment du nombre des injustes.",
            'es': 'No hay más divinidad que Tú. ¡Glorificado seas! Ciertamente he sido de los injustos.',
            'it': "Non c'è altra divinità che Te! Gloria a Te! In verità sono stato tra gli ingiusti.",
            'de': 'Es gibt keinen Gott außer Dir. Preis sei Dir! Gewiss, ich gehörte zu den Ungerechten.',
            'pt': 'Não há divindade além de Ti! Glorificado sejas! Em verdade, fui um dos iníquos.',
          },
        'romanUrdu':
            'Tere siwa koi ilaah nahi, Tu paak hai, beshak main zalimoon mein se tha.',
        'source': 'Quran 21:87',
      },
      // Musa
      {
        'prophet': 'Prophet Musa (عليه السلام)',
        'title': {
            'en': 'Dua for Forgiveness',
            'fr': 'Dua pour le pardon',
            'es': 'Dua por el perdón',
            'it': 'Dua per il perdono',
            'de': 'Dua um Vergebung',
            'pt': 'Dua pelo perdão',
          },
        'arabic': 'رَبِّ إِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي',
        'transliteration': 'Rabbi inni zalamtu nafsi faghfir li',
        'english': {
            'en': 'My Lord, indeed I have wronged myself, so forgive me.',
            'fr': 'Seigneur, je me suis fait du tort à moi-même ; pardonne-moi.',
            'es': 'Señor mío, ciertamente he sido injusto conmigo mismo; perdóname.',
            'it': 'Signore, ho fatto torto a me stesso: perdonami.',
            'de': 'Mein Herr, ich habe mir selbst Unrecht zugefügt; so vergib mir.',
            'pt': 'Senhor meu, em verdade fui injusto comigo mesmo; perdoa-me.',
          },
        'romanUrdu':
            'Ae mere Rabb, beshak maine apne aap par zulm kiya, pas mujhe maaf farma de.',
        'source': 'Quran 28:16',
      },
      {
        'prophet': 'Prophet Musa (عليه السلام)',
        'title': {
            'en': 'Dua for Ease in Affairs',
            'fr': 'Dua pour la facilité dans les affaires',
            'es': 'Dua por la facilidad en los asuntos',
            'it': 'Dua per la facilità negli affari',
            'de': 'Dua um Erleichterung in Angelegenheiten',
            'pt': 'Dua pela facilidade nos assuntos',
          },
        'arabic':
            'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي يَفْقَهُوا قَوْلِي',
        'transliteration':
            'Rabbish-rah li sadri wa yassir li amri wahlul uqdatan min lisani yafqahu qawli',
        'english': {
            'en': 'My Lord, expand my breast, ease my task, and remove the impediment from my speech so they may understand what I say.',
            'fr': "Seigneur, dilate ma poitrine, facilite ma mission et délie ma langue, afin qu'ils comprennent mes paroles.",
            'es': 'Señor mío, infúndeme ánimo, facilita mi misión y desata el nudo de mi lengua, para que comprendan mis palabras.',
            'it': 'Signore, allarga il mio petto, facilita la mia missione e sciogli il nodo della mia lingua, affinché comprendano le mie parole.',
            'de': 'Mein Herr, weite mir meine Brust, erleichtere mir meine Aufgabe und löse den Knoten in meiner Zunge, damit sie meine Worte verstehen.',
            'pt': 'Senhor meu, dilata-me o peito, facilita-me a missão e desata o nó da minha língua, para que compreendam as minhas palavras.',
          },
        'romanUrdu':
            'Ae mere Rabb, mera seena khol de, mera kaam aasaan kar de aur meri zaban ki gaanh khol de taake log meri baat samjhein.',
        'source': 'Quran 20:25-28',
      },
      {
        'prophet': 'Prophet Musa (عليه السلام)',
        'title': {
            'en': 'Dua for Good Provision',
            'fr': 'Dua pour une bonne subsistance',
            'es': 'Dua por un buen sustento',
            'it': 'Dua per un buon sostentamento',
            'de': 'Dua um gute Versorgung',
            'pt': 'Dua por um bom sustento',
          },
        'arabic': 'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
        'transliteration': 'Rabbi inni lima anzalta ilayya min khayrin faqeer',
        'english': {
            'en': 'My Lord, indeed I am in need of whatever good You would send down to me.',
            'fr': 'Seigneur, je suis vraiment dans le besoin de tout bien que Tu fasses descendre vers moi.',
            'es': 'Señor mío, ciertamente estoy necesitado de cualquier bien que hagas descender sobre mí.',
            'it': 'Signore, ho davvero bisogno di qualunque bene Tu voglia far scendere su di me.',
            'de': 'Mein Herr, ich bin bedürftig all des Guten, das Du auf mich herabsendest.',
            'pt': 'Senhor meu, em verdade estou necessitado de todo bem que faças descer sobre mim.',
          },
        'romanUrdu':
            'Ae mere Rabb, beshak main us bhalai ka muhtaaj hoon jo Tu mere liye nazil farmaaye.',
        'source': 'Quran 28:24',
      },
      // Ayyub
      {
        'prophet': 'Prophet Ayyub (عليه السلام)',
        'title': {
            'en': 'Dua in Times of Hardship',
            'fr': "Dua dans l'épreuve",
            'es': 'Dua en la adversidad',
            'it': 'Dua nelle avversità',
            'de': 'Dua in Zeiten der Not',
            'pt': 'Dua na adversidade',
          },
        'arabic':
            'أَنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ',
        'transliteration': 'Anni massaniyad-durru wa anta arhamur-rahimeen',
        'english': {
            'en': 'Indeed, adversity has touched me, and You are the Most Merciful of the merciful.',
            'fr': "Le mal m'a touché, et Toi, Tu es le plus Miséricordieux des miséricordieux.",
            'es': 'La adversidad me ha alcanzado, y Tú eres el más Misericordioso de los misericordiosos.',
            'it': "In verità l'avversità mi ha colpito, e Tu sei il più Misericordioso dei misericordiosi.",
            'de': 'Mich hat das Unheil getroffen, und Du bist der Barmherzigste der Barmherzigen.',
            'pt': 'Em verdade a adversidade me açoita, e Tu és o mais Misericordioso dos misericordiosos.',
          },
        'romanUrdu':
            'Beshak mujhe takleef pahunchi hai aur Tu sab rahm karne walon se zyada rahm karne wala hai.',
        'source': 'Quran 21:83',
      },
      // Zakariyya
      {
        'prophet': 'Prophet Zakariyya (عليه السلام)',
        'title': {
            'en': 'Dua for a Righteous Heir',
            'fr': 'Dua pour un héritier vertueux',
            'es': 'Dua por un heredero justo',
            'it': 'Dua per un erede devoto',
            'de': 'Dua um einen rechtschaffenen Erben',
            'pt': 'Dua por um herdeiro virtuoso',
          },
        'arabic':
            'رَبِّ لَا تَذَرْنِي فَرْدًا وَأَنتَ خَيْرُ الْوَارِثِينَ',
        'transliteration': 'Rabbi la tadharni fardan wa anta khayrul warithin',
        'english': {
            'en': 'My Lord, do not leave me alone without an heir, and You are the best of inheritors.',
            'fr': 'Seigneur, ne me laisse pas seul sans héritier, et Tu es le meilleur des héritiers.',
            'es': 'Señor mío, no me dejes solo sin heredero, y Tú eres el mejor de los herederos.',
            'it': 'Signore, non lasciarmi solo senza eredi, e Tu sei il migliore degli eredi.',
            'de': 'Mein Herr, lasse mich nicht allein ohne Erben, und Du bist der beste Erbe.',
            'pt': 'Senhor meu, não me deixes só, sem herdeiro, e Tu és o melhor dos herdeiros.',
          },
        'romanUrdu':
            'Ae mere Rabb, mujhe akela mat chhod aur Tu sab se behtar waris hai.',
        'source': 'Quran 21:89',
      },
      {
        'prophet': 'Prophet Zakariyya (عليه السلام)',
        'title': {
            'en': 'Dua for a Pure Offspring',
            'fr': 'Dua pour une descendance pure',
            'es': 'Dua por una descendencia pura',
            'it': 'Dua per una discendenza pura',
            'de': 'Dua um reine Nachkommenschaft',
            'pt': 'Dua por uma descendência pura',
          },
        'arabic':
            'رَبِّ هَبْ لِي مِن لَّدُنكَ ذُرِّيَّةً طَيِّبَةً ۖ إِنَّكَ سَمِيعُ الدُّعَاءِ',
        'transliteration':
            "Rabbi hab li milladunka dhurriyyatan tayyibah innaka samee'ud-du'a",
        'english': {
            'en': 'My Lord, grant me from Yourself a good offspring. Indeed, You are the Hearer of supplication.',
            'fr': 'Seigneur, donne-moi, venant de Toi, une descendance pure. Certes, Tu entends bien les prières.',
            'es': 'Señor mío, concédeme de Tu parte una descendencia pura. Ciertamente, Tú eres Quien escucha la súplica.',
            'it': "Signore, concedimi da parte Tua una buona discendenza. In verità Tu sei Colui che ascolta l'invocazione.",
            'de': 'Mein Herr, schenke mir von Dir aus gute Nachkommenschaft. Du bist ja der Erhörer des Bittgebets.',
            'pt': 'Senhor meu, concede-me, de Tua parte, uma descendência pura. Em verdade, Tu és o Ouvinte da súplica.',
          },
        'romanUrdu':
            'Ae mere Rabb, apni taraf se mujhe paak aulaad ata farma. Beshak Tu dua sunne wala hai.',
        'source': 'Quran 3:38',
      },
      // Sulayman
      {
        'prophet': 'Prophet Sulayman (عليه السلام)',
        'title': {
            'en': 'Dua of Gratitude',
            'fr': 'Dua de gratitude',
            'es': 'Dua de gratitud',
            'it': 'Dua di gratitudine',
            'de': 'Dua der Dankbarkeit',
            'pt': 'Dua de gratidão',
          },
        'arabic':
            'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَىٰ وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ',
        'transliteration':
            "Rabbi awzi'ni an ashkura ni'matakal-lati an'amta 'alayya wa 'ala walidayya wa an a'mala salihan tardah",
        'english': {
            'en': 'My Lord, enable me to be grateful for Your favour which You have bestowed upon me and upon my parents, and to do righteousness of which You approve.',
            'fr': "Seigneur, permets-moi de rendre grâce pour le bienfait dont Tu m'as comblé, ainsi que mes père et mère, et de faire une bonne œuvre que Tu agrées.",
            'es': 'Señor mío, permíteme ser agradecido por el favor que me has concedido a mí y a mis padres, y obrar rectamente, de modo que Te complazcas.',
            'it': 'Signore, concedimi di esserti grato per il favore che hai concesso a me e ai miei genitori, e di compiere il bene di cui Ti compiaci.',
            'de': 'Mein Herr, veranlasse mich, für Deine Gunst zu danken, die Du mir und meinen Eltern erwiesen hast, und rechtschaffen zu handeln, womit Du zufrieden bist.',
            'pt': 'Senhor meu, inspira-me a agradecer a graça que me concedeste, a mim e a meus pais, e a praticar o bem que Te agrade.',
          },
        'romanUrdu':
            "Ae mere Rabb, mujhe toufeeq de ke main teri us ne'mat ka shukar ada karun jo tu ne mujhe aur mere walidain ko di aur nek amal karun jo tujhe pasand ho.",
        'source': 'Quran 27:19',
      },
      {
        'prophet': 'Prophet Sulayman (عليه السلام)',
        'title': {
            'en': 'Dua for Truthful Entry and Exit',
            'fr': 'Dua pour une entrée et une sortie véridiques',
            'es': 'Dua por una entrada y una salida veraces',
            'it': "Dua per un ingresso e un'uscita veraci",
            'de': 'Dua um wahrhaftigen Eingang und Ausgang',
            'pt': 'Dua por uma entrada e uma saída veraz',
          },
        'arabic':
            'رَبِّ أَدْخِلْنِي مُدْخَلَ صِدْقٍ وَأَخْرِجْنِي مُخْرَجَ صِدْقٍ وَاجْعَل لِّي مِن لَّدُنكَ سُلْطَانًا نَّصِيرًا',
        'transliteration':
            "Rabbi adkhilni mudkhala sidqin wa akhrijnee mukhraja sidqin waj'al li milladunka sultanan nasira",
        'english': {
            'en': 'My Lord, cause me to enter an entry of truth and to exit an exit of truth and grant me from You a supporting authority.',
            'fr': "Seigneur, fais que j'entre par une entrée de vérité et que je sorte par une sortie de vérité, et accorde-moi de Ta part une autorité secourable.",
            'es': 'Señor mío, hazme entrar con una entrada veraz y hazme salir con una salida veraz, y concédeme de Tu parte una autoridad que me auxilie.',
            'it': "Signore, fammi entrare con un ingresso di verità e fammi uscire con un'uscita di verità, e concedimi da parte Tua un'autorità che mi soccorra.",
            'de': 'Mein Herr, gewähre mir einen wahrhaftigen Eingang und gewähre mir einen wahrhaftigen Ausgang, und schenke mir von Dir aus eine hilfreiche Macht.',
            'pt': 'Senhor meu, faze-me entrar com uma entrada veraz e faze-me sair com uma saída veraz, e concede-me, de Tua parte, uma autoridade que me socorra.',
          },
        'romanUrdu':
            'Ae mere Rabb, mujhe sachche daakhle se daakhil kar aur sachche khurooj se baahir kar aur apni taraf se mujhe madad karne wali quwwat ata farma.',
        'source': 'Quran 17:80',
      },
      // Isa
      {
        'prophet': 'Prophet Isa (عليه السلام)',
        'title': {
            'en': 'Dua for a Table Spread from Heaven',
            'fr': 'Dua pour une table servie du ciel',
            'es': 'Dua por una mesa servida del cielo',
            'it': 'Dua per una mensa dal cielo',
            'de': 'Dua um einen Tisch vom Himmel',
            'pt': 'Dua por uma mesa servida do céu',
          },
        'arabic':
            'اللَّهُمَّ رَبَّنَا أَنزِلْ عَلَيْنَا مَائِدَةً مِّنَ السَّمَاءِ تَكُونُ لَنَا عِيدًا',
        'transliteration':
            "Allahumma Rabbana anzil 'alayna ma'idatam minas-sama'i takunu lana 'eeda",
        'english': {
            'en': 'O Allah, our Lord, send down to us a table from the sky that will be for us a festival.',
            'fr': 'Ô Allah, notre Seigneur, fais descendre du ciel sur nous une table servie qui soit une fête pour nous.',
            'es': '¡Oh Allah, Señor nuestro! Haz descender sobre nosotros, del cielo, una mesa servida que sea para nosotros una fiesta.',
            'it': 'O Allah, Signore nostro, fai scendere su di noi, dal cielo, una mensa che sia per noi una festa.',
            'de': 'O Allah, unser Herr, sende uns vom Himmel einen Tisch mit Speisen herab, der für uns ein Fest sei.',
            'pt': 'Ó Allah, Senhor nosso, faz descer sobre nós, do céu, uma mesa servida que seja para nós uma festa.',
          },
        'romanUrdu':
            'Ae Allah, hamare Rabb, hamare liye aasmaan se ek dastarkhwaan nazil farma jo hamare liye eid ho.',
        'source': 'Quran 5:114',
      },
      // Lut
      {
        'prophet': 'Prophet Lut (عليه السلام)',
        'title': {
            'en': 'Dua for Victory Over Wrongdoers',
            'fr': 'Dua pour la victoire sur les corrupteurs',
            'es': 'Dua por la victoria sobre los corruptores',
            'it': 'Dua per la vittoria sui corruttori',
            'de': 'Dua um Sieg über die Unheilstifter',
            'pt': 'Dua pela vitória sobre os corruptores',
          },
        'arabic': 'رَبِّ انصُرْنِي عَلَى الْقَوْمِ الْمُفْسِدِينَ',
        'transliteration': 'Rabbinsurni alal-qawmil mufsideen',
        'english': {
            'en': 'My Lord, support me against the corrupting people.',
            'fr': 'Seigneur, fais-moi triompher contre ce peuple de corrupteurs.',
            'es': 'Señor mío, auxíliame contra el pueblo corruptor.',
            'it': 'Signore, dammi il Tuo soccorso contro questo popolo corrotto.',
            'de': 'Mein Herr, hilf mir gegen das Volk, das Unheil stiftet.',
            'pt': 'Senhor meu, socorre-me contra o povo corruptor.',
          },
        'romanUrdu':
            'Ae mere Rabb, fasaad phailane wali qaum ke khilaf meri madad farma.',
        'source': 'Quran 29:30',
      },
      // Muhammad ﷺ
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': {
            'en': 'Dua for Steadfastness of the Heart',
            'fr': 'Dua pour la fermeté du cœur',
            'es': 'Dua por la firmeza del corazón',
            'it': 'Dua per la fermezza del cuore',
            'de': 'Dua um Festigkeit des Herzens',
            'pt': 'Dua pela firmeza do coração',
          },
        'arabic':
            'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
        'transliteration': 'Ya muqallibal-qulubi thabbit qalbi ala dinik',
        'english': {
            'en': 'O Turner of hearts, make my heart firm upon Your religion.',
            'fr': 'Ô Toi qui fais tourner les cœurs, affermis mon cœur dans Ta religion.',
            'es': 'Oh Tú que haces girar los corazones, afirma mi corazón en Tu religión.',
            'it': 'O Tu che volgi i cuori, rendi saldo il mio cuore nella Tua religione.',
            'de': 'O Wender der Herzen, festige mein Herz in Deiner Religion.',
            'pt': 'Ó Tu que volves os corações, firma o meu coração na Tua religião.',
          },
        'romanUrdu':
            'Ae dilon ko palat dene wale, mere dil ko apne deen par sabit farma.',
        'source': 'Sunan Tirmidhi 3522',
      },
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': {
            'en': 'Dua for Beneficial Knowledge',
            'fr': 'Dua pour une science utile',
            'es': 'Dua por un conocimiento beneficioso',
            'it': 'Dua per una scienza utile',
            'de': 'Dua um nützliches Wissen',
            'pt': 'Dua por conhecimento benéfico',
          },
        'arabic':
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
        'transliteration':
            "Allahumma inni as'aluka 'ilman nafi'an wa rizqan tayyiban wa 'amalan mutaqabbala",
        'english': {
            'en': 'O Allah, I ask You for beneficial knowledge, good provision, and accepted deeds.',
            'fr': 'Ô Allah, je Te demande une science utile, une subsistance pure et des œuvres agréées.',
            'es': 'Oh Allah, Te pido conocimiento beneficioso, sustento lícito y obras aceptadas.',
            'it': 'O Allah, Ti chiedo una scienza utile, un sostentamento puro e opere accettate.',
            'de': 'O Allah, ich bitte Dich um nützliches Wissen, gute Versorgung und angenommene Taten.',
            'pt': 'Ó Allah, peço-Te conhecimento benéfico, sustento puro e obras aceitas.',
          },
        'romanUrdu':
            'Ae Allah, main tujh se nafa bakhsh ilm, paak rizq aur qabool shuda amal maangta hoon.',
        'source': 'Sunan Ibn Majah 925',
      },
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': {
            'en': 'Dua for Anxiety and Grief',
            'fr': "Dua contre l'angoisse et le chagrin",
            'es': 'Dua contra la angustia y la tristeza',
            'it': "Dua contro l'angoscia e la tristezza",
            'de': 'Dua gegen Angst und Kummer',
            'pt': 'Dua contra a angústia e a tristeza',
          },
        'arabic':
            'اللَّهُمَّ إِنِّي عَبْدُكَ ابْنُ عَبْدِكَ ابْنُ أَمَتِكَ نَاصِيَتِي بِيَدِكَ مَاضٍ فِيَّ حُكْمُكَ عَدْلٌ فِيَّ قَضَاؤُكَ',
        'transliteration':
            "Allahumma inni 'abduka wabnu 'abdika wabnu amatika nasiyati biyadika madin fiyya hukmuka 'adlun fiyya qada'uk",
        'english': {
            'en': 'O Allah, I am Your servant, son of Your servant, son of Your handmaid. My forelock is in Your hand, Your command over me is forever executed, and Your decree over me is just.',
            'fr': "Ô Allah, je suis Ton serviteur, fils de Ton serviteur, fils de Ta servante. Mon toupet est dans Ta main, Ton décret s'accomplit toujours en moi et Ton jugement à mon égard est juste.",
            'es': 'Oh Allah, yo soy Tu siervo, hijo de Tu siervo, hijo de Tu sierva. Mi frente está en Tu mano, Tu orden sobre mí siempre se cumple y Tu decreto sobre mí es justo.',
            'it': 'O Allah, io sono il Tuo servo, figlio del Tuo servo, figlio della Tua serva. La mia fronte è nella Tua mano, il Tuo ordine su di me si compie sempre e il Tuo decreto su di me è giusto.',
            'de': 'O Allah, ich bin Dein Diener, Sohn Deines Dieners, Sohn Deiner Dienerin. Mein Haupthaar ist in Deiner Hand, Dein Befehl über mich wird stets vollzogen und Dein Urteil über mich ist gerecht.',
            'pt': 'Ó Allah, eu sou Teu servo, filho do Teu servo, filho da Tua serva. A minha fronte está em Tua mão, a Tua ordem sobre mim sempre se cumpre e o Teu decreto sobre mim é justo.',
          },
        'romanUrdu':
            'Ae Allah, main tera banda hoon, tere bande ka beta hoon, teri bandhi ka beta hoon. Meri peshaani tere haath mein hai, mujh par tera hukm jaari hai, mujh par tera faisla adl hai.',
        'source': 'Musnad Ahmad 3704',
      },
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': {
            'en': 'Dua Before Sleeping',
            'fr': 'Dua avant de dormir',
            'es': 'Dua antes de dormir',
            'it': 'Dua prima di dormire',
            'de': 'Dua vor dem Schlafen',
            'pt': 'Dua antes de dormir',
          },
        'arabic': 'اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا',
        'transliteration': 'Allahumma bismika amutu wa ahya',
        'english': {
            'en': 'O Allah, in Your name I die and I live.',
            'fr': "Ô Allah, c'est en Ton nom que je meurs et que je vis.",
            'es': 'Oh Allah, en Tu nombre muero y vivo.',
            'it': 'O Allah, nel Tuo nome muoio e vivo.',
            'de': 'O Allah, in Deinem Namen sterbe ich und lebe ich.',
            'pt': 'Ó Allah, em Teu nome morro e vivo.',
          },
        'romanUrdu':
            'Ae Allah, tere naam ke saath marta hoon aur tere naam ke saath jeeta hoon.',
        'source': 'Sahih Bukhari 6324',
      },
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': {
            'en': 'Dua for Rectification of Religion and World',
            'fr': "Dua pour redresser la religion et la vie d'ici-bas",
            'es': 'Dua por la rectitud de la religión y la vida',
            'it': 'Dua per la rettitudine della religione e della vita',
            'de': 'Dua um Rechtschaffenheit in Religion und Welt',
            'pt': 'Dua pela retidão da religião e da vida',
          },
        'arabic':
            'اللَّهُمَّ أَصْلِحْ لِي دِينِيَ الَّذِي هُوَ عِصْمَةُ أَمْرِي وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي',
        'transliteration':
            "Allahumma aslih li dini alladhi huwa 'ismatu amri wa aslih li dunyaya allati fiha ma'ashi",
        'english': {
            'en': 'O Allah, set right for me my religion which is the safeguard of my affairs, and set right for me my worldly life in which is my livelihood.',
            'fr': "Ô Allah, rends droite ma religion, qui est la sauvegarde de mes affaires, et rends bonne ma vie d'ici-bas, dans laquelle se trouve ma subsistance.",
            'es': 'Oh Allah, rectifica mi religión, que es la salvaguarda de mis asuntos, y rectifica mi vida mundanal, en la que está mi sustento.',
            'it': 'O Allah, rendi retta la mia religione, che è la salvaguardia dei miei affari, e rendi buona la mia vita terrena, nella quale è il mio sostentamento.',
            'de': 'O Allah, bringe meine Religion in Ordnung, die der Schutz meiner Angelegenheiten ist, und bringe mein weltliches Leben in Ordnung, in dem mein Lebensunterhalt liegt.',
            'pt': 'Ó Allah, retifica a minha religião, que é a salvaguarda dos meus assuntos, e retifica a minha vida mundana, na qual está o meu sustento.',
          },
        'romanUrdu':
            'Ae Allah, mere deen ko durust kar jo mere saare kamon ki hifaazat ka zariya hai, aur meri duniya ko durust kar jis mein mera guzaara hai.',
        'source': 'Sahih Muslim 2720',
      },
    ],
  },
  // ── 2. Daily Duas (10 duas) ─────────────────────────────────
  {
    'id': 'daily',
    'name': {
            'en': 'Daily Duas',
            'fr': 'Duas quotidiennes',
            'es': 'Duas diarias',
            'it': 'Dua quotidiane',
            'de': 'Tägliche Duas',
            'pt': 'Duas diárias',
          },
    'emoji': '☀️',
    'watermark': 'اليومية',
    'hasProphetSections': false,
    'duas': [
      {
        'title': {
            'en': 'Dua When Waking Up',
            'fr': 'Dua au réveil',
            'es': 'Dua al despertar',
            'it': 'Dua al risveglio',
            'de': 'Dua beim Aufwachen',
            'pt': 'Dua ao despertar',
          },
        'arabic':
            'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        'transliteration':
            "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
        'english': {
            'en': 'All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.',
            'fr': "Toute louange est à Allah qui nous a redonné la vie après nous l'avoir ôtée, et c'est vers Lui que se fera la résurrection.",
            'es': 'Toda alabanza es para Allah, que nos ha devuelto la vida después de habérnosla quitado, y hacia Él es la resurrección.',
            'it': 'Ogni lode è ad Allah, che ci ha ridato la vita dopo avercela tolta, e a Lui è la resurrezione.',
            'de': 'Alles Lob gebührt Allah, der uns das Leben wiedergab, nachdem Er es uns genommen hatte, und zu Ihm ist die Auferstehung.',
            'pt': 'Todo louvor pertence a Allah, que nos devolveu a vida depois de a ter tomado, e para Ele é a ressurreição.',
          },
        'romanUrdu':
            'Tamam taareef Allah ke liye hai jis ne hamen maut dene ke baad zindagi di aur usi ki taraf uthna hai.',
        'source': 'Sahih Bukhari 6312',
      },
      {
        'title': {
            'en': 'Dua Before Eating',
            'fr': 'Dua avant de manger',
            'es': 'Dua antes de comer',
            'it': 'Dua prima di mangiare',
            'de': 'Dua vor dem Essen',
            'pt': 'Dua antes de comer',
          },
        'arabic': 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
        'transliteration': "Bismillahi wa 'ala barakatillah",
        'english': {
            'en': 'In the name of Allah and with the blessings of Allah.',
            'fr': "Au nom d'Allah et avec la bénédiction d'Allah.",
            'es': 'En el nombre de Allah y con la bendición de Allah.',
            'it': 'Nel nome di Allah e con la benedizione di Allah.',
            'de': 'Im Namen Allahs und mit dem Segen Allahs.',
            'pt': 'Em nome de Allah e com a bênção de Allah.',
          },
        'romanUrdu': 'Allah ke naam se aur Allah ki barkat ke saath.',
        'source': 'Sunan Abu Dawud 3767',
      },
      {
        'title': {
            'en': 'Dua After Eating',
            'fr': 'Dua après le repas',
            'es': 'Dua después de comer',
            'it': 'Dua dopo il pasto',
            'de': 'Dua nach dem Essen',
            'pt': 'Dua depois de comer',
          },
        'arabic':
            'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
        'transliteration':
            'Alhamdu lillahil-ladhi at-amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah',
        'english': {
            'en': 'Praise be to Allah who fed me this and provided it for me without any effort or power on my part.',
            'fr': "Louange à Allah qui m'a nourri de ceci et me l'a accordé sans force ni puissance de ma part.",
            'es': 'Alabado sea Allah, que me ha alimentado con esto y me lo ha provisto sin esfuerzo ni poder por mi parte.',
            'it': 'Lode ad Allah che mi ha nutrito di questo e me lo ha concesso senza alcuna forza né potere da parte mia.',
            'de': 'Lob sei Allah, der mich damit gespeist und es mir gewährt hat, ohne Anstrengung oder Macht meinerseits.',
            'pt': 'Louvado seja Allah, que me alimentou com isto e me proveu sem esforço nem poder da minha parte.',
          },
        'romanUrdu':
            'Shukar hai Allah ka jis ne mujhe yeh khaana khilaya aur bina mere kisi zor aur taqat ke rizq diya.',
        'source': 'Sunan Tirmidhi 3458',
      },
      {
        'title': {
            'en': 'Dua When Entering the Home',
            'fr': 'Dua en entrant chez soi',
            'es': 'Dua al entrar en casa',
            'it': 'Dua entrando in casa',
            'de': 'Dua beim Betreten des Hauses',
            'pt': 'Dua ao entrar em casa',
          },
        'arabic':
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا',
        'transliteration':
            "Allahumma inni as'aluka khayral mawliji wa khayral makhraj bismillahi walajna wa bismillahi kharajna",
        'english': {
            'en': 'O Allah, I ask You for the good of entering and the good of leaving. In the name of Allah we enter and in the name of Allah we leave.',
            'fr': "Ô Allah, je Te demande le bien de l'entrée et le bien de la sortie. Au nom d'Allah nous entrons et au nom d'Allah nous sortons.",
            'es': 'Oh Allah, Te pido el bien al entrar y el bien al salir. En el nombre de Allah entramos y en el nombre de Allah salimos.',
            'it': "O Allah, Ti chiedo il bene dell'entrare e il bene dell'uscire. Nel nome di Allah entriamo e nel nome di Allah usciamo.",
            'de': 'O Allah, ich bitte Dich um das Gute des Eintretens und das Gute des Hinausgehens. Im Namen Allahs treten wir ein und im Namen Allahs gehen wir hinaus.',
            'pt': 'Ó Allah, peço-Te o bem ao entrar e o bem ao sair. Em nome de Allah entramos e em nome de Allah saímos.',
          },
        'romanUrdu':
            'Ae Allah, main tujh se dakhle ki bhalai aur bahar nikalne ki bhalai maangta hoon. Allah ke naam se hum daakhil hue aur Allah ke naam se hum nikal jaayenge.',
        'source': 'Sunan Abu Dawud 5096',
      },
      {
        'title': {
            'en': 'Dua When Leaving the Home',
            'fr': 'Dua en quittant la maison',
            'es': 'Dua al salir de casa',
            'it': 'Dua uscendo di casa',
            'de': 'Dua beim Verlassen des Hauses',
            'pt': 'Dua ao sair de casa',
          },
        'arabic':
            'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        'transliteration':
            'Bismillahi tawakkaltu alallahi wa la hawla wa la quwwata illa billah',
        'english': {
            'en': 'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.',
            'fr': "Au nom d'Allah, je place ma confiance en Allah, et il n'y a de force ni de puissance qu'en Allah.",
            'es': 'En el nombre de Allah, pongo mi confianza en Allah, y no hay fuerza ni poder sino en Allah.',
            'it': "Nel nome di Allah, pongo la mia fiducia in Allah, e non c'è forza né potere se non in Allah.",
            'de': 'Im Namen Allahs, ich setze mein Vertrauen auf Allah, und es gibt keine Macht und keine Kraft außer durch Allah.',
            'pt': 'Em nome de Allah, deposito a minha confiança em Allah, e não há força nem poder senão em Allah.',
          },
        'romanUrdu':
            'Allah ke naam se, maine Allah par bharosa kiya aur koi taqat aur koi zor nahi siwaay Allah ke.',
        'source': 'Sunan Tirmidhi 3426',
      },
      {
        'title': {
            'en': 'Dua Before Entering the Masjid',
            'fr': "Dua avant d'entrer à la mosquée",
            'es': 'Dua antes de entrar en la mezquita',
            'it': 'Dua prima di entrare in moschea',
            'de': 'Dua vor dem Betreten der Moschee',
            'pt': 'Dua antes de entrar na mesquita',
          },
        'arabic': 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        'transliteration': "Allahummaf-tah li abwaba rahmatik",
        'english': {
            'en': 'O Allah, open for me the doors of Your mercy.',
            'fr': 'Ô Allah, ouvre-moi les portes de Ta miséricorde.',
            'es': 'Oh Allah, ábreme las puertas de Tu misericordia.',
            'it': 'O Allah, aprimi le porte della Tua misericordia.',
            'de': 'O Allah, öffne mir die Tore Deiner Barmherzigkeit.',
            'pt': 'Ó Allah, abre-me as portas da Tua misericórdia.',
          },
        'romanUrdu': 'Ae Allah, mere liye apni rehmat ke darwaaze khol de.',
        'source': 'Sahih Muslim 713',
      },
      {
        'title': {
            'en': 'Dua When Leaving the Masjid',
            'fr': 'Dua en quittant la mosquée',
            'es': 'Dua al salir de la mezquita',
            'it': 'Dua uscendo dalla moschea',
            'de': 'Dua beim Verlassen der Moschee',
            'pt': 'Dua ao sair da mesquita',
          },
        'arabic': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
        'transliteration': "Allahumma inni as'aluka min fadlik",
        'english': {
            'en': 'O Allah, I ask You of Your bounty.',
            'fr': 'Ô Allah, je Te demande de Ta grâce.',
            'es': 'Oh Allah, Te pido de Tu favor.',
            'it': 'O Allah, Ti chiedo della Tua grazia.',
            'de': 'O Allah, ich bitte Dich um Deine Gunst.',
            'pt': 'Ó Allah, peço-Te da Tua graça.',
          },
        'romanUrdu': 'Ae Allah, main tujh se tere fazl ka sawaali hoon.',
        'source': 'Sahih Muslim 713',
      },
      {
        'title': {
            'en': 'Dua When Entering the Bathroom',
            'fr': 'Dua en entrant aux toilettes',
            'es': 'Dua al entrar al baño',
            'it': 'Dua entrando in bagno',
            'de': 'Dua beim Betreten der Toilette',
            'pt': 'Dua ao entrar no banheiro',
          },
        'arabic':
            'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
        'transliteration':
            "Allahumma inni a'udhu bika minal-khubuthi wal-khaba'ith",
        'english': {
            'en': 'O Allah, I seek refuge with You from evil and the evil ones.',
            'fr': 'Ô Allah, je cherche refuge auprès de Toi contre le mal et les êtres malfaisants.',
            'es': 'Oh Allah, me refugio en Ti del mal y de los seres malignos.',
            'it': 'O Allah, cerco rifugio presso di Te dal male e dagli esseri maligni.',
            'de': 'O Allah, ich suche Zuflucht bei Dir vor dem Bösen und den bösen Wesen.',
            'pt': 'Ó Allah, busco refúgio em Ti do mal e dos seres malignos.',
          },
        'romanUrdu':
            'Ae Allah, main tujh se napaak jinnat mardon aur napaak jinnat aurton se panaah maangta hoon.',
        'source': 'Sahih Bukhari 142',
      },
      {
        'title': {
            'en': 'Dua When Looking in the Mirror',
            'fr': 'Dua devant le miroir',
            'es': 'Dua al mirarse al espejo',
            'it': 'Dua davanti allo specchio',
            'de': 'Dua vor dem Spiegel',
            'pt': 'Dua ao olhar-se no espelho',
          },
        'arabic':
            'اللَّهُمَّ أَنْتَ حَسَّنْتَ خَلْقِي فَحَسِّنْ خُلُقِي',
        'transliteration': 'Allahumma anta hassanta khalqi fahassin khuluqi',
        'english': {
            'en': 'O Allah, You have made my physical form beautiful, so make my character beautiful too.',
            'fr': 'Ô Allah, Tu as embelli mon apparence, embellis donc aussi mon caractère.',
            'es': 'Oh Allah, Tú has hecho bella mi forma física, haz bello también mi carácter.',
            'it': 'O Allah, Tu hai reso bello il mio aspetto, rendi bello anche il mio carattere.',
            'de': 'O Allah, Du hast meine Gestalt schön gemacht, so mache auch meinen Charakter schön.',
            'pt': 'Ó Allah, Tu embelezaste a minha forma, embeleza também o meu caráter.',
          },
        'romanUrdu':
            'Ae Allah, tu ne meri soorat achhi banayi, toh meri seerat bhi achhi bana de.',
        'source': 'Musnad Ahmad 3823',
      },
      {
        'title': {
            'en': 'Dua Before Sleeping',
            'fr': 'Dua avant de dormir',
            'es': 'Dua antes de dormir',
            'it': 'Dua prima di dormire',
            'de': 'Dua vor dem Schlafen',
            'pt': 'Dua antes de dormir',
          },
        'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        'transliteration': 'Bismika Allahumma amutu wa ahya',
        'english': {
            'en': 'In Your name, O Allah, I die and I live.',
            'fr': 'En Ton nom, ô Allah, je meurs et je vis.',
            'es': 'En Tu nombre, oh Allah, muero y vivo.',
            'it': 'Nel Tuo nome, o Allah, muoio e vivo.',
            'de': 'In Deinem Namen, o Allah, sterbe ich und lebe ich.',
            'pt': 'Em Teu nome, ó Allah, morro e vivo.',
          },
        'romanUrdu':
            'Ae Allah, tere naam ke saath main marta hoon aur tere naam ke saath jeeta hoon.',
        'source': 'Sahih Bukhari 6324',
      },
    ],
  },
  // ── 3. Quranic Duas (7 duas) ────────────────────────────────
  {
    'id': 'quranic',
    'name': {
            'en': 'Quranic Duas',
            'fr': 'Duas coraniques',
            'es': 'Duas coránicas',
            'it': 'Dua coraniche',
            'de': 'Koranische Duas',
            'pt': 'Duas corânicas',
          },
    'emoji': '📖',
    'watermark': 'القرآن',
    'hasProphetSections': false,
    'duas': [
      {
        'title': {
            'en': 'Dua for Good in Both Worlds',
            'fr': 'Dua pour le bien dans les deux mondes',
            'es': 'Dua por el bien en ambos mundos',
            'it': 'Dua per il bene nei due mondi',
            'de': 'Dua um Gutes in beiden Welten',
            'pt': 'Dua pelo bem em ambos os mundos',
          },
        'arabic':
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        'transliteration':
            "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-naar",
        'english': {
            'en': 'Our Lord, give us good in this world and good in the Hereafter, and save us from the punishment of the Fire.',
            'fr': "Notre Seigneur, accorde-nous une belle part ici-bas, et une belle part aussi dans l'au-delà, et protège-nous du châtiment du Feu.",
            'es': 'Señor nuestro, concédenos bien en esta vida y bien en la otra, y presérvanos del castigo del Fuego.',
            'it': "Signore nostro, concedici il bene in questa vita e il bene nell'altra vita, e preservaci dal castigo del Fuoco.",
            'de': 'Unser Herr, gib uns im Diesseits Gutes und im Jenseits Gutes, und bewahre uns vor der Strafe des Feuers.',
            'pt': 'Senhor nosso, concede-nos o bem neste mundo e o bem no outro, e preserva-nos do castigo do Fogo.',
          },
        'romanUrdu':
            'Ae hamare Rabb, hamen dunya mein bhalai de aur aakhirat mein bhalai de aur hamen jahannam ke azaab se bacha.',
        'source': 'Quran 2:201',
      },
      {
        'title': {
            'en': 'Dua for Increase in Knowledge',
            'fr': "Dua pour l'accroissement du savoir",
            'es': 'Dua por el aumento del conocimiento',
            'it': "Dua per l'accrescimento della scienza",
            'de': 'Dua um mehr Wissen',
            'pt': 'Dua pelo aumento do conhecimento',
          },
        'arabic': 'رَّبِّ زِدْنِي عِلْمًا',
        'transliteration': "Rabbi zidni 'ilma",
        'english': {
            'en': 'My Lord, increase me in knowledge.',
            'fr': 'Seigneur, accrois mon savoir.',
            'es': 'Señor mío, auméntame el conocimiento.',
            'it': 'Signore, accresci la mia scienza.',
            'de': 'Mein Herr, lasse mich an Wissen zunehmen.',
            'pt': 'Senhor meu, aumenta-me o conhecimento.',
          },
        'romanUrdu': 'Ae mere Rabb, mujhe ilm mein izaafa farma.',
        'source': 'Quran 20:114',
      },
      {
        'title': {
            'en': 'Dua for Mercy and Guidance',
            'fr': 'Dua pour la miséricorde et la guidée',
            'es': 'Dua por la misericordia y la guía',
            'it': 'Dua per la misericordia e la guida',
            'de': 'Dua um Barmherzigkeit und Rechtleitung',
            'pt': 'Dua pela misericórdia e orientação',
          },
        'arabic':
            'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً',
        'transliteration':
            "Rabbana la tuzigh qulobana ba'da idh hadaytana wa hab lana milladunka rahmah",
        'english': {
            'en': 'Our Lord, let not our hearts deviate after You have guided us, and grant us from Yourself mercy.',
            'fr': 'Notre Seigneur, ne laisse pas dévier nos cœurs après que Tu nous as guidés, et accorde-nous Ta miséricorde.',
            'es': 'Señor nuestro, no dejes que nuestros corazones se desvíen después de habernos guiado, y concédenos de Tu parte misericordia.',
            'it': 'Signore nostro, non lasciar deviare i nostri cuori dopo che ci hai guidato, e concedici da parte Tua la misericordia.',
            'de': 'Unser Herr, lasse unsere Herzen nicht abweichen, nachdem Du uns rechtgeleitet hast, und schenke uns von Dir aus Barmherzigkeit.',
            'pt': 'Senhor nosso, não permitas que os nossos corações se desviem depois de nos haveres guiado, e concede-nos a Tua misericórdia.',
          },
        'romanUrdu':
            'Ae hamare Rabb, hamare dilon ko terhaa mat kar baad is ke ke tu ne hamen hidayat di, aur apni taraf se hamen rehmat ata farma.',
        'source': 'Quran 3:8',
      },
      {
        'title': {
            'en': 'Dua for Forgiveness and Mercy',
            'fr': 'Dua pour le pardon et la miséricorde',
            'es': 'Dua por el perdón y la misericordia',
            'it': 'Dua per il perdono e la misericordia',
            'de': 'Dua um Vergebung und Barmherzigkeit',
            'pt': 'Dua pelo perdão e a misericórdia',
          },
        'arabic':
            'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
        'transliteration':
            'Rabbana zalamna anfusana wa illam taghfir lana wa tarhamna lanakunanna minal khasireen',
        'english': {
            'en': 'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
            'fr': 'Notre Seigneur, nous avons fait du tort à nous-mêmes. Et si Tu ne nous pardonnes pas et ne nous fais pas miséricorde, nous serons très certainement du nombre des perdants.',
            'es': 'Señor nuestro, hemos sido injustos con nosotros mismos; y si no nos perdonas y no Te apiadas de nosotros, seremos ciertamente de los perdedores.',
            'it': 'Signore nostro, abbiamo mancato contro noi stessi; se non ci perdoni e non hai misericordia di noi, saremo certamente tra i perdenti.',
            'de': 'Unser Herr, wir haben uns selbst Unrecht zugefügt. Wenn Du uns nicht vergibst und Dich unser nicht erbarmst, werden wir ganz gewiss zu den Verlierern gehören.',
            'pt': 'Senhor nosso, fomos injustos com nós mesmos e, se não nos perdoares e não Te compadeceres de nós, seremos certamente dos perdedores.',
          },
        'romanUrdu':
            'Ae hamare Rabb, hum ne apne aap par zulm kiya aur agar Tu hamen maaf na kare aur hum par raham na kare to hum yaqeenan ghaate walon mein se honge.',
        'source': 'Quran 7:23',
      },
      {
        'title': {
            'en': 'Dua for Parents',
            'fr': 'Dua pour les parents',
            'es': 'Dua por los padres',
            'it': 'Dua per i genitori',
            'de': 'Dua für die Eltern',
            'pt': 'Dua pelos pais',
          },
        'arabic': 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
        'transliteration': 'Rabbir-hamhuma kama rabbayani saghira',
        'english': {
            'en': 'My Lord, have mercy upon them as they brought me up when I was small.',
            'fr': "Seigneur, fais-leur miséricorde comme ils m'ont élevé tout petit.",
            'es': 'Señor mío, ten misericordia de ellos como ellos me criaron cuando era pequeño.',
            'it': 'Signore, sii misericordioso con loro come essi lo sono stati con me allevandomi da piccolo.',
            'de': 'Mein Herr, erbarme Dich ihrer, wie sie mich aufgezogen haben, als ich klein war.',
            'pt': 'Senhor meu, tem misericórdia deles, como eles me criaram quando eu era pequeno.',
          },
        'romanUrdu':
            'Ae mere Rabb, un par raham farma jaise unhon ne mujhe bachpan mein pala.',
        'source': 'Quran 17:24',
      },
      {
        'title': {
            'en': 'Dua for Guidance to the Right Path',
            'fr': 'Dua pour la guidée vers le droit chemin',
            'es': 'Dua por la guía al camino recto',
            'it': 'Dua per la guida sulla retta via',
            'de': 'Dua um Rechtleitung auf den rechten Weg',
            'pt': 'Dua pela orientação ao caminho reto',
          },
        'arabic':
            'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
        'transliteration':
            'Rabbana atina milladunka rahmatan wa hayyi lana min amrina rashada',
        'english': {
            'en': 'Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance.',
            'fr': 'Notre Seigneur, accorde-nous de Ta part une miséricorde et assure-nous la droiture dans tout ce qui nous concerne.',
            'es': 'Señor nuestro, concédenos de Tu parte misericordia y dispón para nosotros rectitud en nuestro asunto.',
            'it': 'Signore nostro, concedici da parte Tua una misericordia e apprestaci retta guida nel nostro affare.',
            'de': 'Unser Herr, gib uns von Dir aus Barmherzigkeit und bereite uns in unserer Angelegenheit Rechtleitung.',
            'pt': 'Senhor nosso, concede-nos a Tua misericórdia e dispõe para nós retidão em nosso assunto.',
          },
        'romanUrdu':
            'Ae hamare Rabb, apni taraf se hamen rehmat ata farma aur hamare kaam mein hamare liye seedh ka intizaam farma.',
        'source': 'Quran 18:10',
      },
      {
        'title': {
            'en': 'Dua for Steadfastness in Battle',
            'fr': 'Dua pour la constance au combat',
            'es': 'Dua por la firmeza en la batalla',
            'it': 'Dua per la fermezza in battaglia',
            'de': 'Dua um Standhaftigkeit im Kampf',
            'pt': 'Dua pela firmeza na batalha',
          },
        'arabic':
            'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
        'transliteration':
            "Rabbana afrigh 'alayna sabran wa thabbit aqdamana wansurna 'alal-qawmil kafireen",
        'english': {
            'en': 'Our Lord, pour upon us patience and plant firmly our feet and give us victory over the disbelieving people.',
            'fr': "Notre Seigneur, déverse sur nous l'endurance, affermis nos pas et donne-nous la victoire sur le peuple mécréant.",
            'es': 'Señor nuestro, infúndenos paciencia, afirma nuestros pasos y concédenos la victoria sobre el pueblo incrédulo.',
            'it': 'Signore nostro, riversa su di noi la costanza, rendi saldi i nostri passi e dacci la vittoria sul popolo dei miscredenti.',
            'de': 'Unser Herr, überschütte uns mit Standhaftigkeit, festige unsere Füße und verhilf uns zum Sieg über das ungläubige Volk.',
            'pt': 'Senhor nosso, infunde-nos paciência, firma os nossos passos e concede-nos a vitória sobre o povo incrédulo.',
          },
        'romanUrdu':
            'Ae hamare Rabb, hum par sabr daal de aur hamare qadam mazbut kar de aur kaafir qaum ke khilaf hamari madad farma.',
        'source': 'Quran 2:250',
      },
    ],
  },
  // ── 4. Special Occasions (5 duas) ──────────────────────────
  {
    'id': 'occasions',
    'name': {
            'en': 'Special Occasions',
            'fr': 'Occasions spéciales',
            'es': 'Ocasiones especiales',
            'it': 'Occasioni speciali',
            'de': 'Besondere Anlässe',
            'pt': 'Ocasiões especiais',
          },
    'emoji': '⭐',
    'watermark': 'المناسبات',
    'hasProphetSections': false,
    'duas': [
      {
        'title': {
            'en': 'Dua for Laylatul Qadr',
            'fr': 'Dua pour Laylat al-Qadr',
            'es': 'Dua para Laylat al-Qadr',
            'it': 'Dua per Laylat al-Qadr',
            'de': 'Dua für Laylat al-Qadr',
            'pt': 'Dua para Laylat al-Qadr',
          },
        'arabic':
            'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
        'transliteration':
            "Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni",
        'english': {
            'en': 'O Allah, You are Pardoning and You love pardon, so pardon me.',
            'fr': 'Ô Allah, Tu es Celui qui pardonne et Tu aimes le pardon, pardonne-moi donc.',
            'es': 'Oh Allah, Tú eres Indulgente y amas el perdón, perdóname pues.',
            'it': 'O Allah, Tu sei Colui che perdona e ami il perdono, perdonami dunque.',
            'de': 'O Allah, Du bist der Verzeihende und Du liebst das Verzeihen, so verzeihe mir.',
            'pt': 'Ó Allah, Tu és Indulgente e amas o perdão, perdoa-me pois.',
          },
        'romanUrdu':
            'Ae Allah, Tu maaf karne wala hai aur maafi ko pasand karta hai, pas mujhe maaf farma de.',
        'source': 'Sunan Ibn Majah 3850',
      },
      {
        'title': {
            'en': 'Dua for Breaking Fast (Iftar)',
            'fr': 'Dua pour la rupture du jeûne (iftar)',
            'es': 'Dua para romper el ayuno (iftar)',
            'it': 'Dua per la rottura del digiuno (iftar)',
            'de': 'Dua zum Fastenbrechen (Iftar)',
            'pt': 'Dua para romper o jejum (iftar)',
          },
        'arabic':
            'اللَّهُمَّ لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ',
        'transliteration':
            "Allahumma laka sumtu wa bika amantu wa 'alayka tawakkaltu wa 'ala rizqika aftart",
        'english': {
            'en': 'O Allah, I fasted for You and I believe in You and I put my trust in You and I break my fast with Your sustenance.',
            'fr': "Ô Allah, c'est pour Toi que j'ai jeûné, en Toi que j'ai cru, à Toi que je me suis confié, et c'est de Ta subsistance que je romps mon jeûne.",
            'es': 'Oh Allah, por Ti he ayunado, en Ti he creído, en Ti he confiado y con Tu sustento rompo mi ayuno.',
            'it': 'O Allah, per Te ho digiunato, in Te ho creduto, in Te ho confidato e con il Tuo sostentamento rompo il digiuno.',
            'de': 'O Allah, für Dich habe ich gefastet, an Dich habe ich geglaubt, auf Dich habe ich vertraut und mit Deiner Versorgung breche ich mein Fasten.',
            'pt': 'Ó Allah, por Ti jejuei, em Ti acreditei, em Ti confiei e com o Teu sustento rompo o meu jejum.',
          },
        'romanUrdu':
            'Ae Allah, maine tere liye roza rakha aur tujh par imaan laya aur tujh par bharosa kiya aur tere rizq se iftaar kiya.',
        'source': 'Sunan Abu Dawud 2358',
      },
      {
        'title': {
            'en': 'Dua on the Day of Arafah',
            'fr': 'Dua du jour de Arafah',
            'es': 'Dua del día de Arafah',
            'it': 'Dua del giorno di Arafah',
            'de': 'Dua am Tag von Arafah',
            'pt': 'Dua do dia de Arafah',
          },
        'arabic':
            'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        'transliteration':
            'La ilaha illallahu wahdahu la sharika lah lahul-mulku wa lahul-hamdu wa huwa ala kulli shay in qadir',
        'english': {
            'en': 'There is no god but Allah alone, He has no partner, His is the dominion and His is the praise, and He has power over everything.',
            'fr': "Il n'y a de dieu qu'Allah, Seul, sans associé ; à Lui la royauté et à Lui la louange, et Il est capable de toute chose.",
            'es': 'No hay dios sino Allah, Único, sin asociado alguno; Suyo es el dominio y Suya es la alabanza, y Él tiene poder sobre todas las cosas.',
            'it': "Non c'è dio se non Allah, l'Unico, senza associati; Sua è la sovranità e Sua è la lode, ed Egli è onnipotente su ogni cosa.",
            'de': 'Es gibt keinen Gott außer Allah, Er allein, Er hat keinen Teilhaber; Sein ist die Herrschaft und Sein ist das Lob, und Er hat Macht über alle Dinge.',
            'pt': 'Não há deus senão Allah, Único, sem associado; Dele é o domínio e Dele é o louvor, e Ele tem poder sobre todas as coisas.',
          },
        'romanUrdu':
            'Allah ke siwa koi ilaah nahi, akela hai, uska koi shareek nahi, usi ki badshaahi hai aur usi ki taareef hai aur woh har cheez par qadir hai.',
        'source': 'Sunan Tirmidhi 3585',
      },
      {
        'title': {
            'en': 'Dua When Visiting the Sick',
            'fr': 'Dua pour visiter un malade',
            'es': 'Dua al visitar a un enfermo',
            'it': 'Dua per la visita a un malato',
            'de': 'Dua beim Besuch eines Kranken',
            'pt': 'Dua ao visitar um doente',
          },
        'arabic':
            'أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَكَ',
        'transliteration':
            "As'alullaahal-'azeema rabbal-'arshil-'azeemi an yashfiyak",
        'english': {
            'en': 'I ask Allah, the Mighty, the Lord of the Mighty Throne, to cure you.',
            'fr': "Je demande à Allah l'Immense, Seigneur du Trône immense, de te guérir.",
            'es': 'Pido a Allah, el Inmenso, Señor del Trono inmenso, que te cure.',
            'it': "Chiedo ad Allah, l'Immenso, Signore del Trono immenso, di guarirti.",
            'de': 'Ich bitte Allah, den Gewaltigen, den Herrn des gewaltigen Thrones, dich zu heilen.',
            'pt': 'Peço a Allah, o Magnífico, Senhor do Trono magnífico, que te cure.',
          },
        'romanUrdu':
            'Main Allah azeem se jo arsh azeem ka Rabb hai dua karta hoon ke woh tujhe shifa de.',
        'source': 'Sunan Abu Dawud 3106',
      },
      {
        'title': {
            'en': 'Dua When it Rains',
            'fr': 'Dua quand il pleut',
            'es': 'Dua cuando llueve',
            'it': 'Dua quando piove',
            'de': 'Dua bei Regen',
            'pt': 'Dua quando chove',
          },
        'arabic': 'اللَّهُمَّ صَيِّبًا نَافِعًا',
        'transliteration': "Allahumma sayyiban nafi'a",
        'english': {
            'en': 'O Allah, make it a beneficial rain.',
            'fr': 'Ô Allah, fais que ce soit une pluie bénéfique.',
            'es': 'Oh Allah, haz que sea una lluvia beneficiosa.',
            'it': "O Allah, fa' che sia una pioggia benefica.",
            'de': 'O Allah, mache es zu einem nützlichen Regen.',
            'pt': 'Ó Allah, faz dela uma chuva benéfica.',
          },
        'romanUrdu': 'Ae Allah, ise nafa bakhsh baarish bana.',
        'source': 'Sahih Bukhari 1032',
      },
    ],
  },
  // ── 5. Success & Protection (5 duas) ───────────────────────
  {
    'id': 'protection',
    'name': {
            'en': 'Success & Protection',
            'fr': 'Réussite et protection',
            'es': 'Éxito y protección',
            'it': 'Successo e protezione',
            'de': 'Erfolg und Schutz',
            'pt': 'Sucesso e proteção',
          },
    'emoji': '🛡️',
    'watermark': 'الحماية',
    'hasProphetSections': false,
    'duas': [
      {
        'title': {
            'en': 'Dua for Protection from Evil Eye',
            'fr': 'Dua de protection contre le mauvais œil',
            'es': 'Dua de protección contra el mal de ojo',
            'it': 'Dua di protezione dal malocchio',
            'de': 'Dua um Schutz vor dem bösen Blick',
            'pt': 'Dua de proteção contra o mau-olhado',
          },
        'arabic':
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        'transliteration':
            "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
        'english': {
            'en': 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
            'fr': "Je cherche refuge dans les paroles parfaites d'Allah contre le mal de ce qu'Il a créé.",
            'es': 'Me refugio en las palabras perfectas de Allah del mal de lo que Él ha creado.',
            'it': 'Cerco rifugio nelle parole perfette di Allah dal male di ciò che Egli ha creato.',
            'de': 'Ich suche Zuflucht in den vollkommenen Worten Allahs vor dem Übel dessen, was Er geschaffen hat.',
            'pt': 'Busco refúgio nas palavras perfeitas de Allah do mal de tudo o que Ele criou.',
          },
        'romanUrdu':
            'Main Allah ke kaamil kalimat ki panaah maangta hoon us ki tamam makhluq ki burai se.',
        'source': 'Sahih Muslim 2708',
      },
      {
        'title': {
            'en': 'Dua for Debt Relief',
            'fr': 'Dua pour se libérer des dettes',
            'es': 'Dua para liberarse de las deudas',
            'it': 'Dua per liberarsi dai debiti',
            'de': 'Dua um Befreiung von Schulden',
            'pt': 'Dua para livrar-se das dívidas',
          },
        'arabic':
            'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
        'transliteration':
            "Allahumma-kfini bihalaalika 'an haramika wa aghnini bifadlika 'amman siwak",
        'english': {
            'en': 'O Allah, suffice me with what You have made lawful so that I have no need of what You have made unlawful, and make me independent of all those other than You by Your grace.',
            'fr': "Ô Allah, satisfais-moi par ce que Tu as rendu licite afin que je n'aie nul besoin de ce que Tu as interdit, et par Ta grâce rends-moi indépendant de tout autre que Toi.",
            'es': 'Oh Allah, bástame con lo que has hecho lícito para que no necesite lo que has prohibido, y con Tu favor hazme independiente de todo aquel que no seas Tú.',
            'it': "O Allah, bastami ciò che hai reso lecito, così che non abbia bisogno di ciò che hai proibito, e con la Tua grazia rendimi indipendente da chiunque altro all'infuori di Te.",
            'de': 'O Allah, lasse mir das genügen, was Du erlaubt hast, damit ich dessen nicht bedarf, was Du verboten hast, und mache mich durch Deine Gunst unabhängig von allen außer Dir.',
            'pt': 'Ó Allah, basta-me o que tornaste lícito, para que não precise do que proibiste, e, pela Tua graça, torna-me independente de todos além de Ti.',
          },
        'romanUrdu':
            'Ae Allah, apne halaal se mujhe apne haraam se be-niyaaz farma aur apne fazl se mujhe apne siwa sab se be-niyaaz farma.',
        'source': 'Sunan Tirmidhi 3563',
      },
      {
        'title': {
            'en': 'Dua for Ease in Affairs',
            'fr': 'Dua pour la facilité dans les affaires',
            'es': 'Dua por la facilidad en los asuntos',
            'it': 'Dua per la facilità negli affari',
            'de': 'Dua um Erleichterung in Angelegenheiten',
            'pt': 'Dua pela facilidade nos assuntos',
          },
        'arabic': 'رَبِّ يَسِّرْ وَلَا تُعَسِّرْ وَتَمِّمْ بِالْخَيْرِ',
        'transliteration': "Rabbi yassir wa la tu'assir wa tammim bil-khayr",
        'english': {
            'en': 'My Lord, make things easy and do not make them difficult, and complete things with goodness.',
            'fr': 'Seigneur, facilite et ne rends pas difficile, et parachève dans le bien.',
            'es': 'Señor mío, facilita y no dificultes, y culmina con el bien.',
            'it': 'Signore, facilita e non rendere difficile, e porta a compimento nel bene.',
            'de': 'Mein Herr, mache es leicht und nicht schwer, und vollende es mit Gutem.',
            'pt': 'Senhor meu, facilita e não dificultes, e conclui com o bem.',
          },
        'romanUrdu':
            'Ae mere Rabb, aasaan farma aur mushkil mat bana aur bhalai ke saath mukammal farma.',
        'source': 'Athari — widely reported supplication',
      },
      {
        'title': {
            'en': 'Dua for Morning Protection',
            'fr': 'Dua de protection du matin',
            'es': 'Dua de protección matinal',
            'it': 'Dua di protezione del mattino',
            'de': 'Dua um Schutz am Morgen',
            'pt': 'Dua de proteção matinal',
          },
        'arabic':
            'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
        'transliteration':
            'Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namutu wa ilaykan-nushur',
        'english': {
            'en': 'O Allah, by You we have entered the morning, by You we have entered the evening, by You we live and by You we die, and unto You is the resurrection.',
            'fr': "Ô Allah, c'est par Toi que nous entrons dans le matin et par Toi que nous entrons dans le soir, par Toi que nous vivons et par Toi que nous mourons, et c'est vers Toi que se fera la résurrection.",
            'es': 'Oh Allah, por Ti hemos llegado a la mañana y por Ti hemos llegado a la tarde, por Ti vivimos y por Ti morimos, y hacia Ti es la resurrección.',
            'it': 'O Allah, per Te siamo giunti al mattino e per Te siamo giunti alla sera, per Te viviamo e per Te moriamo, e verso di Te è la resurrezione.',
            'de': 'O Allah, durch Dich haben wir den Morgen erreicht und durch Dich den Abend, durch Dich leben wir und durch Dich sterben wir, und zu Dir ist die Auferstehung.',
            'pt': 'Ó Allah, por Ti alcançamos a manhã e por Ti alcançamos a noite, por Ti vivemos e por Ti morremos, e para Ti é a ressurreição.',
          },
        'romanUrdu':
            'Ae Allah, tere zariye hum ne subah ki aur tere zariye hum ne shaam ki, tere zariye hum jeete hain aur tere zariye hum marte hain aur tere paas hi uthna hai.',
        'source': 'Sunan Tirmidhi 3391',
      },
      {
        'title': {
            'en': 'Dua for Protection from Shaytan',
            'fr': 'Dua de protection contre Shaytan',
            'es': 'Dua de protección contra Shaytán',
            'it': 'Dua di protezione da Shaytan',
            'de': 'Dua um Schutz vor Schaitan',
            'pt': 'Dua de proteção contra Shaytan',
          },
        'arabic':
            'أَعُوذُ بِاللَّهِ السَّمِيعِ الْعَلِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        'transliteration':
            "A'udhu billahis-samee'il-'aleemi minash-shaytanir-rajeem",
        'english': {
            'en': 'I seek refuge in Allah, the All-Hearing, the All-Knowing, from the accursed devil.',
            'fr': "Je cherche refuge auprès d'Allah, l'Audient, l'Omniscient, contre le diable maudit.",
            'es': 'Me refugio en Allah, Quien todo lo oye, Quien todo lo sabe, del demonio maldito.',
            'it': "Cerco rifugio in Allah, l'Audiente, il Sapiente, dal demonio maledetto.",
            'de': 'Ich suche Zuflucht bei Allah, dem Allhörenden, dem Allwissenden, vor dem verfluchten Satan.',
            'pt': 'Busco refúgio em Allah, o Oniouvinte, o Onisciente, do demônio maldito.',
          },
        'romanUrdu':
            'Main Allah se jo sunne wala aur jaanne wala hai, mardood shaytan se panaah maangta hoon.',
        'source': 'Sunan Tirmidhi 3392',
      },
    ],
  },
];

// ═══════════════════════════════════════════════════════════════
// LEVEL 1 — CATEGORIES PAGE
// ═══════════════════════════════════════════════════════════════

IconData _categoryIcon(String id) {
  switch (id) {
    case 'prophets':  return Icons.people;
    case 'daily':     return Icons.wb_sunny;
    case 'quranic':   return Icons.book;
    case 'occasions': return Icons.star;
    case 'protection': return Icons.security;
    default:          return Icons.list;
  }
}

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _searchResults {
    final q = _query.toLowerCase();
    final results = <Map<String, dynamic>>[];
    // Search what is actually on screen. Matching English titles while the
    // list renders French would look broken from either direction.
    final lang = Localizations.localeOf(context).languageCode;
    for (final cat in duasCategories) {
      final catName = duaField(cat, 'name', lang);
      for (final dua in cat['duas'] as List<dynamic>) {
        final d = dua as Map<String, dynamic>;
        final matchTitle = duaField(d, 'title', lang).toLowerCase().contains(q);
        final matchArabic = (d['arabic'] as String).contains(_query);
        final matchEng = duaField(d, 'english', lang).toLowerCase().contains(q);
        final matchUrdu =
            (d['romanUrdu'] as String).toLowerCase().contains(q);
        final matchTranslit =
            (d['transliteration'] as String).toLowerCase().contains(q);
        if (matchTitle || matchArabic || matchEng || matchUrdu || matchTranslit) {
          results.add({...d, '_categoryName': catName});
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final bool searching = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.back(size: 22, color: context.textDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          L.of(context).quickDuas,
          style: TextStyle(
            color: context.text,
            fontSize: 16,
            fontFamily: 'serif',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Bismillah header
                _BismillahHeader(),
                // Search bar
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          if (!searching)
            // Category cards grid
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _CategoryCard(
                    category: duasCategories[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DuasCategoryPage(
                          category: duasCategories[i],
                        ),
                      ),
                    ),
                  ),
                  childCount: duasCategories.length,
                ),
              ),
            )
          else
            // Search results
            _searchResults.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        L.of(context).duasNoResults,
                        style: TextStyle(
                          color: context.textDim,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            _SearchResultCard(dua: _searchResults[i]),
                        childCount: _searchResults.length,
                      ),
                    ),
                  ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Bismillah header ──────────────────────────────────────────

class _BismillahHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Scheherazade',
              fontSize: 26,
              color: AppColors.gold,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'In the name of Allah, the Most Gracious, the Most Merciful',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: context.textDim,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ───────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(fontSize: 14, color: context.text),
          decoration: InputDecoration(
            hintText: L.of(context).duasSearchHint,
            hintStyle: TextStyle(fontSize: 13, color: context.textDim),
            prefixIcon:
                Icon(Icons.search, size: 20, color: context.textDim),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, size: 18, color: context.textDim),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duas = category['duas'] as List<dynamic>;
    final count = duas.length;
    final previewLang = Localizations.localeOf(context).languageCode;
    final preview1 = count > 0
        ? duaField(duas[0] as Map<String, dynamic>, 'title', previewLang)
        : '';
    final preview2 = count > 1
        ? duaField(duas[1] as Map<String, dynamic>, 'title', previewLang)
        : '';
    final watermark = category['watermark'] as String;
    final bool dark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? [
                    const Color(0xFF1E1A06),
                    const Color(0xFF181408),
                    const Color(0xFF120F04),
                  ]
                : [
                    const Color(0xFFFFFBF0),
                    const Color(0xFFFAF0D0),
                    const Color(0xFFF2E3B0),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.gold.withOpacity(dark ? 0.35 : 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(dark ? 0.08 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Arabic watermark
              Positioned(
                right: -10,
                bottom: -12,
                child: Text(
                  watermark,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Scheherazade',
                    fontSize: 72,
                    color: AppColors.gold.withOpacity(dark ? 0.06 : 0.08),
                    height: 1,
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + name row
                    Row(
                      children: [
                        Icon(
                          _categoryIcon(category['id'] as String),
                          size: 28,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                duaField(category, 'name',
                                    Localizations.localeOf(context)
                                        .languageCode),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: context.text,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.gold.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  L.of(context).duasCount(count),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.goldDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.gold.withOpacity(0.7),
                        ),
                      ],
                    ),
                    if (preview1.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: AppColors.gold.withOpacity(0.2),
                      ),
                      const SizedBox(height: 10),
                      // Sneak peek duas
                      _PreviewRow(text: preview1),
                      if (preview2.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _PreviewRow(text: preview2),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String text;
  const _PreviewRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: context.textDim,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Search result card ────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> dua;
  const _SearchResultCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: _ExpandableDuaCard(
        dua: dua,
        categoryLabel: dua['_categoryName'] as String?,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEVEL 2 — DUAS CATEGORY PAGE
// ═══════════════════════════════════════════════════════════════

class DuasCategoryPage extends StatelessWidget {
  final Map<String, dynamic> category;
  const DuasCategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final bool hasProphets = category['hasProphetSections'] == true;
    final duas = category['duas'] as List<dynamic>;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.back(size: 22, color: context.textDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(category['id'] as String),
              size: 18,
              color: AppColors.gold,
            ),
            const SizedBox(width: 8),
            Text(
              duaField(category, 'name',
                  Localizations.localeOf(context).languageCode),
              style: TextStyle(
                color: context.text,
                fontSize: 15,
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: hasProphets
          ? _ProphetGroupedList(duas: duas)
          : _FlatDuaList(duas: duas),
    );
  }
}

// ── Prophet grouped list (Category 1) ────────────────────────

class _ProphetGroupedList extends StatelessWidget {
  final List<dynamic> duas;
  const _ProphetGroupedList({required this.duas});

  Map<String, List<Map<String, dynamic>>> _groupByProphet() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final dua in duas) {
      final d = dua as Map<String, dynamic>;
      final prophet = d['prophet'] as String? ?? 'Other';
      groups.putIfAbsent(prophet, () => []).add(d);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByProphet();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        for (final entry in groups.entries)
          _ProphetSection(
            prophetName: entry.key,
            duas: entry.value,
          ),
      ],
    );
  }
}

// ── Prophet section (collapsible) ────────────────────────────

class _ProphetSection extends StatefulWidget {
  final String prophetName;
  final List<Map<String, dynamic>> duas;
  const _ProphetSection({required this.prophetName, required this.duas});

  @override
  State<_ProphetSection> createState() => _ProphetSectionState();
}

class _ProphetSectionState extends State<_ProphetSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _ctrl;
  late Animation<double> _rotatAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _rotatAnim = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.duas.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prophet header
          GestureDetector(
            onTap: _toggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.prophetName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.text,
                          ),
                        ),
                        Text(
                          L.of(context).duasCount(count),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotatAnim,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Duas list (animated)
          SizeTransition(
            sizeFactor: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 6),
                for (final dua in widget.duas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ExpandableDuaCard(dua: dua),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Flat dua list (Categories 2–5) ───────────────────────────

class _FlatDuaList extends StatelessWidget {
  final List<dynamic> duas;
  const _FlatDuaList({required this.duas});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      itemCount: duas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) =>
          _ExpandableDuaCard(dua: duas[i] as Map<String, dynamic>),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXPANDABLE DUA CARD
// ═══════════════════════════════════════════════════════════════

class _ExpandableDuaCard extends StatefulWidget {
  final Map<String, dynamic> dua;
  final String? categoryLabel;

  const _ExpandableDuaCard({required this.dua, this.categoryLabel});

  @override
  State<_ExpandableDuaCard> createState() => _ExpandableDuaCardState();
}

class _ExpandableDuaCardState extends State<_ExpandableDuaCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _copy(BuildContext context) {
    final d = widget.dua;
    final sourceLine = L.of(context).duasCopySourceLine(d['source'] as String);
    final lang = Localizations.localeOf(context).languageCode;
    // Copies the meaning in the language the user is reading it in; the
    // Arabic, transliteration and Roman Urdu are the same in every locale.
    final text = '${d['arabic']}\n\n${d['transliteration']}\n\n'
        '${duaField(d, 'english', lang)}\n\n${d['romanUrdu']}\n\n$sourceLine';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L.of(context).duasCopiedToClipboard),
        backgroundColor: AppColors.goldDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dua;
    final String title =
        duaField(d, 'title', Localizations.localeOf(context).languageCode);
    final String source = d['source'] as String;

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Collapsed header ──────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category label (search results only)
                        if (widget.categoryLabel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 5),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              widget.categoryLabel!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.goldDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.text,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            source,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 280),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.textDim,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ──────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 1, color: context.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Arabic text
                      Text(
                        d['arabic'] as String,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Scheherazade',
                          fontSize: 24,
                          color: context.arabic,
                          height: 1.9,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2. Transliteration
                      Text(
                        d['transliteration'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: context.translit,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Divider
                      Container(
                        height: 1,
                        color: context.border.withOpacity(0.5),
                      ),
                      const SizedBox(height: 10),
                      // 3. English translation
                      _SectionLabel(label: L.of(context).languageEnglish),
                      const SizedBox(height: 4),
                      Text(
                        duaField(d, 'english',
                            Localizations.localeOf(context).languageCode),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.text2,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 4. Roman Urdu translation
                      _SectionLabel(label: L.of(context).duasRomanUrduLabel),
                      const SizedBox(height: 4),
                      Text(
                        d['romanUrdu'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.urduText,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 5. Source + copy button
                      Row(
                        children: [
                          const Icon(Icons.auto_stories_outlined,
                              size: 12, color: AppColors.gold),
                          const SizedBox(width: 5),
                          Text(
                            source,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _copy(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.gold.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.copy_outlined,
                                      size: 12, color: AppColors.gold),
                                  const SizedBox(width: 4),
                                  Text(
                                    L.of(context).duasCopy,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: AppColors.gold.withOpacity(0.8),
      ),
    );
  }
}
