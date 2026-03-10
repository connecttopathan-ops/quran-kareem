import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  // Mecca coordinates
  static const double _meccaLat = 21.4225;
  static const double _meccaLng = 39.8262;

  /// Haversine-based bearing from [lat1, lng1] to Mecca (degrees, 0=North).
  static double _qiblaBearing(double lat1, double lng1) {
    final lat1r = lat1 * math.pi / 180;
    final lat2r = _meccaLat * math.pi / 180;
    final dLng = (_meccaLng - lng1) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2r);
    final x = math.cos(lat1r) * math.sin(lat2r) -
        math.sin(lat1r) * math.cos(lat2r) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: QIcon.back(size: 22, color: context.textDim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Qibla Direction',
            style: TextStyle(
                color: context.text,
                fontSize: 16,
                fontFamily: 'serif',
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: Consumer<LocationService>(
        builder: (context, loc, _) {
          final pt = loc.prayerTimes;
          if (pt == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 48, color: context.textDim),
                    const SizedBox(height: 16),
                    Text('Location required for Qibla direction',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.textDim,
                            fontSize: 14,
                            fontFamily: 'sans-serif')),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => loc.fetchLocation(),
                      child: const Text('Detect Location'),
                    ),
                  ],
                ),
              ),
            );
          }

          final qibla = _qiblaBearing(pt.lat, pt.lng);

          return StreamBuilder<CompassEvent>(
            stream: FlutterCompass.events,
            builder: (context, snap) {
              final heading = snap.data?.heading ?? 0.0;
              // Needle angle: qibla bearing relative to device heading
              final needleAngle = (qibla - heading) * math.pi / 180;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // City name
                      Text(pt.cityName,
                          style: TextStyle(
                              color: context.textDim,
                              fontSize: 13,
                              fontFamily: 'sans-serif')),
                      const SizedBox(height: 4),
                      Text(
                          '${qibla.toStringAsFixed(1)}° from North',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontFamily: 'sans-serif')),
                      const SizedBox(height: 40),
                      // Compass
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: AnimatedRotation(
                          turns: needleAngle / (2 * math.pi),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: CustomPaint(
                            painter: _CompassPainter(
                                isDark: context.isDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.goldDim.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.goldDim.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mosque_outlined,
                                size: 16, color: AppColors.gold),
                            const SizedBox(width: 8),
                            Text('Face the direction of the arrow',
                                style: TextStyle(
                                    color: context.text,
                                    fontSize: 12,
                                    fontFamily: 'sans-serif')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final bool isDark;
  const _CompassPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final goldColor = const Color(0xFFD4AF37);
    final bgColor = isDark ? const Color(0xFF1A1508) : const Color(0xFFFDF3E0);
    final borderColor = isDark ? const Color(0xFF3A2E10) : const Color(0xFFCEB060);
    final dimColor = isDark ? const Color(0xFF5A4A30) : const Color(0xFF9A7030);

    // Outer ring
    canvas.drawCircle(center, radius - 2,
        Paint()..color = bgColor..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius - 2,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Compass tick marks
    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180;
      final isMajor = i % 9 == 0;
      final tickLen = isMajor ? 14.0 : 6.0;
      final paint = Paint()
        ..color = isMajor ? goldColor : dimColor
        ..strokeWidth = isMajor ? 1.5 : 1.0;
      canvas.drawLine(
        center + Offset(math.sin(angle), -math.cos(angle)) * (radius - 14),
        center +
            Offset(math.sin(angle), -math.cos(angle)) * (radius - 14 - tickLen),
        paint,
      );
    }

    // Qibla arrow (pointing up = Qibla direction)
    final arrowPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    final tipY = center.dy - radius * 0.55;
    final baseY = center.dy + radius * 0.25;
    arrowPath.moveTo(center.dx, tipY); // tip
    arrowPath.lineTo(center.dx - 12, center.dy);
    arrowPath.lineTo(center.dx - 5, center.dy);
    arrowPath.lineTo(center.dx - 5, baseY);
    arrowPath.lineTo(center.dx + 5, baseY);
    arrowPath.lineTo(center.dx + 5, center.dy);
    arrowPath.lineTo(center.dx + 12, center.dy);
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Kaaba icon in center
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 20, height: 20),
        const Radius.circular(3),
      ),
      Paint()..color = goldColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 20, height: 20),
        const Radius.circular(3),
      ),
      Paint()
        ..color = isDark ? const Color(0xFF0C0902) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.isDark != isDark;
}
