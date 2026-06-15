import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/story_repository.dart';
import '../../core/utils/image_utils.dart';

/// Thumbnail for an arrivage card — uses story.mediaUrl or first story_media row.
class ArrivageThumbnail extends StatelessWidget {
  final Story story;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? placeholder;

  const ArrivageThumbnail({
    super.key,
    required this.story,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final storyRepo = context.read<StoryRepository>();

    return FutureBuilder<String?>(
      future: storyRepo.resolveStoryPreviewUrl(story),
      builder: (context, snapshot) {
        final previewUrl = snapshot.data;
        final hasMedia = previewUrl != null && previewUrl.isNotEmpty;

        if (!hasMedia) {
          return errorWidget ??
              Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey[400],
                  size: 36,
                ),
              );
        }

        return ImageUtils.buildCachedImage(
          previewUrl,
          fit: fit,
          placeholder: placeholder,
          errorWidget: errorWidget ??
              Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey[400],
                  size: 36,
                ),
              ),
        );
      },
    );
  }
}
