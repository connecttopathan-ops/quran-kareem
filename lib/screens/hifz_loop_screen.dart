import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_data.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HIFZ LOOP SCREEN  —  per-verse audio loop player for memorization
// ─────────────────────────────────────────────────────────────────────────────

class HifzLoopScreen extends StatefulWidget {
  final int surahNumber;
  final int initialVerse;
  final String langCode;
  final VoidCallback? onMemorizationChanged;

  const HifzLoopScreen({
    super.key,
    required this.surahNumber,
    this.initialVerse = 1,
    this.langCode = 'en',
    this.onMemorizationChanged,
  });

  @override
  State<HifzLoopScreen> createState() => _HifzLoopScreenState();
}

class _HifzLoopScreenState extends State<HifzLoopScreen>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _waveController;

  // Surah metadata
  late int _surahNumber;
  late int _totalVerses;
  late String _surahName;
  late String _surahArabicName;

  // Current verse
  int _currentVerse = 1;

  // Text content
  Map<int, String> _arabicTexts = {};
  Map<int, String> _transliterationTexts = {};  // Roman Arabic
  Map<int, String> _translationTexts = {};       // User's selected language

  // Word-by-word highlighting
  // verseNumber → list of [wordIndex(1-based), startMs, endMs]
  Map<int, List<List<int>>> _wordTimings = {};
  int _activeWordIndex = -1;   // 1-based; -1 = none
  StreamSubscription<Duration>? _positionSub;

  // Memorization state
  Set<int> _memorized = {};

  // Loop state
  int _loopCount = 0;         // how many times current verse has played
  int _loopsPerVerse = 3;     // setting: 1–10
  bool _autoAdvance = true;

  // Playback state
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _showSettings = false;
  double _speed = 1.0;

  // Data loading
  bool _textLoading = true;

  @override
  void initState() {
    super.initState();
    _surahNumber = widget.surahNumber;
    _currentVerse = widget.initialVerse;

    final surah = kSurahs[_surahNumber - 1];
    _totalVerses = surah.verses;
    _surahName = surah.nameTransliteration;
    _surahArabicName = surah.nameArabic;

    _player = AudioPlayer();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _player.playerStateStream.listen(_onPlayerState);
    _positionSub = _player.positionStream.listen(_onPosition);
    _loadPrefs();
    _loadTexts();
    _loadMemorized();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _loopsPerVerse = prefs.getInt('hifz_loops_per_verse') ?? 3;
        _autoAdvance = prefs.getBool('hifz_auto_advance') ?? true;
        _speed = prefs.getDouble('hifz_speed') ?? 1.0;
      });
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hifz_loops_per_verse', _loopsPerVerse);
    await prefs.setBool('hifz_auto_advance', _autoAdvance);
    await prefs.setDouble('hifz_speed', _speed);
  }

  /// Load Arabic text + transliteration from alquran.cloud API,
  /// and translation from the bundled asset for the selected language.
  Future<void> _loadTexts() async {
    if (!mounted) return;
    setState(() => _textLoading = true);

    // Load translation from bundled asset (selected language, fallback 'en')
    final langCode = widget.langCode;
    // ur-roman is not a translation — map to 'en' if it's set as the lang
    final assetLang = (langCode == 'ur-roman') ? 'en' : langCode;
    try {
      final raw =
          await rootBundle.loadString('assets/translations/$assetLang.json');
      final Map<String, dynamic> data = json.decode(raw);
      final surahData = data[_surahNumber.toString()];
      if (surahData is Map) {
        final Map<int, String> trans = {};
        for (final entry in surahData.entries) {
          final v = int.tryParse(entry.key.toString());
          if (v != null) trans[v] = entry.value.toString();
        }
        if (mounted) setState(() => _translationTexts = trans);
      }
    } catch (_) {
      // Fallback to English if the selected language asset is missing
      try {
        final raw =
            await rootBundle.loadString('assets/translations/en.json');
        final Map<String, dynamic> data = json.decode(raw);
        final surahData = data[_surahNumber.toString()];
        if (surahData is Map) {
          final Map<int, String> trans = {};
          for (final entry in surahData.entries) {
            final v = int.tryParse(entry.key.toString());
            if (v != null) trans[v] = entry.value.toString();
          }
          if (mounted) setState(() => _translationTexts = trans);
        }
      } catch (_) {}
    }

    // Load Arabic text + transliteration from alquran.cloud (two editions in one call)
    try {
      final url =
          'https://api.alquran.cloud/v1/surah/$_surahNumber/editions/quran-uthmani,en.transliteration';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final editions = decoded['data'] as List?;
        if (editions != null && editions.length >= 2) {
          final Map<int, String> arabic = {};
          for (final ayah in (editions[0]['ayahs'] as List? ?? [])) {
            final v = ayah['numberInSurah'] as int?;
            final text = ayah['text'] as String?;
            if (v != null && text != null) arabic[v] = text;
          }
          final Map<int, String> translit = {};
          for (final ayah in (editions[1]['ayahs'] as List? ?? [])) {
            final v = ayah['numberInSurah'] as int?;
            final text = ayah['text'] as String?;
            if (v != null && text != null) translit[v] = text;
          }
          if (mounted) {
            setState(() {
              _arabicTexts = arabic;
              _transliterationTexts = translit;
            });
          }
        }
      }
    } catch (_) {}

    // Load word-level timing from qurancdn
    // Response: one entry per surah with verse_timings[].segments
    // Segment format: [wordPos(1-based), absStartMs, absEndMs] — absolute in surah file.
    // Subtract each verse's timestamp_from to get per-verse relative ms.
    try {
      final timingUrl =
          'https://api.qurancdn.com/api/qdc/audio/reciters/7/audio_files?chapter=$_surahNumber&segments=true';
      final timingRes = await http
          .get(Uri.parse(timingUrl))
          .timeout(const Duration(seconds: 10));
      if (timingRes.statusCode == 200) {
        final decoded = json.decode(timingRes.body);
        final audioFiles = decoded['audio_files'] as List?;
        if (audioFiles != null && audioFiles.isNotEmpty) {
          final verseTimings = audioFiles[0]['verse_timings'] as List?;
          if (verseTimings != null) {
            final Map<int, List<List<int>>> timings = {};
            for (final vt in verseTimings) {
              final verseKey = vt['verse_key'] as String?;
              final timestampFrom =
                  (vt['timestamp_from'] as num?)?.toInt() ?? 0;
              final segments = vt['segments'] as List?;
              if (verseKey == null || segments == null) continue;
              final parts = verseKey.split(':');
              if (parts.length != 2) continue;
              final v = int.tryParse(parts[1]);
              if (v == null) continue;
              // Convert absolute → per-verse relative, skip malformed entries
              final List<List<int>> parsed = [];
              for (final s in segments) {
                final seg = s as List;
                if (seg.length < 3) continue; // skip malformed
                final wordPos = (seg[0] as num).toInt();
                final startMs =
                    ((seg[1] as num).toInt() - timestampFrom).clamp(0, 999999);
                final endMs =
                    ((seg[2] as num).toInt() - timestampFrom).clamp(0, 999999);
                parsed.add([wordPos, startMs, endMs]);
              }
              if (parsed.isNotEmpty) timings[v] = parsed;
            }
            if (mounted) setState(() => _wordTimings = timings);
          }
        }
      }
    } catch (e) {
      debugPrint('[Hifz] word timing error: $e');
    }

    if (mounted) {
      setState(() => _textLoading = false);
      // Auto-play first verse once texts are loaded
      await _playCurrentVerse();
    }
  }

  Future<void> _loadMemorized() async {
    final prefs = await SharedPreferences.getInstance();
    final Set<int> mem = {};
    for (int v = 1; v <= _totalVerses; v++) {
      if (prefs.getBool('hifz_ayah_${_surahNumber}_$v') == true) {
        mem.add(v);
      }
    }
    if (mounted) setState(() => _memorized = mem);
  }

  void _onPosition(Duration pos) {
    if (!mounted) return;
    final ms = pos.inMilliseconds;
    final timings = _wordTimings[_currentVerse];
    if (timings == null) return;
    int newIndex = -1;
    for (final seg in timings) {
      if (ms >= seg[1] && ms < seg[2]) {
        newIndex = seg[0]; // 1-based
        break;
      }
    }
    if (newIndex != _activeWordIndex) {
      setState(() => _activeWordIndex = newIndex);
    }
  }

  void _onPlayerState(PlayerState state) {
    if (!mounted) return;
    final playing = state.playing;
    final completed = state.processingState == ProcessingState.completed;
    setState(() => _isPlaying = playing);

    if (playing) {
      _waveController.repeat(reverse: true);
    } else {
      _waveController.stop();
    }

    if (completed) {
      _onVerseCompleted();
    }
  }

  Future<void> _onVerseCompleted() async {
    await _recordRep();
    final newLoopCount = _loopCount + 1;
    if (_autoAdvance && newLoopCount >= _loopsPerVerse) {
      setState(() => _loopCount = 0);
      if (_currentVerse < _totalVerses) {
        await _goToVerse(_currentVerse + 1);
      } else {
        // End of surah
        await _player.stop();
        if (mounted) setState(() => _isPlaying = false);
      }
    } else {
      setState(() => _loopCount = newLoopCount);
      // Replay current verse
      await _player.seek(Duration.zero);
      await _player.play();
    }
  }

  Future<void> _recordRep() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final key = 'hifz_reps_$today';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Compute absolute verse number (1-based within full Quran).
  int _absoluteVerse(int verseNumber) {
    int offset = 0;
    for (final s in kSurahs) {
      if (s.number >= _surahNumber) break;
      offset += s.verses;
    }
    return offset + verseNumber;
  }

  String _audioUrl(int verseNumber) {
    final abs = _absoluteVerse(verseNumber);
    return 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$abs.mp3';
  }

  Future<void> _playCurrentVerse() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // just_audio_background requires AudioSource.uri with a MediaItem tag;
      // plain setUrl() is silently ignored when JustAudioBackground is active.
      final source = AudioSource.uri(
        Uri.parse(_audioUrl(_currentVerse)),
        tag: MediaItem(
          id: 'hifz_${_surahNumber}_$_currentVerse',
          title: '$_surahName – Verse $_currentVerse',
          artist: 'Mishary Rashid Alafasy',
          album: 'Hifz',
        ),
      );
      await _player.setAudioSource(source);
      await _player.setSpeed(_speed);
      await _player.play();
    } catch (e) {
      debugPrint('[Hifz] audio error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _goToVerse(int verse) async {
    if (verse < 1 || verse > _totalVerses) return;
    setState(() {
      _currentVerse = verse;
      _loopCount = 0;
      _activeWordIndex = -1;
    });
    await _playCurrentVerse();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> _toggleMemorized() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'hifz_ayah_${_surahNumber}_$_currentVerse';
    final newVal = !_memorized.contains(_currentVerse);
    await prefs.setBool(key, newVal);
    setState(() {
      if (newVal) {
        _memorized.add(_currentVerse);
      } else {
        _memorized.remove(_currentVerse);
      }
    });
    widget.onMemorizationChanged?.call();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMemorized = _memorized.contains(_currentVerse);
    final arabicText = _arabicTexts[_currentVerse];
    final transliterationText = _transliterationTexts[_currentVerse];
    final translationText = _translationTexts[_currentVerse];

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.back(size: 22, color: context.textDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              _surahName,
              style: TextStyle(
                color: context.text,
                fontSize: 15,
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_memorized.length} / $_totalVerses memorized',
              style: TextStyle(
                color: context.textDim,
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: _showSettings ? AppColors.gold : context.textDim,
              size: 22,
            ),
            onPressed: () => setState(() => _showSettings = !_showSettings),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.border),
        ),
      ),
      body: Column(
        children: [
          if (_showSettings) _buildSettingsPanel(),
          Expanded(child: _buildContent(arabicText, transliterationText, translationText, isMemorized)),
          _buildControls(isMemorized),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: context.surface,
      child: Column(
        children: [
          Divider(height: 1, color: context.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Loops per verse
                Row(
                  children: [
                    Icon(Icons.repeat_rounded,
                        size: 18, color: context.textDim),
                    const SizedBox(width: 8),
                    Text('Repeats per verse',
                        style:
                            TextStyle(color: context.text, fontSize: 13)),
                    const Spacer(),
                    Row(
                      children: [
                        _iconBtn(Icons.remove, () {
                          if (_loopsPerVerse > 1) {
                            setState(() => _loopsPerVerse--);
                            _savePrefs();
                          }
                        }),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$_loopsPerVerse×',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _iconBtn(Icons.add, () {
                          if (_loopsPerVerse < 10) {
                            setState(() => _loopsPerVerse++);
                            _savePrefs();
                          }
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Auto-advance
                Row(
                  children: [
                    Icon(Icons.skip_next_rounded,
                        size: 18, color: context.textDim),
                    const SizedBox(width: 8),
                    Text('Auto-advance',
                        style:
                            TextStyle(color: context.text, fontSize: 13)),
                    const Spacer(),
                    Switch(
                      value: _autoAdvance,
                      onChanged: (v) {
                        setState(() => _autoAdvance = v);
                        _savePrefs();
                      },
                      activeColor: AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Playback speed
                Row(
                  children: [
                    Icon(Icons.speed_rounded,
                        size: 18, color: context.textDim),
                    const SizedBox(width: 8),
                    Text('Speed',
                        style:
                            TextStyle(color: context.text, fontSize: 13)),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      children: [0.5, 0.75, 1.0, 1.25, 1.5]
                          .map((s) => GestureDetector(
                                onTap: () async {
                                  setState(() => _speed = s);
                                  await _player.setSpeed(s);
                                  _savePrefs();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _speed == s
                                        ? AppColors.gold
                                        : context.surface2,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    border: Border.all(
                                        color: _speed == s
                                            ? AppColors.gold
                                            : context.border),
                                  ),
                                  child: Text(
                                    '${s}×',
                                    style: TextStyle(
                                      color: _speed == s
                                          ? Colors.white
                                          : context.textDim,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.border),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: context.textDim),
      ),
    );
  }

  Widget _buildContent(String? arabicText, String? transliterationText,
      String? translationText, bool isMemorized) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          // Verse number badge + surah arabic name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _surahArabicName,
                style: const TextStyle(
                  fontFamily: 'Scheherazade',
                  fontSize: 18,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border),
                ),
                child: Text(
                  'Verse $_currentVerse of $_totalVerses',
                  style: TextStyle(
                    color: context.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Loop counter dots
          _buildLoopDots(),
          const SizedBox(height: 24),

          // Arabic text (word-by-word highlighted when timing data available)
          if (_textLoading)
            const CircularProgressIndicator()
          else if (arabicText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child: _wordTimings.containsKey(_currentVerse)
                  ? _buildHighlightedArabic(arabicText)
                  : Text(
                      arabicText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Scheherazade',
                        fontSize: 28,
                        height: 1.8,
                        color: context.text,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
          ],

          // Roman Arabic transliteration
          if (!_textLoading && transliterationText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Text(
                transliterationText,
                style: TextStyle(
                  color: context.textDim,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Translation (selected language)
          if (!_textLoading && translationText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Text(
                translationText,
                style: TextStyle(
                  color: context.text,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Memorized indicator
          if (isMemorized)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Memorized',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Renders Arabic verse as a right-aligned Wrap of individually coloured words.
  /// The word at [_activeWordIndex] (1-based) is highlighted in gold.
  Widget _buildHighlightedArabic(String arabicText) {
    final words = arabicText.split(' ');
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 2,
      runSpacing: 6,
      children: words.asMap().entries.map((entry) {
        final wordPos = entry.key + 1; // convert to 1-based
        final word = entry.value;
        final isActive = wordPos == _activeWordIndex;
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 120),
          style: TextStyle(
            fontFamily: 'Scheherazade',
            fontSize: 28,
            height: 1.8,
            color: isActive ? AppColors.gold : context.text,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
          child: Text(word),
        );
      }).toList(),
    );
  }

  Widget _buildLoopDots() {
    final completed = _loopCount;
    final total = _loopsPerVerse;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final done = i < completed;
        final active = i == completed && _isPlaying;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: done
                ? AppColors.gold
                : active
                    ? AppColors.gold.withOpacity(0.6)
                    : context.border,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }

  Widget _buildControls(bool isMemorized) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation + play
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous verse
              _controlBtn(
                icon: Icons.skip_previous_rounded,
                size: 32,
                color: _currentVerse > 1 ? context.textDim : context.border,
                onTap: _currentVerse > 1
                    ? () async {
                        setState(() => _loopCount = 0);
                        await _goToVerse(_currentVerse - 1);
                      }
                    : null,
              ),

              // Replay current
              _controlBtn(
                icon: Icons.replay_rounded,
                size: 28,
                color: context.textDim,
                onTap: () async {
                  setState(() => _loopCount = 0);
                  await _player.seek(Duration.zero);
                  await _player.play();
                },
              ),

              // Play / pause
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                ),
              ),

              // Memorize toggle
              GestureDetector(
                onTap: _toggleMemorized,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMemorized
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isMemorized ? AppColors.gold : context.textDim,
                      size: 28,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMemorized ? 'Mem.' : 'Mark',
                      style: TextStyle(
                        color: isMemorized
                            ? AppColors.gold
                            : context.textDim,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              // Next verse
              _controlBtn(
                icon: Icons.skip_next_rounded,
                size: 32,
                color: _currentVerse < _totalVerses
                    ? context.textDim
                    : context.border,
                onTap: _currentVerse < _totalVerses
                    ? () async {
                        setState(() => _loopCount = 0);
                        await _goToVerse(_currentVerse + 1);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final memorizedCount = _memorized.length;
    final pct = _totalVerses > 0 ? memorizedCount / _totalVerses : 0.0;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: context.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$memorizedCount of $_totalVerses verses memorized in $_surahName',
            style: TextStyle(color: context.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required double size,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: size, color: color),
    );
  }
}
