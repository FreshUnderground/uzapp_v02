import 'package:flutter/material.dart';
import '../../data/local/uza_database.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/crypto_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryCircle extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;
  final bool isViewed;

  const StoryCircle({
    super.key,
    required this.story,
    required this.onTap,
    this.isViewed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = story.mediaType == 'video';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Gradient ring for unviewed stories, plain ring for viewed
            Container(
              padding: const EdgeInsets.all(3),
              decoration: isViewed
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    )
                  : const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          UzaColors.primary,
                          UzaColors.secondary,
                          UzaColors.primary,
                        ],
                      ),
                    ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: story.mediaUrl.isNotEmpty
                      ? CachedNetworkImageProvider(
                          CryptoUtils.decrypt(story.mediaUrl),
                        )
                      : null,
                  child: story.mediaUrl.isEmpty
                      ? Icon(
                          isVideo ? Icons.play_circle_outline : Icons.image,
                          color: Colors.grey[400],
                          size: 30,
                        )
                      : null,
                ),
              ),
            ),

            // Video indicator overlay at bottom-right - constrained within circle
            if (isVideo)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: UzaColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
