import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/language.dart';
import '../models/surah.dart';
import '../services/tafsir_service.dart';
import '../theme/app_theme.dart';
import 'q_icons.dart';

// ── Public entry-point ─────────────────────────────────────────────────────────

/// Show the tafsir for one verse, with prev/next so a passage can be read
/// straight through without closing the sheet.
void showTafsirSheet(
  BuildContext context, {
  required Surah surah,
  required int verseNumber,
  required String arabic,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<AppState>()),
        ChangeNotifierProvider.value(value: context.read<TafsirService>()),
      ],
      child: TafsirSheet(
        surah: surah,
        verseNumber: verseNumber,
        arabic: arabic,
      ),
    ),
  );
}

// ── Sheet ──────────────────────────────────────────────────────────────────────

class TafsirSheet extends StatefulWidget {
  const TafsirSheet({
    super.key,
    required this.surah,
    required this.verseNumber,
    required this.arabic,
  });

  final Surah surah;
  final int verseNumber;

  /// The Arabic of the verse the sheet opened on, echoed at the top so the
  /// reader keeps their place behind the scrim. Only available for the opening
  /// verse — stepping to a neighbour shows the reference alone.
  final String arabic;

  @override
  State<TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends State<TafsirSheet> {
  late int _verse = widget.verseNumber;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final state = context.read<AppState>();
    context
        .read<TafsirService>()
        .loadForReading(state.tafsirLang, widget.surah.number);
  }

  void _step(int delta) {
    final next = _verse + delta;
    if (next < 1 || next > widget.surah.verses) return;
    setState(() => _verse = next);
  }

  Future<void> _pickLanguage() async {
    final state = context.read<AppState>();
    final l = L.of(context);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TafsirLanguagePicker(
        current: state.tafsirLangCode,
        title: l.tafsirLanguageTitle,
        followLabel: l.tafsirFollowTranslation,
      ),
    );
    if (chosen == null) return;
    await state.setTafsirLanguage(chosen);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final state = context.watch<AppState>();
    final tafsir = context.watch<TafsirService>();
    final lang = state.tafsirLang;
    final surah = widget.surah;

    final loaded = tafsir.isLoaded(lang, surah.number) &&
        (lang == 'en' || tafsir.isLoaded('en', surah.number));
    final entry = tafsir.lookup(lang, surah.number, _verse);
    final text = entry?.text;
    final viaEnglish = entry != null && entry.lang != lang;
    final langName = kLanguages
        .firstWhere((x) => x.code == lang, orElse: () => kLanguages.first)
        .nativeName;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.tafsirTitle.toUpperCase(),
                    style: TextStyle(fontSize: 7, letterSpacing: 2,
                        color: AppColors.goldDim, fontFamily: 'sans-serif')),
                const SizedBox(height: 3),
                Text('${surah.nameTransliteration} ${surah.number}:$_verse',
                    style: TextStyle(fontSize: 18, fontFamily: 'serif',
                        fontWeight: FontWeight.bold, color: context.text)),
              ]),
            ),
            IconButton(
              icon: QIcon.close(size: 18, color: context.textDim),
              tooltip: l.tafsirClose,
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),

        // Tafsir language — a third choice, independent of the reading language
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: context.surface2,
            border: Border(
              top: BorderSide(color: context.border),
              bottom: BorderSide(color: context.border),
            ),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: _pickLanguage,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold.withOpacity(0.55)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(langName,
                      style: TextStyle(fontSize: 12.5,
                          fontWeight: FontWeight.w600, color: context.text2)),
                  const SizedBox(width: 6),
                  QIcon.expand(size: 14, color: AppColors.gold),
                ]),
              ),
            ),
          ),
        ),

        // Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_verse == widget.verseNumber && widget.arabic.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border),
                  ),
                  child: Text(
                    widget.arabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Scheherazade',
                      fontSize: 19,
                      color: context.arabic,
                      height: 1.95,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              if (!loaded)
                Text(l.tafsirLoading,
                    style: TextStyle(fontSize: 13, color: context.textDim))
              else ...[
                if (viaEnglish) ...[
                  Text(l.tafsirShownInEnglish,
                      style: TextStyle(fontSize: 11, color: context.textDim)),
                  const SizedBox(height: 9),
                ],
                Text(
                  text ?? l.tafsirUnavailable,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: text == null ? 13 : state.readingFontSize + 1,
                    color: text == null ? context.textDim : context.text,
                    height: 1.75,
                  ),
                ),
              ],
            ]),
          ),
        ),

        // Source, then prev/next
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 20),
          decoration: BoxDecoration(
            color: context.surface2,
            border: Border(top: BorderSide(color: context.border)),
          ),
          child: Column(children: [
            Text(l.tafsirSource,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, height: 1.5,
                    color: context.textDim, fontFamily: 'sans-serif')),
            const SizedBox(height: 11),
            Row(children: [
              Expanded(
                child: _StepButton(
                  label: '${surah.number}:${_verse - 1}',
                  icon: QIcon.previousVerse(size: 15, color: context.textDim),
                  iconFirst: true,
                  enabled: _verse > 1,
                  onTap: () => _step(-1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepButton(
                  label: '${surah.number}:${_verse + 1}',
                  icon: QIcon.nextVerse(size: 15, color: AppColors.gold),
                  iconFirst: false,
                  enabled: _verse < surah.verses,
                  highlight: true,
                  onTap: () => _step(1),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.enabled,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final Widget icon;
  final bool iconFirst;
  final bool enabled;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      icon,
      const SizedBox(width: 7),
      Text(label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            color: highlight ? AppColors.gold : context.textDim,
          )),
    ];
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: highlight
                    ? AppColors.gold.withOpacity(0.55)
                    : context.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: iconFirst ? children : children.reversed.toList(),
          ),
        ),
      ),
    );
  }
}

// ── Language picker ────────────────────────────────────────────────────────────

class _TafsirLanguagePicker extends StatelessWidget {
  const _TafsirLanguagePicker({
    required this.current,
    required this.title,
    required this.followLabel,
  });

  final String current;
  final String title;
  final String followLabel;

  @override
  Widget build(BuildContext context) {
    final options = <(String, String)>[
      (kTafsirFollowTranslation, followLabel),
      for (final code in kTafsirLangs)
        (
          code,
          kLanguages
              .firstWhere((x) => x.code == code, orElse: () => kLanguages.first)
              .nativeName
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: context.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(title,
                  style: TextStyle(fontSize: 16, fontFamily: 'serif',
                      fontWeight: FontWeight.bold, color: context.text)),
            ),
          ),
          for (final (code, name) in options)
            InkWell(
              onTap: () => Navigator.pop(context, code),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.border)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(name,
                        style: TextStyle(fontSize: 14.5, color: context.text)),
                  ),
                  if (code == current)
                    QIcon.check(size: 17, color: AppColors.gold),
                ]),
              ),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
