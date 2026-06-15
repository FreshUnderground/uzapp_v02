import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../utils/page_transitions.dart';
import '../screens/shop_profile_screen.dart';

/// Rotating promotional banner for shops with active paid banner (banner_status = 2).
class BoostBannerCarousel extends StatefulWidget {
  const BoostBannerCarousel({super.key});

  @override
  State<BoostBannerCarousel> createState() => _BoostBannerCarouselState();
}

class _BoostBannerCarouselState extends State<BoostBannerCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Shop>>(
      stream: context.read<ShopRepository>().watchActiveBanners(),
      builder: (context, snapshot) {
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.campaign, color: UzaColors.secondary, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'À la une',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          SlideUpRoute(
                            page: ShopProfileScreen(shop: shop),
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (shop.bannerUrl != null &&
                                shop.bannerUrl!.isNotEmpty)
                              ImageUtils.buildCachedImage(
                                shop.bannerUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 600,
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      UzaColors.primary,
                                      UzaColors.secondary,
                                    ],
                                  ),
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.65),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    shop.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (shop.bannerText != null &&
                                      shop.bannerText!.trim().isNotEmpty)
                                    Text(
                                      shop.bannerText!.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (shops.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  shops.length,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? UzaColors.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
