import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

// ═══════════════════════════════════════════════════════════════
// DATA — 51 authentic duas across 5 categories
// Each dua map keys: title, arabic, transliteration, english,
//   romanUrdu, source, [prophet] (category 1 only)
// ═══════════════════════════════════════════════════════════════

const List<Map<String, dynamic>> duasCategories = [
  // ── 1. Duas of the Prophets (24 duas) ──────────────────────
  {
    'id': 'prophets',
    'name': 'Duas of the Prophets',
    'emoji': '🕌',
    'watermark': 'الأنبياء',
    'hasProphetSections': true,
    'duas': [
      // Adam
      {
        'prophet': 'Prophet Adam (عليه السلام)',
        'title': 'Dua of Repentance',
        'arabic':
            'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
        'transliteration':
            'Rabbana zalamna anfusana wa illam taghfir lana wa tarhamna lanakunanna minal khasireen',
        'english':
            'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
        'romanUrdu':
            'Ae hamare Rabb, hum ne apne aap par zulm kiya aur agar Tu ne hamen maaf na kiya aur hum par raham na kiya to hum yaqeenan nuqsaan uthaane walon mein se honge.',
        'source': 'Quran 7:23',
      },
      // Nuh
      {
        'prophet': 'Prophet Nuh (عليه السلام)',
        'title': 'Dua for Help Against Disbelievers',
        'arabic': 'رَبِّ إِنِّي مَغْلُوبٌ فَانتَصِرْ',
        'transliteration': 'Rabbi inni maghlubun fantasir',
        'english': 'My Lord, I am overpowered, so help me.',
        'romanUrdu':
            'Ae mere Rabb, main maghlub ho gaya hoon, pas Tu meri madad farma.',
        'source': 'Quran 54:10',
      },
      {
        'prophet': 'Prophet Nuh (عليه السلام)',
        'title': 'Dua for Forgiveness',
        'arabic':
            'رَّبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَن دَخَلَ بَيْتِيَ مُؤْمِنًا وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ',
        'transliteration':
            "Rabbigh-fir li wa liwaalidayya wa liman dakhala baytiya mu'minan wa lil-mu'mineena wal-mu'minaat",
        'english':
            'My Lord, forgive me and my parents and whoever enters my house as a believer and the believing men and believing women.',
        'romanUrdu':
            'Ae mere Rabb, mujhe aur mere walidain ko aur jo bhi mere ghar mein imaan ke saath daakhil ho aur tamaam momin mardon aur momin aurton ko maaf farma.',
        'source': 'Quran 71:28',
      },
      // Ibrahim
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': 'Dua for a Righteous Child',
        'arabic': 'رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ',
        'transliteration': 'Rabbi hab li minas-saliheen',
        'english': 'My Lord, grant me a child from among the righteous.',
        'romanUrdu':
            'Ae mere Rabb, mujhe naik logon mein se (aulaad) ata farma.',
        'source': 'Quran 37:100',
      },
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': 'Dua for Acceptance of Worship',
        'arabic':
            'رَبَّنَا تَقَبَّلْ مِنَّا ۖ إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ',
        'transliteration':
            'Rabbana taqabbal minna innaka antas-samee ul-aleem',
        'english':
            'Our Lord, accept from us. Indeed You are the Hearing, the Knowing.',
        'romanUrdu':
            'Ae hamare Rabb, hum se qabool farma. Beshak Tu hi sunne wala aur jaanne wala hai.',
        'source': 'Quran 2:127',
      },
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': 'Dua for a City of Peace',
        'arabic':
            'رَبِّ اجْعَلْ هَٰذَا بَلَدًا آمِنًا وَارْزُقْ أَهْلَهُ مِنَ الثَّمَرَاتِ',
        'transliteration':
            'Rabbij-al hadha baladan aminan war-zuq ahlahu minat-thamarat',
        'english':
            'My Lord, make this a secure city and provide its people with fruits.',
        'romanUrdu':
            'Ae mere Rabb, is shahar ko amn wala bana aur iske bashindon ko phalon ka rizq de.',
        'source': 'Quran 2:126',
      },
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': 'Dua for Steadfastness in Prayer',
        'arabic':
            'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي ۚ رَبَّنَا وَتَقَبَّلْ دُعَاءِ',
        'transliteration':
            "Rabbij-alni muqimas-salati wa min dhurriyyati rabbana wa taqabbal du'a",
        'english':
            'My Lord, make me an establisher of prayer, and from my descendants. Our Lord, and accept my supplication.',
        'romanUrdu':
            'Ae mere Rabb, mujhe namaaz qaim karne wala bana aur meri aulaad ko bhi. Ae hamare Rabb, aur meri dua qabool farma.',
        'source': 'Quran 14:40',
      },
      {
        'prophet': 'Prophet Ibrahim (عليه السلام)',
        'title': 'Dua for Forgiveness on Judgement Day',
        'arabic':
            'رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
        'transliteration':
            "Rabbanaghfir li wa liwaalidayya wa lil-mu'mineena yawma yaqumul hisab",
        'english':
            'Our Lord, forgive me and my parents and the believers the Day the account is established.',
        'romanUrdu':
            'Ae hamare Rabb, mujhe aur mere walidain ko aur tamam mominon ko us din maaf farma jis din hisaab qaim hoga.',
        'source': 'Quran 14:41',
      },
      // Yunus
      {
        'prophet': 'Prophet Yunus (عليه السلام)',
        'title': 'Dua from the Darkness',
        'arabic':
            'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
        'transliteration':
            'La ilaha illa anta subhanaka inni kuntu minaz-zalimeen',
        'english':
            'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
        'romanUrdu':
            'Tere siwa koi ilaah nahi, Tu paak hai, beshak main zalimoon mein se tha.',
        'source': 'Quran 21:87',
      },
      // Musa
      {
        'prophet': 'Prophet Musa (عليه السلام)',
        'title': 'Dua for Forgiveness',
        'arabic': 'رَبِّ إِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي',
        'transliteration': 'Rabbi inni zalamtu nafsi faghfir li',
        'english': 'My Lord, indeed I have wronged myself, so forgive me.',
        'romanUrdu':
            'Ae mere Rabb, beshak maine apne aap par zulm kiya, pas mujhe maaf farma de.',
        'source': 'Quran 28:16',
      },
      {
        'prophet': 'Prophet Musa (عليه السلام)',
        'title': 'Dua for Ease in Affairs',
        'arabic':
            'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي يَفْقَهُوا قَوْلِي',
        'transliteration':
            'Rabbish-rah li sadri wa yassir li amri wahlul uqdatan min lisani yafqahu qawli',
        'english':
            'My Lord, expand my breast, ease my task, and remove the impediment from my speech so they may understand what I say.',
        'romanUrdu':
            'Ae mere Rabb, mera seena khol de, mera kaam aasaan kar de aur meri zaban ki gaanh khol de taake log meri baat samjhein.',
        'source': 'Quran 20:25-28',
      },
      {
        'prophet': 'Prophet Musa (عليه السلام)',
        'title': 'Dua for Good Provision',
        'arabic': 'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
        'transliteration': 'Rabbi inni lima anzalta ilayya min khayrin faqeer',
        'english':
            'My Lord, indeed I am in need of whatever good You would send down to me.',
        'romanUrdu':
            'Ae mere Rabb, beshak main us bhalai ka muhtaaj hoon jo Tu mere liye nazil farmaaye.',
        'source': 'Quran 28:24',
      },
      // Ayyub
      {
        'prophet': 'Prophet Ayyub (عليه السلام)',
        'title': 'Dua in Times of Hardship',
        'arabic':
            'أَنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ',
        'transliteration': 'Anni massaniyad-durru wa anta arhamur-rahimeen',
        'english':
            'Indeed, adversity has touched me, and You are the Most Merciful of the merciful.',
        'romanUrdu':
            'Beshak mujhe takleef pahunchi hai aur Tu sab rahm karne walon se zyada rahm karne wala hai.',
        'source': 'Quran 21:83',
      },
      // Zakariyya
      {
        'prophet': 'Prophet Zakariyya (عليه السلام)',
        'title': 'Dua for a Righteous Heir',
        'arabic':
            'رَبِّ لَا تَذَرْنِي فَرْدًا وَأَنتَ خَيْرُ الْوَارِثِينَ',
        'transliteration': 'Rabbi la tadharni fardan wa anta khayrul warithin',
        'english':
            'My Lord, do not leave me alone without an heir, and You are the best of inheritors.',
        'romanUrdu':
            'Ae mere Rabb, mujhe akela mat chhod aur Tu sab se behtar waris hai.',
        'source': 'Quran 21:89',
      },
      {
        'prophet': 'Prophet Zakariyya (عليه السلام)',
        'title': 'Dua for a Pure Offspring',
        'arabic':
            'رَبِّ هَبْ لِي مِن لَّدُنكَ ذُرِّيَّةً طَيِّبَةً ۖ إِنَّكَ سَمِيعُ الدُّعَاءِ',
        'transliteration':
            "Rabbi hab li milladunka dhurriyyatan tayyibah innaka samee'ud-du'a",
        'english':
            'My Lord, grant me from Yourself a good offspring. Indeed, You are the Hearer of supplication.',
        'romanUrdu':
            'Ae mere Rabb, apni taraf se mujhe paak aulaad ata farma. Beshak Tu dua sunne wala hai.',
        'source': 'Quran 3:38',
      },
      // Sulayman
      {
        'prophet': 'Prophet Sulayman (عليه السلام)',
        'title': 'Dua of Gratitude',
        'arabic':
            'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَىٰ وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ',
        'transliteration':
            "Rabbi awzi'ni an ashkura ni'matakal-lati an'amta 'alayya wa 'ala walidayya wa an a'mala salihan tardah",
        'english':
            'My Lord, enable me to be grateful for Your favour which You have bestowed upon me and upon my parents, and to do righteousness of which You approve.',
        'romanUrdu':
            "Ae mere Rabb, mujhe toufeeq de ke main teri us ne'mat ka shukar ada karun jo tu ne mujhe aur mere walidain ko di aur nek amal karun jo tujhe pasand ho.",
        'source': 'Quran 27:19',
      },
      {
        'prophet': 'Prophet Sulayman (عليه السلام)',
        'title': 'Dua for Truthful Entry and Exit',
        'arabic':
            'رَبِّ أَدْخِلْنِي مُدْخَلَ صِدْقٍ وَأَخْرِجْنِي مُخْرَجَ صِدْقٍ وَاجْعَل لِّي مِن لَّدُنكَ سُلْطَانًا نَّصِيرًا',
        'transliteration':
            "Rabbi adkhilni mudkhala sidqin wa akhrijnee mukhraja sidqin waj'al li milladunka sultanan nasira",
        'english':
            'My Lord, cause me to enter an entry of truth and to exit an exit of truth and grant me from You a supporting authority.',
        'romanUrdu':
            'Ae mere Rabb, mujhe sachche daakhle se daakhil kar aur sachche khurooj se baahir kar aur apni taraf se mujhe madad karne wali quwwat ata farma.',
        'source': 'Quran 17:80',
      },
      // Isa
      {
        'prophet': 'Prophet Isa (عليه السلام)',
        'title': 'Dua for a Table Spread from Heaven',
        'arabic':
            'اللَّهُمَّ رَبَّنَا أَنزِلْ عَلَيْنَا مَائِدَةً مِّنَ السَّمَاءِ تَكُونُ لَنَا عِيدًا',
        'transliteration':
            "Allahumma Rabbana anzil 'alayna ma'idatam minas-sama'i takunu lana 'eeda",
        'english':
            'O Allah, our Lord, send down to us a table from the sky that will be for us a festival.',
        'romanUrdu':
            'Ae Allah, hamare Rabb, hamare liye aasmaan se ek dastarkhwaan nazil farma jo hamare liye eid ho.',
        'source': 'Quran 5:114',
      },
      // Lut
      {
        'prophet': 'Prophet Lut (عليه السلام)',
        'title': 'Dua for Victory Over Wrongdoers',
        'arabic': 'رَبِّ انصُرْنِي عَلَى الْقَوْمِ الْمُفْسِدِينَ',
        'transliteration': 'Rabbinsurni alal-qawmil mufsideen',
        'english': 'My Lord, support me against the corrupting people.',
        'romanUrdu':
            'Ae mere Rabb, fasaad phailane wali qaum ke khilaf meri madad farma.',
        'source': 'Quran 29:30',
      },
      // Muhammad ﷺ
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': 'Dua for Steadfastness of the Heart',
        'arabic':
            'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
        'transliteration': 'Ya muqallibal-qulubi thabbit qalbi ala dinik',
        'english':
            'O Turner of hearts, make my heart firm upon Your religion.',
        'romanUrdu':
            'Ae dilon ko palat dene wale, mere dil ko apne deen par sabit farma.',
        'source': 'Sunan Tirmidhi 3522',
      },
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': 'Dua for Beneficial Knowledge',
        'arabic':
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
        'transliteration':
            "Allahumma inni as'aluka 'ilman nafi'an wa rizqan tayyiban wa 'amalan mutaqabbala",
        'english':
            'O Allah, I ask You for beneficial knowledge, good provision, and accepted deeds.',
        'romanUrdu':
            'Ae Allah, main tujh se nafa bakhsh ilm, paak rizq aur qabool shuda amal maangta hoon.',
        'source': 'Sunan Ibn Majah 925',
      },
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': 'Dua for Anxiety and Grief',
        'arabic':
            'اللَّهُمَّ إِنِّي عَبْدُكَ ابْنُ عَبْدِكَ ابْنُ أَمَتِكَ نَاصِيَتِي بِيَدِكَ مَاضٍ فِيَّ حُكْمُكَ عَدْلٌ فِيَّ قَضَاؤُكَ',
        'transliteration':
            "Allahumma inni 'abduka wabnu 'abdika wabnu amatika nasiyati biyadika madin fiyya hukmuka 'adlun fiyya qada'uk",
        'english':
            'O Allah, I am Your servant, son of Your servant, son of Your handmaid. My forelock is in Your hand, Your command over me is forever executed, and Your decree over me is just.',
        'romanUrdu':
            'Ae Allah, main tera banda hoon, tere bande ka beta hoon, teri bandhi ka beta hoon. Meri peshaani tere haath mein hai, mujh par tera hukm jaari hai, mujh par tera faisla adl hai.',
        'source': 'Musnad Ahmad 3704',
      },
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': 'Dua Before Sleeping',
        'arabic': 'اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا',
        'transliteration': 'Allahumma bismika amutu wa ahya',
        'english': 'O Allah, in Your name I die and I live.',
        'romanUrdu':
            'Ae Allah, tere naam ke saath marta hoon aur tere naam ke saath jeeta hoon.',
        'source': 'Sahih Bukhari 6324',
      },
      {
        'prophet': 'Prophet Muhammad ﷺ',
        'title': 'Dua for Rectification of Religion and World',
        'arabic':
            'اللَّهُمَّ أَصْلِحْ لِي دِينِيَ الَّذِي هُوَ عِصْمَةُ أَمْرِي وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي',
        'transliteration':
            "Allahumma aslih li dini alladhi huwa 'ismatu amri wa aslih li dunyaya allati fiha ma'ashi",
        'english':
            'O Allah, set right for me my religion which is the safeguard of my affairs, and set right for me my worldly life in which is my livelihood.',
        'romanUrdu':
            'Ae Allah, mere deen ko durust kar jo mere saare kamon ki hifaazat ka zariya hai, aur meri duniya ko durust kar jis mein mera guzaara hai.',
        'source': 'Sahih Muslim 2720',
      },
    ],
  },
  // ── 2. Daily Duas (10 duas) ─────────────────────────────────
  {
    'id': 'daily',
    'name': 'Daily Duas',
    'emoji': '☀️',
    'watermark': 'اليومية',
    'hasProphetSections': false,
    'duas': [
      {
        'title': 'Dua When Waking Up',
        'arabic':
            'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        'transliteration':
            "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
        'english':
            'All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.',
        'romanUrdu':
            'Tamam taareef Allah ke liye hai jis ne hamen maut dene ke baad zindagi di aur usi ki taraf uthna hai.',
        'source': 'Sahih Bukhari 6312',
      },
      {
        'title': 'Dua Before Eating',
        'arabic': 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
        'transliteration': "Bismillahi wa 'ala barakatillah",
        'english': 'In the name of Allah and with the blessings of Allah.',
        'romanUrdu': 'Allah ke naam se aur Allah ki barkat ke saath.',
        'source': 'Sunan Abu Dawud 3767',
      },
      {
        'title': 'Dua After Eating',
        'arabic':
            'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
        'transliteration':
            'Alhamdu lillahil-ladhi at-amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah',
        'english':
            'Praise be to Allah who fed me this and provided it for me without any effort or power on my part.',
        'romanUrdu':
            'Shukar hai Allah ka jis ne mujhe yeh khaana khilaya aur bina mere kisi zor aur taqat ke rizq diya.',
        'source': 'Sunan Tirmidhi 3458',
      },
      {
        'title': 'Dua When Entering the Home',
        'arabic':
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا',
        'transliteration':
            "Allahumma inni as'aluka khayral mawliji wa khayral makhraj bismillahi walajna wa bismillahi kharajna",
        'english':
            'O Allah, I ask You for the good of entering and the good of leaving. In the name of Allah we enter and in the name of Allah we leave.',
        'romanUrdu':
            'Ae Allah, main tujh se dakhle ki bhalai aur bahar nikalne ki bhalai maangta hoon. Allah ke naam se hum daakhil hue aur Allah ke naam se hum nikal jaayenge.',
        'source': 'Sunan Abu Dawud 5096',
      },
      {
        'title': 'Dua When Leaving the Home',
        'arabic':
            'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        'transliteration':
            'Bismillahi tawakkaltu alallahi wa la hawla wa la quwwata illa billah',
        'english':
            'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.',
        'romanUrdu':
            'Allah ke naam se, maine Allah par bharosa kiya aur koi taqat aur koi zor nahi siwaay Allah ke.',
        'source': 'Sunan Tirmidhi 3426',
      },
      {
        'title': 'Dua Before Entering the Masjid',
        'arabic': 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        'transliteration': "Allahummaf-tah li abwaba rahmatik",
        'english': 'O Allah, open for me the doors of Your mercy.',
        'romanUrdu': 'Ae Allah, mere liye apni rehmat ke darwaaze khol de.',
        'source': 'Sahih Muslim 713',
      },
      {
        'title': 'Dua When Leaving the Masjid',
        'arabic': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
        'transliteration': "Allahumma inni as'aluka min fadlik",
        'english': 'O Allah, I ask You of Your bounty.',
        'romanUrdu': 'Ae Allah, main tujh se tere fazl ka sawaali hoon.',
        'source': 'Sahih Muslim 713',
      },
      {
        'title': 'Dua When Entering the Bathroom',
        'arabic':
            'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
        'transliteration':
            "Allahumma inni a'udhu bika minal-khubuthi wal-khaba'ith",
        'english': 'O Allah, I seek refuge with You from evil and the evil ones.',
        'romanUrdu':
            'Ae Allah, main tujh se napaak jinnat mardon aur napaak jinnat aurton se panaah maangta hoon.',
        'source': 'Sahih Bukhari 142',
      },
      {
        'title': 'Dua When Looking in the Mirror',
        'arabic':
            'اللَّهُمَّ أَنْتَ حَسَّنْتَ خَلْقِي فَحَسِّنْ خُلُقِي',
        'transliteration': 'Allahumma anta hassanta khalqi fahassin khuluqi',
        'english':
            'O Allah, You have made my physical form beautiful, so make my character beautiful too.',
        'romanUrdu':
            'Ae Allah, tu ne meri soorat achhi banayi, toh meri seerat bhi achhi bana de.',
        'source': 'Musnad Ahmad 3823',
      },
      {
        'title': 'Dua Before Sleeping',
        'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        'transliteration': 'Bismika Allahumma amutu wa ahya',
        'english': 'In Your name, O Allah, I die and I live.',
        'romanUrdu':
            'Ae Allah, tere naam ke saath main marta hoon aur tere naam ke saath jeeta hoon.',
        'source': 'Sahih Bukhari 6324',
      },
    ],
  },
  // ── 3. Quranic Duas (7 duas) ────────────────────────────────
  {
    'id': 'quranic',
    'name': 'Quranic Duas',
    'emoji': '📖',
    'watermark': 'القرآن',
    'hasProphetSections': false,
    'duas': [
      {
        'title': 'Dua for Good in Both Worlds',
        'arabic':
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        'transliteration':
            "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-naar",
        'english':
            'Our Lord, give us good in this world and good in the Hereafter, and save us from the punishment of the Fire.',
        'romanUrdu':
            'Ae hamare Rabb, hamen dunya mein bhalai de aur aakhirat mein bhalai de aur hamen jahannam ke azaab se bacha.',
        'source': 'Quran 2:201',
      },
      {
        'title': 'Dua for Increase in Knowledge',
        'arabic': 'رَّبِّ زِدْنِي عِلْمًا',
        'transliteration': "Rabbi zidni 'ilma",
        'english': 'My Lord, increase me in knowledge.',
        'romanUrdu': 'Ae mere Rabb, mujhe ilm mein izaafa farma.',
        'source': 'Quran 20:114',
      },
      {
        'title': 'Dua for Mercy and Guidance',
        'arabic':
            'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً',
        'transliteration':
            "Rabbana la tuzigh qulobana ba'da idh hadaytana wa hab lana milladunka rahmah",
        'english':
            'Our Lord, let not our hearts deviate after You have guided us, and grant us from Yourself mercy.',
        'romanUrdu':
            'Ae hamare Rabb, hamare dilon ko terhaa mat kar baad is ke ke tu ne hamen hidayat di, aur apni taraf se hamen rehmat ata farma.',
        'source': 'Quran 3:8',
      },
      {
        'title': 'Dua for Forgiveness and Mercy',
        'arabic':
            'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
        'transliteration':
            'Rabbana zalamna anfusana wa illam taghfir lana wa tarhamna lanakunanna minal khasireen',
        'english':
            'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
        'romanUrdu':
            'Ae hamare Rabb, hum ne apne aap par zulm kiya aur agar Tu hamen maaf na kare aur hum par raham na kare to hum yaqeenan ghaate walon mein se honge.',
        'source': 'Quran 7:23',
      },
      {
        'title': 'Dua for Parents',
        'arabic': 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
        'transliteration': 'Rabbir-hamhuma kama rabbayani saghira',
        'english':
            'My Lord, have mercy upon them as they brought me up when I was small.',
        'romanUrdu':
            'Ae mere Rabb, un par raham farma jaise unhon ne mujhe bachpan mein pala.',
        'source': 'Quran 17:24',
      },
      {
        'title': 'Dua for Guidance to the Right Path',
        'arabic':
            'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
        'transliteration':
            'Rabbana atina milladunka rahmatan wa hayyi lana min amrina rashada',
        'english':
            'Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance.',
        'romanUrdu':
            'Ae hamare Rabb, apni taraf se hamen rehmat ata farma aur hamare kaam mein hamare liye seedh ka intizaam farma.',
        'source': 'Quran 18:10',
      },
      {
        'title': 'Dua for Steadfastness in Battle',
        'arabic':
            'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
        'transliteration':
            "Rabbana afrigh 'alayna sabran wa thabbit aqdamana wansurna 'alal-qawmil kafireen",
        'english':
            'Our Lord, pour upon us patience and plant firmly our feet and give us victory over the disbelieving people.',
        'romanUrdu':
            'Ae hamare Rabb, hum par sabr daal de aur hamare qadam mazbut kar de aur kaafir qaum ke khilaf hamari madad farma.',
        'source': 'Quran 2:250',
      },
    ],
  },
  // ── 4. Special Occasions (5 duas) ──────────────────────────
  {
    'id': 'occasions',
    'name': 'Special Occasions',
    'emoji': '⭐',
    'watermark': 'المناسبات',
    'hasProphetSections': false,
    'duas': [
      {
        'title': 'Dua for Laylatul Qadr',
        'arabic':
            'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
        'transliteration':
            "Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni",
        'english':
            'O Allah, You are Pardoning and You love pardon, so pardon me.',
        'romanUrdu':
            'Ae Allah, Tu maaf karne wala hai aur maafi ko pasand karta hai, pas mujhe maaf farma de.',
        'source': 'Sunan Ibn Majah 3850',
      },
      {
        'title': 'Dua for Breaking Fast (Iftar)',
        'arabic':
            'اللَّهُمَّ لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ',
        'transliteration':
            "Allahumma laka sumtu wa bika amantu wa 'alayka tawakkaltu wa 'ala rizqika aftart",
        'english':
            'O Allah, I fasted for You and I believe in You and I put my trust in You and I break my fast with Your sustenance.',
        'romanUrdu':
            'Ae Allah, maine tere liye roza rakha aur tujh par imaan laya aur tujh par bharosa kiya aur tere rizq se iftaar kiya.',
        'source': 'Sunan Abu Dawud 2358',
      },
      {
        'title': 'Dua on the Day of Arafah',
        'arabic':
            'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        'transliteration':
            'La ilaha illallahu wahdahu la sharika lah lahul-mulku wa lahul-hamdu wa huwa ala kulli shay in qadir',
        'english':
            'There is no god but Allah alone, He has no partner, His is the dominion and His is the praise, and He has power over everything.',
        'romanUrdu':
            'Allah ke siwa koi ilaah nahi, akela hai, uska koi shareek nahi, usi ki badshaahi hai aur usi ki taareef hai aur woh har cheez par qadir hai.',
        'source': 'Sunan Tirmidhi 3585',
      },
      {
        'title': 'Dua When Visiting the Sick',
        'arabic':
            'أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَكَ',
        'transliteration':
            "As'alullaahal-'azeema rabbal-'arshil-'azeemi an yashfiyak",
        'english':
            'I ask Allah, the Mighty, the Lord of the Mighty Throne, to cure you.',
        'romanUrdu':
            'Main Allah azeem se jo arsh azeem ka Rabb hai dua karta hoon ke woh tujhe shifa de.',
        'source': 'Sunan Abu Dawud 3106',
      },
      {
        'title': 'Dua When it Rains',
        'arabic': 'اللَّهُمَّ صَيِّبًا نَافِعًا',
        'transliteration': "Allahumma sayyiban nafi'a",
        'english': 'O Allah, make it a beneficial rain.',
        'romanUrdu': 'Ae Allah, ise nafa bakhsh baarish bana.',
        'source': 'Sahih Bukhari 1032',
      },
    ],
  },
  // ── 5. Success & Protection (5 duas) ───────────────────────
  {
    'id': 'protection',
    'name': 'Success & Protection',
    'emoji': '🛡️',
    'watermark': 'الحماية',
    'hasProphetSections': false,
    'duas': [
      {
        'title': 'Dua for Protection from Evil Eye',
        'arabic':
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        'transliteration':
            "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
        'english':
            'I seek refuge in the perfect words of Allah from the evil of what He has created.',
        'romanUrdu':
            'Main Allah ke kaamil kalimat ki panaah maangta hoon us ki tamam makhluq ki burai se.',
        'source': 'Sahih Muslim 2708',
      },
      {
        'title': 'Dua for Debt Relief',
        'arabic':
            'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
        'transliteration':
            "Allahumma-kfini bihalaalika 'an haramika wa aghnini bifadlika 'amman siwak",
        'english':
            'O Allah, suffice me with what You have made lawful so that I have no need of what You have made unlawful, and make me independent of all those other than You by Your grace.',
        'romanUrdu':
            'Ae Allah, apne halaal se mujhe apne haraam se be-niyaaz farma aur apne fazl se mujhe apne siwa sab se be-niyaaz farma.',
        'source': 'Sunan Tirmidhi 3563',
      },
      {
        'title': 'Dua for Ease in Affairs',
        'arabic': 'رَبِّ يَسِّرْ وَلَا تُعَسِّرْ وَتَمِّمْ بِالْخَيْرِ',
        'transliteration': "Rabbi yassir wa la tu'assir wa tammim bil-khayr",
        'english':
            'My Lord, make things easy and do not make them difficult, and complete things with goodness.',
        'romanUrdu':
            'Ae mere Rabb, aasaan farma aur mushkil mat bana aur bhalai ke saath mukammal farma.',
        'source': 'Athari — widely reported supplication',
      },
      {
        'title': 'Dua for Morning Protection',
        'arabic':
            'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
        'transliteration':
            'Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namutu wa ilaykan-nushur',
        'english':
            'O Allah, by You we have entered the morning, by You we have entered the evening, by You we live and by You we die, and unto You is the resurrection.',
        'romanUrdu':
            'Ae Allah, tere zariye hum ne subah ki aur tere zariye hum ne shaam ki, tere zariye hum jeete hain aur tere zariye hum marte hain aur tere paas hi uthna hai.',
        'source': 'Sunan Tirmidhi 3391',
      },
      {
        'title': 'Dua for Protection from Shaytan',
        'arabic':
            'أَعُوذُ بِاللَّهِ السَّمِيعِ الْعَلِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        'transliteration':
            "A'udhu billahis-samee'il-'aleemi minash-shaytanir-rajeem",
        'english':
            'I seek refuge in Allah, the All-Hearing, the All-Knowing, from the accursed devil.',
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
    for (final cat in duasCategories) {
      final catName = cat['name'] as String;
      for (final dua in cat['duas'] as List<dynamic>) {
        final d = dua as Map<String, dynamic>;
        final matchTitle = (d['title'] as String).toLowerCase().contains(q);
        final matchArabic = (d['arabic'] as String).contains(_query);
        final matchEng = (d['english'] as String).toLowerCase().contains(q);
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
          'Duas',
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
                        'No duas found',
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
            hintText: 'Search duas in any language…',
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
    final preview1 =
        count > 0 ? (duas[0] as Map<String, dynamic>)['title'] as String : '';
    final preview2 =
        count > 1 ? (duas[1] as Map<String, dynamic>)['title'] as String : '';
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
                        Text(
                          category['emoji'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['name'] as String,
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
                                  '$count Duas',
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
            Text(
              category['emoji'] as String,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              category['name'] as String,
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
                          '$count ${count == 1 ? 'Dua' : 'Duas'}',
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
    final text =
        '${d['arabic']}\n\n${d['transliteration']}\n\n${d['english']}\n\n${d['romanUrdu']}\n\nSource: ${d['source']}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Dua copied to clipboard'),
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
    final String title = d['title'] as String;
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
                      _SectionLabel(label: 'English'),
                      const SizedBox(height: 4),
                      Text(
                        d['english'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.text2,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 4. Roman Urdu translation
                      _SectionLabel(label: 'Roman Urdu'),
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
                                children: const [
                                  Icon(Icons.copy_outlined,
                                      size: 12, color: AppColors.gold),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
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
