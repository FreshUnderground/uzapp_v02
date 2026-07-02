import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/res/uza_colors.dart';

class Skeletons {
  static Widget productCard(BuildContext context) {
    return const ProductCardSkeleton();
  }

  static Widget shopCard(BuildContext context) {
    return const ShopCardSkeleton();
  }

  static Widget arrivageCard(BuildContext context) {
    return const ArrivageCardSkeleton();
  }

  static Widget storyCircle(BuildContext context) {
    return const StoryCircleSkeleton();
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmer = UzaColors.shimmerOf(context);
    return Shimmer.fromColors(
      baseColor: shimmer.base,
      highlightColor: shimmer.highlight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: shimmer.container,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: Container(
                decoration: BoxDecoration(
                  color: shimmer.container,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: shimmer.container,
                  ),
                  const SizedBox(height: 4),
                  Container(height: 10, width: 60, color: shimmer.container),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopCardSkeleton extends StatelessWidget {
  const ShopCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmer = UzaColors.shimmerOf(context);
    return Shimmer.fromColors(
      baseColor: shimmer.base,
      highlightColor: shimmer.highlight,
      child: Container(
        decoration: BoxDecoration(
          color: shimmer.container,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: shimmer.container,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 14, width: 100, color: shimmer.container),
                    const SizedBox(height: 4),
                    Container(height: 10, width: 60, color: shimmer.container),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArrivageCardSkeleton extends StatelessWidget {
  const ArrivageCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmer = UzaColors.shimmerOf(context);
    return Shimmer.fromColors(
      baseColor: shimmer.base,
      highlightColor: shimmer.highlight,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: shimmer.container,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class StoryCircleSkeleton extends StatelessWidget {
  const StoryCircleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmer = UzaColors.shimmerOf(context);
    return Shimmer.fromColors(
      baseColor: shimmer.base,
      highlightColor: shimmer.highlight,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: shimmer.container,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 10, width: 50, color: shimmer.container),
          ],
        ),
      ),
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.86,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const ProductCardSkeleton();
      },
    );
  }
}
