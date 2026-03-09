import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../models/language.dart';
import '../widgets/q_icons.dart';

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
                      _SectionHeader('Reading'),
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
