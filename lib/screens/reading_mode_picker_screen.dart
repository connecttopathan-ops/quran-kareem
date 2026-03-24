import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

class ReadingModePickerScreen extends StatefulWidget {
  const ReadingModePickerScreen({super.key});

  @override
  State<ReadingModePickerScreen> createState() =>
      _ReadingModePickerScreenState();
}

class _ReadingModePickerScreenState extends State<ReadingModePickerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMode = 1;
  bool _showScrollHint = true;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  final ScrollController _scrollCtrl = ScrollController();

  static const _modeNames = [
    'Translation only',
    'Arabic + Translation',
    'Arabic + Transliteration',
  ];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 7).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.offset > 20 && _showScrollHint) {
        setState(() => _showScrollHint = false);
        _bounceCtrl.stop();
      }
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final state = context.read<AppState>();
    await state.setDisplayReadingMode(_selectedMode);
    await state.setDisplayReadingModeSet(true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.close(size: 22, color: context.textDim),
          onPressed: () async {
            // Mark as set even if they dismiss — default mode 1 is used
            await context.read<AppState>().setDisplayReadingModeSet(true);
            if (mounted) Navigator.pop(context);
          },
        ),
        title: Column(children: [
          Text(
            'Al-Fatihah',
            style: TextStyle(
              color: context.text,
              fontSize: 16,
              fontFamily: 'serif',
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Choose how you want to read',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textDim,
                    fontSize: 13,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
                  children: [
                    _ModePickerCard(
                      mode: 1,
                      selected: _selectedMode == 1,
                      onTap: () => setState(() => _selectedMode = 1),
                    ),
                    const SizedBox(height: 10),
                    _ModePickerCard(
                      mode: 2,
                      selected: _selectedMode == 2,
                      onTap: () => setState(() => _selectedMode = 2),
                    ),
                    const SizedBox(height: 10),
                    _ModePickerCard(
                      mode: 3,
                      selected: _selectedMode == 3,
                      onTap: () => setState(() => _selectedMode = 3),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Animated scroll hint
          if (_showScrollHint)
            Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showScrollHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _bounceAnim.value),
                    child: Column(children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: context.textDim,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'scroll to compare',
                        style: TextStyle(
                          color: context.textDim,
                          fontSize: 10,
                          fontFamily: 'sans-serif',
                          letterSpacing: 1,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

          // Pinned footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: context.surface,
                border: Border(top: BorderSide(color: context.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You can always change this in Settings › Text Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textDim,
                      fontSize: 11,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _confirm,
                      child: Text(
                        'Start Reading — ${_modeNames[_selectedMode - 1]}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'sans-serif',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode Picker Card ───────────────────────────────────────────────────────────

class _ModePickerCard extends StatelessWidget {
  final int mode;
  final bool selected;
  final VoidCallback onTap;

  // Hardcoded Al-Fatiha preview (verses 1–3)
  static const _previewArabic = [
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'الرَّحْمَٰنِ الرَّحِيمِ',
  ];
  static const _previewTranslit = [
    'Bismillaahir Rahmaanir Raheem',
    "Alhamdu lillaahi Rabbil 'aalameen",
    'Ar-Rahmaanir Raheem',
  ];
  static const _previewTranslation = [
    'In the name of Allah, the Entirely Merciful, the Especially Merciful',
    'All praise is due to Allah, Lord of all the worlds',
    'The Entirely Merciful, the Especially Merciful',
  ];
  static const _modeNames = [
    'Translation only',
    'Arabic + Translation',
    'Arabic + Transliteration',
  ];
  static const _modeDescs = [
    'Just the meaning — clean and focused',
    'Arabic text with meaning below each verse',
    'Arabic, Roman phonetics, and translation',
  ];
  static const _modeIcons = [
    Icons.text_fields,
    Icons.auto_stories,
    Icons.translate,
  ];

  const _ModePickerCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.gold : context.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.goldDim.withOpacity(0.12)
                        : context.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.gold : context.border,
                    ),
                  ),
                  child: Icon(
                    _modeIcons[mode - 1],
                    size: 20,
                    color: selected ? AppColors.gold : context.textDim,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _modeNames[mode - 1],
                        style: TextStyle(
                          fontSize: 14,
                          color: context.text,
                          fontFamily: 'serif',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _modeDescs[mode - 1],
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textDim,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<int>(
                  value: mode,
                  groupValue: selected ? mode : 0,
                  onChanged: (_) => onTap(),
                  activeColor: AppColors.gold,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ]),
            ),

            // Preview block
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.border),
              ),
              child: Column(
                children: List.generate(
                    3, (i) => _buildVersePreview(context, i)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersePreview(BuildContext context, int i) {
    return Padding(
      padding: EdgeInsets.only(bottom: i < 2 ? 8 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verse number pill
          Row(children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldFaint.withOpacity(0.5),
                border: Border.all(color: AppColors.lightBorder2),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.gold,
                    fontFamily: 'sans-serif',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),

          // Arabic (modes 2 and 3)
          if (mode >= 2) ...[
            Text(
              _previewArabic[i],
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Scheherazade',
                fontSize: 16,
                color: context.arabic,
                height: 1.8,
              ),
            ),
          ],

          // Transliteration (mode 3 only)
          if (mode >= 3) ...[
            Text(
              _previewTranslit[i],
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: context.translit,
                height: 1.4,
              ),
            ),
          ],

          // Translation (all modes)
          Text(
            _previewTranslation[i],
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 11,
              color: context.urduText,
              height: 1.4,
            ),
          ),

          if (i < 2) ...[
            const SizedBox(height: 4),
            Container(height: 0.5, color: context.border),
          ],
        ],
      ),
    );
  }
}
