import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Wrap product images in Hero for smooth list-to-detail transitions
class HeroProductImage extends StatelessWidget {
  final String heroTag;
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const HeroProductImage({
    super.key,
    required this.heroTag,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, _) => Container(
        color: Colors.grey.withValues(alpha: 0.1),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, _, _) => Container(
        color: Colors.grey.withValues(alpha: 0.1),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        ),
      ),
    );

    return Hero(
      tag: heroTag,
      child: borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: image)
          : image,
    );
  }
}
