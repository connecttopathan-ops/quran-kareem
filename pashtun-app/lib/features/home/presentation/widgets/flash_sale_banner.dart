import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/home_provider.dart';

class FlashSaleBanner extends ConsumerStatefulWidget {
  const FlashSaleBanner({super.key});

  @override
  ConsumerState<FlashSaleBanner> createState() => _FlashSaleBannerState();
}

class _FlashSaleBannerState extends ConsumerState<FlashSaleBanner> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final sale = ref.read(flashSaleProvider);
      if (sale == null || !mounted) return;
      setState(() {
        final diff = sale.endTime.difference(DateTime.now());
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final sale = ref.watch(flashSaleProvider);
    if (sale == null || !sale.isActive) return const SizedBox.shrink();

    final h = _pad(_remaining.inHours);
    final m = _pad(_remaining.inMinutes.remainder(60));
    final s = _pad(_remaining.inSeconds.remainder(60));

    return GestureDetector(
      onTap: () => context.push('/collection/sale'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.saleRed,
        child: Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${sale.title} — ${sale.discountPercent}% OFF',
                style: AppTextStyles.labelLarge
                    .copyWith(color: Colors.white),
              ),
            ),
            _CountdownUnit(value: h, label: 'HH'),
            const _Colon(),
            _CountdownUnit(value: m, label: 'MM'),
            const _Colon(),
            _CountdownUnit(value: s, label: 'SS'),
          ],
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final String value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: AppTextStyles.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(':',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
