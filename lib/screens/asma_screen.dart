import 'package:flutter/material.dart';
import '../data/asma_ul_husna.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

class AsmaScreen extends StatefulWidget {
  const AsmaScreen({super.key});

  @override
  State<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends State<AsmaScreen> {
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<AsmaEntry> get _filtered {
    if (_query.isEmpty) return kAsmaUlHusna;
    final q = _query.toLowerCase();
    return kAsmaUlHusna
        .where((e) =>
            e.transliteration.toLowerCase().contains(q) ||
            e.meaning.toLowerCase().contains(q) ||
            e.number.toString() == q)
        .toList();
  }

  void _showDetail(AsmaEntry entry) {
    final color = asmaColor(entry.number);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AsmaDetailSheet(entry: entry, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios,
                            size: 18, color: context.textDim),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أَسْمَاءُ اللَّهِ الْحُسْنَى',
                              style: TextStyle(
                                fontFamily: 'Scheherazade',
                                fontSize: 20,
                                color: context.isDark
                                    ? AppColors.gold
                                    : AppColors.goldDark,
                              ),
                            ),
                            Text(
                              'The 99 Names of Allah',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'sans-serif',
                                color: context.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: Text(
                          '99',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'serif',
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  TextField(
                    controller: _ctrl,
                    style: TextStyle(color: context.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or meaning...',
                      hintStyle:
                          TextStyle(color: context.textDim, fontSize: 13),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(11),
                        child: QIcon.search(
                            size: 17, color: context.textDim),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: QIcon.close(
                                  size: 16, color: context.textDim),
                              onPressed: () {
                                _ctrl.clear();
                                setState(() => _query = '');
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
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),

            // ── Grid ────────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _AsmaCard(
                        entry: filtered[i],
                        onTap: () => _showDetail(filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.08),
                border: Border.all(
                    color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  'بَحْث',
                  style: TextStyle(
                    fontFamily: 'Scheherazade',
                    fontSize: 20,
                    color: AppColors.gold.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No names found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching by transliteration or meaning',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'sans-serif',
                color: context.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _AsmaCard extends StatelessWidget {
  final AsmaEntry entry;
  final VoidCallback onTap;

  const _AsmaCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = asmaColor(entry.number);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              Color.lerp(color, Colors.black, 0.22)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle pattern overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(painter: _CirclePainter()),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.number.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontFamily: 'sans-serif',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Arabic name
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      entry.arabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Scheherazade',
                        fontSize: 24,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Transliteration
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      entry.transliteration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.90),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Meaning
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      entry.meaning,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'sans-serif',
                        color: Colors.white.withOpacity(0.72),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Subtle decorative circles in the card background
class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.15), size.width * 0.45, paint);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.85), size.width * 0.3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Detail sheet ──────────────────────────────────────────────────────────────

class _AsmaDetailSheet extends StatelessWidget {
  final AsmaEntry entry;
  final Color color;

  const _AsmaDetailSheet({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1408) : const Color(0xFFF9F3E8);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.18)
                    : Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Colour circle with number
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  Color.lerp(color, Colors.black, 0.22)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                entry.number.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Arabic name
          Text(
            entry.arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Scheherazade',
              fontSize: 42,
              color: isDark ? Colors.white : const Color(0xFF1A0E00),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Transliteration
          Text(
            entry.transliteration,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),

          // Meaning
          Text(
            entry.meaning,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 15,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF5A4A2A),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Divider
          Divider(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.07),
          ),
          const SizedBox(height: 16),

          // Bismillah reminder
          Text(
            'سُبْحَانَهُ وَتَعَالَى',
            style: TextStyle(
              fontFamily: 'Scheherazade',
              fontSize: 18,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Glorified and Exalted be He',
            style: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 11,
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : const Color(0xFF9A8060),
            ),
          ),
        ],
      ),
    );
  }
}
