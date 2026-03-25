import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/book_download_service.dart';

class BookLanguageScreen extends StatefulWidget {
  const BookLanguageScreen({super.key});

  @override
  State<BookLanguageScreen> createState() => _BookLanguageScreenState();
}

class _BookLanguageScreenState extends State<BookLanguageScreen> {
  String _selected = 'en';

  Future<void> _confirm() async {
    await context.read<BookDownloadService>().setLanguage(_selected);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('books_language_set', true);
    if (mounted) Navigator.pop(context);
  }

  static const _langs = [
    (
      code: 'en',
      name: 'English',
      desc: 'Read in English',
      sample: 'Narrated by Abu Hurairah: The Prophet said, "Actions are judged by intentions..."',
      rtl: false,
    ),
    (
      code: 'ar',
      name: 'العربية',
      desc: 'اللغة العربية',
      sample: 'حَدَّثَنَا عُمَرُ بْنُ الْخَطَّابِ، قَالَ: سَمِعْتُ رَسُولَ اللَّهِ ﷺ يَقُولُ...',
      rtl: true,
    ),
    (
      code: 'ur',
      name: 'اردو',
      desc: 'اردو میں پڑھیں',
      sample: 'ابوہریرہ رضی اللہ عنہ سے روایت ہے: نبی کریم ﷺ نے فرمایا، اعمال کا دارومدار نیتوں پر ہے...',
      rtl: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final langLabel = _langs.firstWhere((l) => l.code == _selected).name;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        size: 18, color: context.textDim),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('Islamic Books',
                      style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          color: context.text)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose your reading language',
                        style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: context.text)),
                    const SizedBox(height: 8),
                    Text(
                        'Which language would you like to read in? You can change this anytime.',
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'sans-serif',
                            color: context.textDim)),
                    const SizedBox(height: 24),
                    // Language cards
                    ...(_langs.map((lang) {
                      final selected = _selected == lang.code;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = lang.code),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.goldDim.withOpacity(0.08)
                                : context.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppColors.gold : context.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Radio dot
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.gold
                                        : context.border,
                                    width: selected ? 5 : 1.5,
                                  ),
                                  color: selected
                                      ? AppColors.gold
                                      : Colors.transparent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lang.name,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: context.text,
                                            fontFamily: lang.rtl
                                                ? 'Scheherazade'
                                                : null)),
                                    const SizedBox(height: 2),
                                    Text(lang.desc,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: context.textDim,
                                            fontFamily: 'sans-serif')),
                                    const SizedBox(height: 8),
                                    Text(lang.sample,
                                        textDirection: lang.rtl
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                        style: TextStyle(
                                            fontSize: lang.rtl ? 13 : 11,
                                            fontStyle: lang.rtl
                                                ? FontStyle.normal
                                                : FontStyle.italic,
                                            fontFamily: lang.rtl
                                                ? 'Scheherazade'
                                                : 'sans-serif',
                                            color: context.textDim,
                                            height: 1.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })),
                    const Spacer(),
                    Text(
                      'You can change this anytime in Settings › Islamic Books',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'sans-serif',
                          color: context.textDim),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Continue in $langLabel',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
