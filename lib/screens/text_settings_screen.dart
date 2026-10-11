import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/language.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

// ── Public entry-point ─────────────────────────────────────────────────────────

/// Show the Text Settings bottom sheet from any context.
void showTextSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: const TextSettingsSheet(),
    ),
  );
}

class TextSettingsSheet extends StatelessWidget {
  const TextSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      return Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: context.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 4),
            child: Row(children: [
              Text(
                L.of(context).textSettings,
                style: TextStyle(
                  color: context.text,
                  fontSize: 17,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: QIcon.close(size: 20, color: context.textDim),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          // Scrollable content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Reading mode ──────────────────────────────────────────
                  _SheetLabel(L.of(context).readerSectionReadingMode),
                  const SizedBox(height: 8),
                  _ReadingModeChips(state: state),
                  const SizedBox(height: 16),

                  // ── Live preview ──────────────────────────────────────────
                  _SheetLabel(L.of(context).textSettingsSectionLivePreview),
                  const SizedBox(height: 8),
                  _LivePreview(state: state),
                  const SizedBox(height: 16),

                  // ── Swipe navigation ──────────────────────────────────────
                  _SheetLabel(L.of(context).textSettingsSectionSwipeNavigation),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    title: L.of(context).textSettingsSwipeBetweenSurahs,
                    subtitle:
                        L.of(context).textSettingsSwipeBetweenSurahsSubtitle,
                    value: state.swipeEnabled,
                    onChanged: (_) => state.toggleSwipeEnabled(),
                  ),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    title: L.of(context).textSettingsShowSurahNameStrip,
                    subtitle:
                        L.of(context).textSettingsShowSurahNameStripSubtitle,
                    value: state.showSurahHints,
                    onChanged: (_) => state.toggleShowSurahHints(),
                  ),
                  const SizedBox(height: 16),

                  // ── Font size ─────────────────────────────────────────────
                  _SheetLabel(L.of(context).textSettingsSectionFontSize),
                  const SizedBox(height: 8),
                  _FontSizeRow(state: state),
                  const SizedBox(height: 16),

                  // ── Translation language ──────────────────────────────────
                  _SheetLabel(
                      L.of(context).textSettingsSectionTranslationLanguage),
                  const SizedBox(height: 8),
                  _TranslationLanguageRow(state: state),
                ],
              ),
            ),
          ),
        ]),
      );
    });
  }
}

// ── Reading mode chips ─────────────────────────────────────────────────────────

class _ReadingModeChips extends StatelessWidget {
  final AppState state;
  const _ReadingModeChips({required this.state});

  @override
  Widget build(BuildContext context) {
    // Not const: the labels are resolved from the active locale.
    final chips = [
      (1, L.of(context).readerModeTranslation),
      (2, L.of(context).readerModeArabicPlus),
      (3, L.of(context).readerModeRoman),
    ];
    return Row(
      children: chips.map((chip) {
        final mode = chip.$1;
        final label = chip.$2;
        final sel = state.displayReadingMode == mode;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => state.setDisplayReadingMode(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.goldDim.withOpacity(0.12)
                    : context.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppColors.gold : context.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'sans-serif',
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  color: sel ? AppColors.gold : context.textDim,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Live preview ───────────────────────────────────────────────────────────────

class _LivePreview extends StatelessWidget {
  final AppState state;
  const _LivePreview({required this.state});

  static const _sampleArabic =
      'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';

  // The transliteration and translation samples are localised, so they are
  // resolved per-build rather than held in static consts.
  static String _sampleTranslit(BuildContext context) =>
      L.of(context).textSettingsPreviewTransliteration;
  static String _sampleTranslation(BuildContext context) =>
      L.of(context).textSettingsPreviewTranslation;

  @override
  Widget build(BuildContext context) {
    final mode = state.displayReadingMode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Verse number pill
        Row(children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldFaint.withOpacity(0.5),
              border: Border.all(color: AppColors.lightBorder2),
            ),
            child: const Center(
              child: Text(
                '2',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.gold,
                  fontFamily: 'sans-serif',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 6),

        // Arabic
        if (mode >= 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _sampleArabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Scheherazade',
                fontSize: state.arabicFontSize.clamp(20.0, 40.0),
                color: context.arabic,
                height: 2.0,
              ),
            ),
          ),

        // Transliteration
        if (mode >= 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _sampleTranslit(context),
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: state.translitFontSize,
                fontStyle: FontStyle.italic,
                color: context.translit,
                height: 1.5,
              ),
            ),
          ),

        // Translation
        Text(
          _sampleTranslation(context),
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: state.readingFontSize,
            color: context.urduText,
            height: 1.5,
          ),
        ),
      ]),
    );
  }
}

// ── Font size row ──────────────────────────────────────────────────────────────

class _FontSizeRow extends StatelessWidget {
  final AppState state;
  const _FontSizeRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Row(children: [
        // A− button
        GestureDetector(
          onTap: () => state.setReadingFontSize(state.readingFontSize - 1),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.border),
            ),
            child: Center(
              child: Text(
                L.of(context).textSettingsFontSizeDecrease,
                style: TextStyle(
                  fontSize: 13,
                  color: context.text,
                  fontFamily: 'sans-serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // Slider
        Expanded(
          child: Slider(
            value: state.readingFontSize,
            min: 12,
            max: 20,
            divisions: 8,
            activeColor: AppColors.gold,
            inactiveColor: context.border,
            onChanged: state.setReadingFontSize,
          ),
        ),

        // A+ button
        GestureDetector(
          onTap: () => state.setReadingFontSize(state.readingFontSize + 1),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.border),
            ),
            child: Center(
              child: Text(
                L.of(context).textSettingsFontSizeIncrease,
                style: TextStyle(
                  fontSize: 13,
                  color: context.text,
                  fontFamily: 'sans-serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Translation language row ───────────────────────────────────────────────────

class _TranslationLanguageRow extends StatelessWidget {
  final AppState state;
  const _TranslationLanguageRow({required this.state});

  void _openLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: _LanguagePickerSheet(currentCode: state.langCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openLanguagePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.currentLanguage.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.text,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.currentLanguage.nativeName,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textDim,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.textDim, size: 20),
        ]),
      ),
    );
  }
}

// ── Inline language picker sheet ───────────────────────────────────────────────

class _LanguagePickerSheet extends StatelessWidget {
  final String currentCode;
  const _LanguagePickerSheet({required this.currentCode});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      return Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: context.border),
        ),
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            L.of(context).translationLanguage,
            style: TextStyle(
              color: context.text,
              fontSize: 17,
              fontFamily: 'serif',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: ListView.builder(
              itemCount: kLanguages.length,
              itemBuilder: (ctx, i) {
                final lang = kLanguages[i];
                final selected = state.langCode == lang.code;
                return GestureDetector(
                  onTap: () {
                    state.setLanguage(lang.code);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.goldDim.withOpacity(0.1)
                          : context.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.gold : context.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected
                                    ? AppColors.gold
                                    : context.text,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              lang.nativeName,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textDim,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        QIcon.check(size: 16, color: AppColors.gold),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      );
    });
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 2,
        color: context.textDim,
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 14, color: context.text)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: context.textDim,
                      fontFamily: 'sans-serif')),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.gold,
        ),
      ]),
    );
  }
}
