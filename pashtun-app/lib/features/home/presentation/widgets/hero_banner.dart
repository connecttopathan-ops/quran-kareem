import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/home_provider.dart';

class HeroBannerCarousel extends ConsumerStatefulWidget {
  const HeroBannerCarousel({super.key});

  @override
  ConsumerState<HeroBannerCarousel> createState() =>
      _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends ConsumerState<HeroBannerCarousel> {
  int _currentIndex = 0;
  final _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(heroBannersProvider);

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider.builder(
            carouselController: _controller,
            options: CarouselOptions(
              height: 340,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              autoPlayCurve: Curves.fastOutSlowIn,
              onPageChanged: (idx, _) => setState(() => _currentIndex = idx),
            ),
            itemCount: banners.length,
            itemBuilder: (context, index, _) {
              final banner = banners[index];
              return GestureDetector(
                onTap: () => context.push(banner.route),
                child: _BannerSlide(banner: banner),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (i) {
                final isActive = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Colors.white.withAlpha(153),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final HeroBanner banner;

  const _BannerSlide({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (banner.imageUrl != null)
          CachedNetworkImage(
            imageUrl: banner.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.accent),
            errorWidget: (_, __, ___) => Container(color: AppColors.accent),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, Color(0xFF3D2B1F)],
              ),
            ),
          ),
        // Gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withAlpha(179),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
        // Text content
        Positioned(
          bottom: 48,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                banner.title,
                style: AppTextStyles.displayMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                banner.subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withAlpha(204),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(120, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(banner.cta),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
