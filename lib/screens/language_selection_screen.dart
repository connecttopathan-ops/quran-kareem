import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/language.dart';
import '../theme/app_theme.dart';
import '../data/first_verse_translations.dart';
import '../widgets/q_icons.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  // Roman Urdu is always pinned at the top of the list.
  static const _pinnedCode = 'ur-roman';
  static final _pinnedLang =
      kLanguages.firstWhere((l) => l.code == _pinnedCode);

  late String _selectedCode;
  String _query = '';
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _didAutoScroll = false;

  @override
  void initState() {
    super.initState();
    _selectedCode = _detectLocaleCode();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Maps the device locale to the closest available language code.
  /// Falls back to Roman Urdu (the app's primary language) if no match.
  String _detectLocaleCode() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final lang = locale.languageCode.toLowerCase();

    // Direct match
    if (kLanguages.any((l) => l.code == lang)) return lang;

    // Known remappings
    switch (lang) {
      case 'nb':
      case 'nn':
        return 'no'; // Norwegian variants
      case 'in':
        return 'id'; // Old Indonesian BCP-47 code
      case 'iw':
      case 'he':
        return 'ar'; // Hebrew → Arabic (closest available)
      case 'jw':
      case 'jv':
        return 'id'; // Javanese → Indonesian
      case 'tl':
      case 'fil':
        return 'en'; // Filipino → English
      case 'uz':
        return 'ur'; // Uzbek → Urdu
      case 'kk':
      case 'ky':
        return 'ru'; // Kazakh / Kyrgyz → Russian
    }

    return _pinnedCode; // fall back to Roman Urdu
  }

  /// After the first frame, scroll so the auto-detected language is centred.
  /// Only runs once and only when not searching.
  void _maybeAutoScroll(List<dynamic> items) {
    if (_didAutoScroll || _selectedCode == _pinnedCode) return;
    if (!_scrollCtrl.hasClients) return;
    _didAutoScroll = true;

    const tileH   = 136.0; // approx tile height + bottom margin
    const headerH =  42.0; // approx group-header height

    double offset = 10.0; // list top padding
    for (final item in items) {
      if (item is String) {
        offset += headerH;
      } else if ((item as Language).code == _selectedCode) {
        break;
      } else {
        offset += tileH;
      }
    }

    final maxExt  = _scrollCtrl.position.maxScrollExtent;
    final viewport = _scrollCtrl.position.viewportDimension;
    final target  = (offset - viewport / 2 + tileH / 2).clamp(0.0, maxExt);

    _scrollCtrl.animateTo(target,
        duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
  }

  Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    await prefs.setString('langCode', _selectedCode);
    if (mounted) {
      context.read<AppState>().setLanguage(_selectedCode);
      Navigator.pop(context);
    }
  }

  // ── Tile builder ────────────────────────────────────────────────────────────

  Widget _buildTile(Language lang, {bool pinned = false}) {
    final selected = _selectedCode == lang.code;
    final preview =
        kBismillahTranslations[lang.code] ?? kBismillahTranslations['en']!;
    final isRtl = lang.isRtl;

    return GestureDetector(
      onTap: () => setState(() => _selectedCode = lang.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: pinned ? 0 : 8),
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
        child: Column(
          crossAxisAlignment:
              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ── Name row ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment:
                  isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (pinned) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.gold.withOpacity(0.35)),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.gold,
                        fontFamily: 'sans-serif',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
                Text(
                  lang.name,
                  style: TextStyle(
                    color: selected ? AppColors.gold : context.text,
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
                  const Icon(Icons.check_circle,
                      color: AppColors.gold, size: 16),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // ── Arabic ───────────────────────────────────────────────────
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Scheherazade',
                fontSize: 17,
                color: selected ? AppColors.gold : context.arabic,
              ),
            ),
            const SizedBox(height: 4),
            // ── Transliteration ──────────────────────────────────────────
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
            // ── Translation preview ──────────────────────────────────────
            Text(
              preview,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;

    // When searching: include all languages (Roman Urdu appears in results too).
    // When not searching: exclude Roman Urdu from the grouped list — it's pinned above.
    final filtered = searching
        ? kLanguages
            .where((l) =>
                l.name.toLowerCase().contains(_query.toLowerCase()) ||
                l.nativeName.toLowerCase().contains(_query.toLowerCase()))
            .toList()
        : kLanguages.where((l) => l.code != _pinnedCode).toList();

    // Build flat list with group-header strings interleaved.
    final items = <dynamic>[];
    String? currentGroup;
    for (final lang in filtered) {
      if (lang.group != currentGroup) {
        currentGroup = lang.group;
        items.add(currentGroup);
      }
      items.add(lang);
    }

    // Auto-scroll once to the locale-detected selection.
    if (!searching) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeAutoScroll(items));
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + search ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
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
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: context.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search language...',
                      hintStyle:
                          TextStyle(color: context.textDim, fontSize: 13),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(11),
                        child:
                            QIcon.search(size: 17, color: context.textDim),
                      ),
                      suffixIcon: searching
                          ? IconButton(
                              icon: QIcon.close(
                                  size: 16, color: context.textDim),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _query = '';
                                  _didAutoScroll = false;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.gold),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() {
                      _query = v;
                      if (v.isNotEmpty) _didAutoScroll = false;
                    }),
                  ),
                ],
              ),
            ),

            // ── Pinned Roman Urdu (hidden while searching) ─────────────────
            if (!searching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTile(_pinnedLang, pinned: true),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(children: [
                  Expanded(child: Divider(color: context.border, height: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'ALL LANGUAGES',
                      style: TextStyle(
                        color: context.textDim,
                        fontSize: 9,
                        letterSpacing: 2.5,
                        fontFamily: 'sans-serif',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: context.border, height: 1)),
                ]),
              ),
            ],

            // ── Grouped / filtered language list ───────────────────────────
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'No languages found',
                        style: TextStyle(
                            color: context.textDim,
                            fontFamily: 'sans-serif'),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        if (item is String) {
                          return Padding(
                            padding:
                                const EdgeInsets.fromLTRB(4, 10, 4, 8),
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
                        return _buildTile(item as Language);
                      },
                    ),
            ),

            // ── Continue button ────────────────────────────────────────────
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
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
