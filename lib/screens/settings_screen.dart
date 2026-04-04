import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../models/language.dart';
import '../models/islamic_book.dart';
import '../widgets/q_icons.dart';
import '../services/audio_service.dart';
import '../services/book_download_service.dart';
import '../services/quran_service.dart';
import 'text_settings_screen.dart';
import 'book_language_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
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
                      Text('Settings',
                          style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 20,
                              color: context.text)),
                      const Spacer(),
                      QIcon.settings(size: 20, color: context.textDim),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _SectionHeader('Appearance'),
                      _SettingTile(
                        title: 'Dark Mode',
                        subtitle: 'Switch between light and dark theme',
                        trailing: Switch(
                          value: state.isDarkMode,
                          onChanged: (_) => state.toggleDarkMode(),
                          activeColor: AppColors.gold,
                        ),
                      ),
                      _SectionHeader('Translation'),
                      _LanguageSelector(state: state),
                      _TranslationSourceTile(),
                      _SectionHeader('Reading'),
                      _TextSettingsTile(),
                      _SettingTile(
                        title: 'Arabic Font Size',
                        subtitle: '${state.arabicFontSize.toInt()}px',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _IconBtn(
                              icon: Icons.remove,
                              onTap: () => state.setArabicFontSize(
                                  (state.arabicFontSize - 2).clamp(20, 48)),
                            ),
                            const SizedBox(width: 8),
                            _IconBtn(
                              icon: Icons.add,
                              onTap: () => state.setArabicFontSize(
                                  (state.arabicFontSize + 2).clamp(20, 48)),
                            ),
                          ],
                        ),
                      ),
                      _SettingTile(
                        title: 'Show Transliteration',
                        subtitle: 'Display Roman transliteration',
                        trailing: Switch(
                          value: state.showTranslit,
                          onChanged: (_) => state.toggleTranslit(),
                          activeColor: AppColors.gold,
                        ),
                      ),
                      _SettingTile(
                        title: 'Show Translation',
                        subtitle: 'Display translation below Arabic',
                        trailing: Switch(
                          value: state.showTranslation,
                          onChanged: (_) => state.toggleTranslation(),
                          activeColor: AppColors.gold,
                        ),
                      ),
                      _SectionHeader('Islamic Books'),
                      _IslamicBooksLanguageTile(),
                      _ManageDownloadsTile(),
                      _SectionHeader('Quran Audio'),
                      _AudioLanguageTile(),
                      _SectionHeader('Notifications'),
                      _NotificationTile(),
                      _DailyRemindersTile(),
                      _SectionHeader('About'),
                      _SettingTile(
                        title: 'Quran Kareem',
                        subtitle: 'Version 1.0.0',
                        trailing: null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2,
          color: context.textDim,
          fontFamily: 'sans-serif',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: context.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.border),
        ),
        child: Icon(icon, size: 16, color: context.text),
      ),
    );
  }
}

class _TextSettingsTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showTextSettingsSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: Row(children: [
          Icon(Icons.text_fields, color: AppColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text Settings',
                    style: TextStyle(fontSize: 14, color: context.text)),
                const SizedBox(height: 2),
                Text('Reading mode, font size, swipe navigation',
                    style: TextStyle(
                        fontSize: 11,
                        color: context.textDim,
                        fontFamily: 'sans-serif')),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.textDim, size: 20),
        ]),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/prayer-notifications'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined,
                color: AppColors.gold, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prayer Notifications',
                      style: TextStyle(fontSize: 14, color: context.text)),
                  const SizedBox(height: 2),
                  Text('Adhan, vibration, or silent alerts',
                      style: TextStyle(
                          fontSize: 11,
                          color: context.textDim,
                          fontFamily: 'sans-serif')),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DailyRemindersTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/daily-reminders'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined,
                color: AppColors.gold, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Reminders',
                      style: TextStyle(fontSize: 14, color: context.text)),
                  const SizedBox(height: 2),
                  Text('Quran reading & Ayah of the Day',
                      style: TextStyle(
                          fontSize: 11,
                          color: context.textDim,
                          fontFamily: 'sans-serif')),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final AppState state;

  const _LanguageSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Translation Language',
              style: TextStyle(fontSize: 14, color: context.text)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: state.langCode,
            isExpanded: true,
            dropdownColor: context.surface,
            underline: const SizedBox(),
            style: TextStyle(
                fontSize: 13, color: context.text, fontFamily: 'serif'),
            items: kLanguages
                .map((l) => DropdownMenuItem(
                      value: l.code,
                      child: Text('${l.name} (${l.nativeName})'),
                    ))
                .toList(),
            onChanged: (code) {
              if (code != null) state.setLanguage(code);
            },
          ),
        ],
      ),
    );
  }
}

// ── Islamic Books tiles ───────────────────────────────────────────────────────

class _IslamicBooksLanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BookDownloadService>(builder: (context, svc, _) {
      final langName = svc.language == 'ar'
          ? 'Arabic'
          : svc.language == 'ur'
              ? 'Urdu'
              : 'English';
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const BookLanguageScreen(),
              fullscreenDialog: true),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.border),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reading language',
                      style: TextStyle(fontSize: 14, color: context.text)),
                  const SizedBox(height: 2),
                  Text(langName,
                      style: TextStyle(
                          fontSize: 11,
                          color: context.textDim,
                          fontFamily: 'sans-serif')),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textDim, size: 20),
          ]),
        ),
      );
    });
  }
}

class _ManageDownloadsTile extends StatelessWidget {
  Future<void> _showManageSheet(BuildContext context) async {
    final svc = context.read<BookDownloadService>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageDownloadsSheet(svc: svc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookDownloadService>(builder: (context, svc, _) {
      final downloaded = svc.downloadedBooks;
      final subtitle = downloaded.isEmpty
          ? 'No books downloaded'
          : '${downloaded.length} book${downloaded.length == 1 ? '' : 's'} downloaded';
      return GestureDetector(
        onTap: () => _showManageSheet(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.border),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage downloads',
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
            Icon(Icons.chevron_right, color: context.textDim, size: 20),
          ]),
        ),
      );
    });
  }
}

class _ManageDownloadsSheet extends StatelessWidget {
  final BookDownloadService svc;
  const _ManageDownloadsSheet({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: context.border)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Manage Downloads',
              style: TextStyle(
                  fontFamily: 'serif', fontSize: 18, color: context.text)),
          const SizedBox(height: 16),
          if (svc.downloadedBooks.isEmpty)
            Text('No books downloaded yet.',
                style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'sans-serif',
                    color: context.textDim))
          else
            ...svc.downloadedBooks.map((book) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: book.spineColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(book.spineChar,
                            style: const TextStyle(
                                fontFamily: 'Scheherazade',
                                fontSize: 14,
                                color: AppColors.gold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title,
                              style: TextStyle(
                                  fontSize: 13, color: context.text)),
                          Text('${book.fileSizeMb.toStringAsFixed(1)} MB',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'sans-serif',
                                  color: context.textDim)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await svc.deleteBook(book.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text('Delete',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade400,
                              fontFamily: 'sans-serif')),
                    ),
                  ]),
                )),
        ],
      ),
    );
  }
}

// ── Translation Source tile ───────────────────────────────────────────────────

class _TranslationSourceTile extends StatefulWidget {
  const _TranslationSourceTile();

  @override
  State<_TranslationSourceTile> createState() => _TranslationSourceTileState();
}

class _TranslationSourceTileState extends State<_TranslationSourceTile> {
  String _enSource = 'en.sahih';
  String _urSource = 'ur.jalandhry';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enSource = prefs.getString('translation_source_en') ?? 'en.sahih';
      _urSource = prefs.getString('translation_source_ur') ?? 'ur.jalandhry';
    });
  }

  Future<void> _setSource(String langCode, String editionId) async {
    setState(() {
      if (langCode == 'en') _enSource = editionId;
      if (langCode == 'ur') _urSource = editionId;
    });
    context.read<QuranService>().setTranslationSource(langCode, editionId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final lang = appState.langCode;
        final isEn = lang == 'en';
        final isUr = lang == 'ur';
        if (!isEn && !isUr) return const SizedBox.shrink();

        final sources = isEn
            ? QuranService.kEnTranslationSources
            : QuranService.kUrTranslationSources;
        final currentSource = isEn ? _enSource : _urSource;
        final effectiveSource =
            sources.containsKey(currentSource) ? currentSource : sources.keys.first;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Text('Translation Source',
                    style: TextStyle(fontSize: 14, color: context.text)),
              ),
              ...sources.entries.map((e) {
                final selected = e.key == effectiveSource;
                return GestureDetector(
                  onTap: () => _setSource(isEn ? 'en' : 'ur', e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: context.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(e.value,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: selected ? AppColors.gold : context.text,
                                  fontFamily: 'serif')),
                        ),
                        if (selected)
                          Icon(Icons.check, size: 16, color: AppColors.gold),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

// ── Audio Language tile ───────────────────────────────────────────────────────

class _AudioLanguageTile extends StatelessWidget {
  const _AudioLanguageTile();

  static const Map<String, String> _langNames = {
    'ar': 'Arabic',
    'en': 'English',
    'ur': 'Urdu',
    'fr': 'French',
    'fa': 'Persian',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(builder: (context, audio, _) {
      final currentLang = audio.audioLanguage;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audio Language',
                          style: TextStyle(fontSize: 14, color: context.text)),
                      const SizedBox(height: 2),
                      Text('Language for Quran recitation',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.textDim,
                              fontFamily: 'sans-serif')),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: currentLang,
                  dropdownColor: context.surface,
                  underline: const SizedBox(),
                  style: TextStyle(
                      fontSize: 13, color: context.text, fontFamily: 'serif'),
                  items: _langNames.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (code) {
                    if (code != null) audio.setAudioLanguage(code);
                  },
                ),
              ],
            ),
            // Arabic: reciter dropdown; others: static reciter name
            const Divider(height: 20),
            if (currentLang == 'ar') ...[
              Text('Reciter',
                  style: TextStyle(
                      fontSize: 12,
                      color: context.textDim,
                      fontFamily: 'sans-serif')),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: audio.reciterId,
                isExpanded: true,
                dropdownColor: context.surface,
                underline: const SizedBox(),
                style: TextStyle(
                    fontSize: 13, color: context.text, fontFamily: 'serif'),
                items: Reciter.all
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text('${r.name} — ${r.style}'),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id != null) audio.setReciter(id);
                },
              ),
            ] else ...[
              Row(
                children: [
                  Text('Reciter',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.textDim,
                          fontFamily: 'sans-serif')),
                  const Spacer(),
                  Text(audio.currentReciterName,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.text,
                          fontFamily: 'serif')),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}
