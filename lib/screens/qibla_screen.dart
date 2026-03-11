import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/q_icons.dart';

// ── Constants ──────────────────────────────────────────────────────────────────

const double _meccaLat = 21.4225;
const double _meccaLon = 39.8262;

double _calcQiblaBearing(double lat, double lon) {
  const mLat = _meccaLat * pi / 180;
  const mLon = _meccaLon * pi / 180;
  final uLat = lat * pi / 180;
  final uLon = lon * pi / 180;
  final dLon = mLon - uLon;
  final y = sin(dLon) * cos(mLat);
  final x = cos(uLat) * sin(mLat) - sin(uLat) * cos(mLat) * cos(dLon);
  return (atan2(y, x) * 180 / pi + 360) % 360;
}

double _getMagneticDeclination(double lat, double lon) {
  final latRad = lat * pi / 180;
  final lonRad = lon * pi / 180;
  final t = DateTime.now().year + DateTime.now().month / 12.0 - 2020.0;
  return -3.1 * sin(lonRad) - 8.7 * sin(latRad) * cos(lonRad) + 0.5 * t;
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  return 2 * r * asin(sqrt(a));
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with TickerProviderStateMixin {
  // Heading smoothing
  final List<double> _headingBuffer = [];
  double _smoothHeading = 0;

  // Tilt
  bool _isTilted = false;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // 2=high, 1=medium, 0=low — derived from heading buffer variance
  int _accuracyLevel = 1;

  // Haptic "on target" guard
  bool _hapticFired = false;

  // Calibration overlay
  bool _showCalibration = true;
  late AnimationController _lissajousCtrl;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();

    _lissajousCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );

    // Auto-dismiss calibration overlay after 3 seconds
    Future.delayed(const Duration(seconds: 3), _dismissCalibration);

    // Tilt detection
    _accelSub = accelerometerEventStream().listen((event) {
      // z-axis close to ±9.8 means flat; significant x/y tilt = tilted
      final tiltAngle = acos(event.z.abs() / sqrt(
              event.x * event.x + event.y * event.y + event.z * event.z)) *
          180 / pi;
      final tilted = tiltAngle > 30;
      if (tilted != _isTilted) {
        setState(() => _isTilted = tilted);
      }
    });
  }

  @override
  void dispose() {
    _lissajousCtrl.dispose();
    _fadeCtrl.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  void _dismissCalibration() {
    if (!mounted) return;
    _fadeCtrl.reverse().then((_) {
      if (mounted) setState(() => _showCalibration = false);
    });
  }

  void _showCalibrationOverlay() {
    setState(() => _showCalibration = true);
    _fadeCtrl.forward();
    _lissajousCtrl.repeat();
    Future.delayed(const Duration(seconds: 3), _dismissCalibration);
  }

  // Circular mean of heading buffer (handles 0/360 wrap)
  double _circularMean(List<double> angles) {
    double sinSum = 0, cosSum = 0;
    for (final a in angles) {
      final r = a * pi / 180;
      sinSum += sin(r);
      cosSum += cos(r);
    }
    return (atan2(sinSum, cosSum) * 180 / pi + 360) % 360;
  }

  void _onCompassEvent(CompassEvent event) {
    final h = event.heading ?? 0.0;
    _headingBuffer.add(h);
    if (_headingBuffer.length > 10) _headingBuffer.removeAt(0);
    _smoothHeading = _circularMean(_headingBuffer);

    // Derive accuracy from heading variance
    if (_headingBuffer.length >= 3) {
      final mean = _smoothHeading;
      double variance = 0;
      for (final a in _headingBuffer) {
        final d = ((a - mean + 540) % 360) - 180;
        variance += d * d;
      }
      variance /= _headingBuffer.length;
      _accuracyLevel = variance < 9 ? 2 : variance < 36 ? 1 : 0;
    }
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
        actions: [_AccuracyIndicator(level: _accuracyLevel)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: Stack(
        children: [
          Consumer<LocationService>(
            builder: (context, loc, _) {
              final pt = loc.prayerTimes;
              if (pt == null) return _NoLocation(loc: loc);

              final rawBearing = _calcQiblaBearing(pt.lat, pt.lng);
              final decl = _getMagneticDeclination(pt.lat, pt.lng);
              final qibla = (rawBearing - decl + 360) % 360;
              final distKm = _haversineKm(pt.lat, pt.lng, _meccaLat, _meccaLon);

              return StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (context, snap) {
                  if (snap.data != null) _onCompassEvent(snap.data!);

                  final needleAngle =
                      (qibla - _smoothHeading) * pi / 180;
                  final diff = ((qibla - _smoothHeading + 540) % 360) - 180;
                  final onTarget = diff.abs() < 2;

                  // Haptic feedback when aligned
                  if (onTarget && !_hapticFired) {
                    _hapticFired = true;
                    HapticFeedback.mediumImpact();
                  } else if (!onTarget) {
                    _hapticFired = false;
                  }

                  return Column(
                    children: [
                      if (_isTilted)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          color: Colors.orange.withOpacity(0.15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.screen_rotation,
                                  size: 14, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'Hold phone flat for accurate reading',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontFamily: 'sans-serif'),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Compass rose + needle
                                SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Static compass rose
                                      CustomPaint(
                                        size: const Size(260, 260),
                                        painter: _RosePainter(
                                            isDark: context.isDark),
                                      ),
                                      // Rotating needle
                                      Transform.rotate(
                                        angle: needleAngle,
                                        child: CustomPaint(
                                          size: const Size(260, 260),
                                          painter: _NeedlePainter(
                                              onTarget: onTarget,
                                              isDark: context.isDark),
                                        ),
                                      ),
                                      // Kaaba emoji at needle tip
                                      Transform.translate(
                                        offset: Offset(
                                          sin(needleAngle) * 90,
                                          -cos(needleAngle) * 90,
                                        ),
                                        child: const Text('🕋',
                                            style: TextStyle(fontSize: 20)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Bearing
                                Text(
                                  '${qibla.toStringAsFixed(1)}° to Qibla',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 18,
                                    fontFamily: 'serif',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Distance
                                Text(
                                  '${NumberFormat('#,###').format(distKm.round())} km from Mecca',
                                  style: TextStyle(
                                    color: context.textDim,
                                    fontSize: 13,
                                    fontFamily: 'sans-serif',
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Alignment indicator
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: onTarget
                                        ? Colors.green.withOpacity(0.12)
                                        : AppColors.goldDim.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: onTarget
                                          ? Colors.green.withOpacity(0.5)
                                          : AppColors.goldDim.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        onTarget
                                            ? Icons.mosque
                                            : Icons.mosque_outlined,
                                        size: 16,
                                        color: onTarget
                                            ? Colors.green
                                            : AppColors.gold,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        onTarget
                                            ? 'Facing Qibla'
                                            : 'Face the direction of the arrow',
                                        style: TextStyle(
                                          color: onTarget
                                              ? Colors.green
                                              : context.text,
                                          fontSize: 12,
                                          fontFamily: 'sans-serif',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Recalibrate button
                                TextButton.icon(
                                  onPressed: _showCalibrationOverlay,
                                  icon: const Icon(Icons.explore, size: 14),
                                  label: const Text('Recalibrate'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: context.textDim,
                                    textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'sans-serif'),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                // Location footer
                                Text(
                                  '📍 ${pt.cityName} (${pt.lat.toStringAsFixed(4)}°N, ${pt.lng.toStringAsFixed(4)}°E)',
                                  style: TextStyle(
                                    color: context.textDim,
                                    fontSize: 10,
                                    fontFamily: 'sans-serif',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // Calibration overlay
          if (_showCalibration)
            FadeTransition(
              opacity: _fadeCtrl,
              child: GestureDetector(
                onTap: _dismissCalibration,
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _lissajousCtrl,
                          builder: (_, __) {
                            const A = 60.0;
                            const B = 60.0;
                            final t = _lissajousCtrl.value * 2 * pi;
                            final dx = A * sin(t);
                            final dy = B * sin(2 * t);
                            return SizedBox(
                              width: 160,
                              height: 160,
                              child: CustomPaint(
                                painter: _LissajousPainter(
                                  progress: _lissajousCtrl.value,
                                  dotX: dx,
                                  dotY: dy,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Move your phone in a\nfigure-8 motion to\ncalibrate the compass',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 16,
                            fontFamily: 'serif',
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to dismiss',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── No-location placeholder ────────────────────────────────────────────────────

class _NoLocation extends StatelessWidget {
  final LocationService loc;
  const _NoLocation({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 48, color: context.textDim),
            const SizedBox(height: 16),
            Text(
              'Location required for Qibla direction',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.textDim,
                  fontSize: 14,
                  fontFamily: 'sans-serif'),
            ),
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
}

// ── Accuracy indicator ─────────────────────────────────────────────────────────

class _AccuracyIndicator extends StatelessWidget {
  final int level; // 2=high, 1=medium, 0=low
  const _AccuracyIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = level == 2
        ? ('High', '✅', Colors.green)
        : level == 1
            ? ('Medium', '⚠️', Colors.orange)
            : ('Low', '❌', Colors.red);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontFamily: 'sans-serif',
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Painters ───────────────────────────────────────────────────────────────────

class _RosePainter extends CustomPainter {
  final bool isDark;
  const _RosePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final gold = const Color(0xFFD4AF37);
    final bg = isDark ? const Color(0xFF1A1508) : const Color(0xFFFDF3E0);
    final border = isDark ? const Color(0xFF3A2E10) : const Color(0xFFCEB060);
    final dim = isDark ? const Color(0xFF5A4A30) : const Color(0xFF9A7030);

    canvas.drawCircle(center, radius - 2,
        Paint()..color = bg..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius - 2,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Tick marks
    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * pi / 180;
      final major = i % 9 == 0;
      final len = major ? 14.0 : 6.0;
      canvas.drawLine(
        center + Offset(sin(angle), -cos(angle)) * (radius - 14),
        center + Offset(sin(angle), -cos(angle)) * (radius - 14 - len),
        Paint()
          ..color = major ? gold : dim
          ..strokeWidth = major ? 1.5 : 1.0,
      );
    }

    // N / S / E / W labels
    final dirs = [('N', 0.0), ('E', pi / 2), ('S', pi), ('W', 3 * pi / 2)];
    for (final (label, angle) in dirs) {
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
                color: label == 'N' ? gold : dim,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final pos = center +
          Offset(sin(angle), -cos(angle)) * (radius - 34) -
          Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, pos);
    }

    // Center dot
    canvas.drawCircle(center, 5, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(_RosePainter o) => o.isDark != isDark;
}

class _NeedlePainter extends CustomPainter {
  final bool onTarget;
  final bool isDark;
  const _NeedlePainter({required this.onTarget, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final color = onTarget ? Colors.green : const Color(0xFFD4AF37);

    final path = Path();
    final tipY = center.dy - radius * 0.62;
    final baseY = center.dy + radius * 0.28;
    path.moveTo(center.dx, tipY);
    path.lineTo(center.dx - 11, center.dy);
    path.lineTo(center.dx - 4, center.dy);
    path.lineTo(center.dx - 4, baseY);
    path.lineTo(center.dx + 4, baseY);
    path.lineTo(center.dx + 4, center.dy);
    path.lineTo(center.dx + 11, center.dy);
    path.close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter o) =>
      o.onTarget != onTarget || o.isDark != isDark;
}

class _LissajousPainter extends CustomPainter {
  final double progress;
  final double dotX;
  final double dotY;
  const _LissajousPainter(
      {required this.progress, required this.dotX, required this.dotY});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const A = 55.0;
    const B = 55.0;

    // Draw the full path faintly
    final pathPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i <= 200; i++) {
      final t = i / 200 * 2 * pi;
      final x = cx + A * sin(t);
      final y = cy + B * sin(2 * t);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, pathPaint);

    // Dot
    canvas.drawCircle(
      Offset(cx + dotX, cy + dotY),
      6,
      Paint()..color = const Color(0xFFD4AF37),
    );
  }

  @override
  bool shouldRepaint(_LissajousPainter o) => o.progress != progress;
}
