import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/res/uza_colors.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/local/uza_database.dart';
import '../../core/utils/image_utils.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;


  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_itemCount == 0) return;
      if (_currentPage < _itemCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.watch<ShopRepository>();

    return StreamBuilder<List<Shop>>(
      stream: shopRepo.watchActiveBanners(),
      builder: (context, snapshot) {
        final List<Map<String, String>> currentAds = [];
        
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          for (var shop in snapshot.data!) {
            currentAds.add({
              'title': shop.name,
              'subtitle': shop.bannerText ?? 'Visitez notre boutique',
              'image': shop.bannerUrl ?? '',
              'tag': 'BOUTIQUE',
            });
          }
        }
        
        if (currentAds.isEmpty) return const SizedBox.shrink();

        _itemCount = currentAds.length;

        return Column(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _itemCount,
                itemBuilder: (context, index) {
                  final ad = currentAds[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        try {
                          value = _pageController.page! - index;
                          value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                        } catch (_) {}
                      }
                      return Center(
                        child: SizedBox(
                          height: Curves.easeOut.transform(value) * 180,
                          width: Curves.easeOut.transform(value) * MediaQuery.of(context).size.width,
                          child: child,
                        ),
                      );
                    },
                    child: _buildAdCard(ad),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildIndicators(_itemCount),
          ],
        );
      }
    );
  }

  Widget _buildAdCard(Map<String, String> ad) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: ImageUtils.buildCachedImage(
                ad['image'],
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ColorFilter.mode(Colors.white.withValues(alpha: 0.1), BlendMode.overlay),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [UzaColors.primary, UzaColors.primary.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ad['tag']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ad['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ad['subtitle']!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentPage == index 
              ? UzaColors.primary 
              : UzaColors.primary.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}
