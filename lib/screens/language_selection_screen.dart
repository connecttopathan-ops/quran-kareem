import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/language.dart';
import '../theme/app_theme.dart';
import '../data/first_verse_translations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedCode = 'en';

  Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    await prefs.setString('langCode', _selectedCode);
    if (mounted) {
      context.read<AppState>().setLanguage(_selectedCode);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build a flat list interleaved with group headers
    final items = <dynamic>[];
    String? currentGroup;
    for (final lang in kLanguages) {
      if (lang.group != currentGroup) {
        currentGroup = lang.group;
        items.add(currentGroup);
      }
      items.add(lang);
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your language',
                    style: TextStyle(
                      color: context.text,
                      fontSize: 22,
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select the language for Quran translations',
                    style: TextStyle(
                      color: context.textDim,
                      fontSize: 13,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ],
              ),
            ),

            // ── Language list ────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  // Group header
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                      child: Text(
                        item.toUpperCase(),
                        style: TextStyle(
                          color: context.textDim,
                          fontSize: 9,
                          letterSpacing: 2.5,
                          fontFamily: 'sans-serif',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // Language tile
                  final lang = item as Language;
                  final selected = _selectedCode == lang.code;
                  final preview = kBismillahTranslations[lang.code] ??
                      kBismillahTranslations['en']!;
                  final isRtl = lang.isRtl;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCode = lang.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.goldDim.withOpacity(0.08)
                            : context.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? AppColors.gold : context.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isRtl
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Language name row
                          Row(
                            mainAxisAlignment: isRtl
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              Text(
                                lang.name,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.gold
                                      : context.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lang.nativeName,
                                style: TextStyle(
                                  color: context.textDim,
                                  fontSize: 11,
                                  fontFamily: 'sans-serif',
                                ),
                              ),
                              if (selected) ...[
                                const Spacer(),
                                Icon(Icons.check_circle,
                                    color: AppColors.gold, size: 16),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Arabic text (line 1)
                          Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Scheherazade',
                              fontSize: 17,
                              color: selected
                                  ? AppColors.gold
                                  : context.arabic,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Roman Arabic transliteration (line 2)
                          Text(
                            'Bismillaahir Rahmaanir Raheem',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: context.translit,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Translation in selected language (line 3)
                          Text(
                            preview,
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'sans-serif',
                              color: context.text2,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Continue button ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
