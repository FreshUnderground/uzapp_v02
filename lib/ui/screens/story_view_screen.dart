import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/utils/crypto_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final VoidCallback? onClose;
  final Map<int, Shop> shopLookup;
  final Future<int> Function(int storyId)? getViewCount;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onClose,
    this.shopLookup = const {},
    this.getViewCount,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  int _currentIndex = 0;
  bool _isPaused = false;
  double _dragOffset = 0.0;

  // Media sub-items for the current story
  List<StoryMediaData> _currentMediaItems = [];
  int _mediaIndex = 0;

  // Video player for video media
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Liked stories (local state only)
  final Set<int> _likedStoryIds = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animController = AnimationController(vsync: this);

    if (widget.stories.isNotEmpty) {
      _loadStory(story: widget.stories[_currentIndex], animateToPage: false);
    }

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.stop();
        _animController.reset();
        _advanceMediaOrStory();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  void _onVideoUpdate() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        !_videoController!.value.isPlaying &&
        _videoController!.value.position >= _videoController!.value.duration) {
      // Video finished playing, advance to next media
      _advanceMediaOrStory();
    }
  }

  void _advanceMediaOrStory() {
    setState(() {
      final totalCount = _getMediaCount();
      // If current story has more media items, go to next media
      if (_mediaIndex + 1 < totalCount) {
        _mediaIndex++;
        _setupCurrentMedia();
      } else {
        // Move to next story
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex++;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          _closeViewer();
        }
      }
    });
  }

  void _goToPreviousMediaOrStory() {
    setState(() {
      if (_mediaIndex > 0) {
        _mediaIndex--;
        _setupCurrentMedia();
      } else if (_currentIndex > 0) {
        _currentIndex--;
        _loadStory(story: widget.stories[_currentIndex]);
      }
    });
  }

  void _closeViewer() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _loadStory({required Story story, bool animateToPage = true}) {
    _disposeVideoController();
    _mediaIndex = 0;
    _currentMediaItems = [];

    // Load media items for this story
    _loadMediaItems(story.id);

    if (animateToPage && _pageController.hasClients) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadMediaItems(int storyId) async {
    try {
      final storyRepo = context.read<StoryRepository>();
      final story = widget.stories[_currentIndex];
      final mediaItems = await storyRepo.getStoryMedia(storyId);

      if (mounted) {
        setState(() {
          // Include the story's main mediaUrl as the first item
          // (it's stored separately from storyMedia child items)
          _currentMediaItems = mediaItems;
        });
        _setupCurrentMedia();
      }
    } catch (e) {
      // Fallback: no media items, use the story's main mediaUrl
      if (mounted) {
        setState(() {
          _currentMediaItems = [];
        });
        _setupCurrentMedia();
      }
    }
  }

  /// Get the current media URL (either from StoryMedia or the story's main mediaUrl)
  String _getCurrentMediaUrl() {
    final story = widget.stories[_currentIndex];

    // If we have media items from storyMedia table
    if (_currentMediaItems.isNotEmpty) {
      // Index 0 = story's main mediaUrl (first image)
      // Index 1+ = media items from storyMedia table
      if (_mediaIndex == 0) {
        // First image: use story's main mediaUrl
        return story.mediaUrl.isNotEmpty
            ? CryptoUtils.decrypt(story.mediaUrl)
            : '';
      } else if (_mediaIndex < _currentMediaItems.length + 1) {
        // Subsequent images: use storyMedia items (adjust index by -1)
        final url = _currentMediaItems[_mediaIndex - 1].mediaUrl;
        return CryptoUtils.decrypt(url);
      }
    }

    // Fallback: no media items, use the story's main mediaUrl
    return story.mediaUrl.isNotEmpty ? CryptoUtils.decrypt(story.mediaUrl) : '';
  }

  /// Get the current media type
  String _getCurrentMediaType() {
    final story = widget.stories[_currentIndex];

    // If we have media items from storyMedia table
    if (_currentMediaItems.isNotEmpty) {
      // Index 0 = story's main mediaUrl (first image)
      // Index 1+ = media items from storyMedia table
      if (_mediaIndex == 0) {
        // First image: use story's main mediaType
        return story.mediaType;
      } else if (_mediaIndex < _currentMediaItems.length + 1) {
        // Subsequent images: use storyMedia items (adjust index by -1)
        return _currentMediaItems[_mediaIndex - 1].mediaType;
      }
    }

    // Fallback: no media items, use the story's main mediaType
    return story.mediaType;
  }

  /// Total media count for current story (includes StoryMedia or just the main one)
  int _getMediaCount() {
    if (_currentMediaItems.isNotEmpty) {
      // Count includes story's main mediaUrl + all storyMedia items
      return _currentMediaItems.length + 1;
    }
    return 1; // Fallback to single media
  }

  void _setupCurrentMedia() {
    _disposeVideoController();
    _animController.stop();
    _animController.reset();

    final mediaType = _getCurrentMediaType();
    if (mediaType == 'video') {
      _setupVideoPlayer();
    } else {
      // Image: use timer-based progress
      _animController.duration = const Duration(seconds: 5);
      if (!_isPaused) {
        _animController.forward();
      }
    }
  }

  void _setupVideoPlayer() {
    final url = _getCurrentMediaUrl();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController!
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() => _isVideoInitialized = true);
            _videoController!.play();
            _videoController!.addListener(_onVideoUpdate);

            // Set animation duration to video duration for progress bar
            final duration = _videoController!.value.duration;
            if (duration.inMilliseconds > 0) {
              _animController.duration = duration;
            } else {
              _animController.duration = const Duration(seconds: 15);
            }
            if (!_isPaused) {
              _animController.forward();
            }
          }
        })
        .catchError((e) {
          // Video failed to load, skip to next
          debugPrint('Video player error: $e');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _advanceMediaOrStory();
          });
        });
  }

  String _getRelativeTime(DateTime createdAt) {
    final localCreatedAt = createdAt.isUtc ? createdAt.toLocal() : createdAt;
    final diff = DateTime.now().difference(localCreatedAt);
    if (diff.isNegative) return "À l'instant";
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes}min";
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  void _onHorizontalTap(double relativeDx, double effectiveWidth) {
    if (relativeDx < effectiveWidth / 3) {
      _goToPreviousMediaOrStory();
    } else if (relativeDx > 2 * effectiveWidth / 3) {
      setState(() {
        _advanceMediaOrStory();
      });
    }
  }

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _isPaused = true);
    _animController.stop();
    _videoController?.pause();
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    setState(() => _isPaused = false);
    _animController.forward();
    _videoController?.play();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    final screenHeight = MediaQuery.of(context).size.height;
    final story = widget.stories[_currentIndex];
    final mediaUrl = _getCurrentMediaUrl();
    final mediaType = _getCurrentMediaType();
    final mediaCount = _getMediaCount();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred background for desktop
          if (isDesktop && mediaType != 'video')
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: mediaUrl,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.6),
                colorBlendMode: BlendMode.darken,
                errorWidget: (_, __, ___) => Container(color: Colors.black),
              ),
            ),

          // Swipe-down-to-close wrapper
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _dragOffset += details.delta.dy;
                if (_dragOffset < 0) _dragOffset = 0;
              });
            },
            onVerticalDragEnd: (details) {
              if (_dragOffset > screenHeight * 0.2) {
                _closeViewer();
              } else {
                setState(() => _dragOffset = 0);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(0, _dragOffset, 0)
                ..setEntry(0, 0, 1 - (_dragOffset / screenHeight) * 0.3)
                ..setEntry(1, 1, 1 - (_dragOffset / screenHeight) * 0.3),
              curve: Curves.easeOut,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 450 : double.infinity,
                  ),
                  child: ClipRRect(
                    borderRadius: isDesktop
                        ? BorderRadius.circular(16)
                        : BorderRadius.zero,
                    child: GestureDetector(
                      onTapDown: (details) {
                        final double screenWidth = MediaQuery.of(
                          context,
                        ).size.width;
                        final double dx = details.globalPosition.dx;

                        double effectiveWidth = isDesktop ? 450 : screenWidth;
                        double startX = isDesktop ? (screenWidth - 450) / 2 : 0;
                        double relativeDx = dx - startX;

                        _onHorizontalTap(relativeDx, effectiveWidth);
                      },
                      onLongPressStart: _onLongPressStart,
                      onLongPressEnd: _onLongPressEnd,
                      child: Stack(
                        children: [
                          // Story content
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: _buildMediaContent(mediaUrl, mediaType),
                          ),

                          // Pause indicator
                          if (_isPaused)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.pause,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),

                          // Story Indicators & Controls
                          Positioned(
                            top: 40.0,
                            left: 10.0,
                            right: 10.0,
                            child: Column(
                              children: [
                                // Progress bars (one per media item in current story)
                                _buildMediaProgressBar(mediaCount),

                                // Header row with shop info
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                    vertical: 12.0,
                                  ),
                                  child: _buildStoryHeader(story, mediaCount),
                                ),
                              ],
                            ),
                          ),

                          // Action bar with interaction buttons
                          Positioned(
                            bottom: 90.0,
                            left: 0,
                            right: 0,
                            child: _buildActionBar(story),
                          ),

                          // View count at bottom
                          Positioned(
                            bottom: 36.0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _StoryViewCount(
                                storyId: story.id,
                                getViewCount: widget.getViewCount,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(String mediaUrl, String mediaType) {
    if (mediaType == 'video') {
      if (_isVideoInitialized && _videoController != null) {
        return FittedBox(
          fit: BoxFit.cover,
          key: ValueKey('video_$_mediaIndex'),
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        );
      } else {
        return Container(
          key: ValueKey('video_loading_$_mediaIndex'),
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }
    }

    return CachedNetworkImage(
      key: ValueKey('img_$_mediaIndex'),
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
        ),
      ),
    );
  }

  Widget _buildMediaProgressBar(int mediaCount) {
    if (mediaCount <= 1 && _currentMediaItems.isEmpty) {
      // Single story, single media — show story-level progress bars
      return Row(
        children: widget.stories
            .asMap()
            .map((i, e) {
              return MapEntry(
                i,
                AnimatedBar(
                  animController: _animController,
                  position: i,
                  currentIndex: _currentIndex,
                ),
              );
            })
            .values
            .toList(),
      );
    }

    // Multi-media story — show media-level progress bars
    return Row(
      children: List.generate(mediaCount, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: _MediaProgressBar(
              animController: _animController,
              isComplete: i < _mediaIndex,
              isCurrent: i == _mediaIndex,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStoryHeader(Story story, int mediaCount) {
    final shop = widget.shopLookup[story.shopId];

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white24,
          backgroundImage: () {
            if (shop?.logoUrl == null || shop!.logoUrl!.isEmpty) return null;
            final decrypted = CryptoUtils.decrypt(shop.logoUrl!);
            if (decrypted.isEmpty || (!decrypted.startsWith('http://') && !decrypted.startsWith('https://'))) return null;
            return CachedNetworkImageProvider(decrypted) as ImageProvider;
          }(),
          child: shop?.logoUrl == null || shop!.logoUrl!.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop?.name ?? 'Boutique',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text(
                    _getRelativeTime(story.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (mediaCount > 1) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${_mediaIndex + 1}/$mediaCount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: _closeViewer,
        ),
      ],
    );
  }

  // ─── Action Bar ────────────────────────────────────────────────────────
  Widget _buildActionBar(Story story) {
    final isLiked = _likedStoryIds.contains(story.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // WhatsApp
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.whatsapp,
              color: const Color(0xFF25D366),
              size: 22,
            ),
            onPressed: () => _openWhatsApp(story),
            tooltip: 'WhatsApp',
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share, size: 24),
            color: Colors.white,
            onPressed: () => _shareStory(story),
            tooltip: 'Partager',
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          // Like
          IconButton(
            icon: AnimatedScale(
              scale: isLiked ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isLiked),
                size: 24,
              ),
            ),
            color: isLiked ? Colors.red : Colors.white,
            onPressed: _toggleLike,
            tooltip: "J'aime",
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          // Comment
          IconButton(
            icon: const Icon(Icons.comment_outlined, size: 24),
            color: Colors.white,
            onPressed: _showCommentSheet,
            tooltip: 'Commentaire',
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(Story story) async {
    Shop? shop = widget.shopLookup[story.shopId];

    // If shop not in lookup, fetch it from the repository
    if (shop == null) {
      final shopRepo = context.read<ShopRepository>();
      shop = await shopRepo.getShopById(story.shopId);
    }

    final number = shop?.whatsapp ?? shop?.phone;

    if (number == null || number.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Numéro WhatsApp non disponible'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final cleanNumber = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir WhatsApp"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _shareStory(Story story) {
    final mediaUrl = _getCurrentMediaUrl();
    Share.share('Découvrez cette offre sur UzaApp: $mediaUrl');
  }

  void _toggleLike() {
    final story = widget.stories[_currentIndex];
    setState(() {
      if (_likedStoryIds.contains(story.id)) {
        _likedStoryIds.remove(story.id);
      } else {
        _likedStoryIds.add(story.id);
      }
    });
  }

  void _showCommentSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 16,
          right: 8,
          top: 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                autofocus: true,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => Navigator.of(sheetContext).pop(),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ),
    ).whenComplete(() => controller.dispose());
  }
}

/// Progress bar for a single media item within a story.
class _MediaProgressBar extends StatelessWidget {
  final AnimationController animController;
  final bool isComplete;
  final bool isCurrent;

  const _MediaProgressBar({
    required this.animController,
    required this.isComplete,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background
            Container(
              height: 3.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            // Fill
            if (isComplete)
              Container(
                height: 3.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              )
            else if (isCurrent)
              AnimatedBuilder(
                animation: animController,
                builder: (context, child) {
                  return Container(
                    height: 3.0,
                    width: constraints.maxWidth * animController.value,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// Displays the view count for a story, fetched asynchronously.
class _StoryViewCount extends StatefulWidget {
  final int storyId;
  final Future<int> Function(int storyId)? getViewCount;
  const _StoryViewCount({required this.storyId, this.getViewCount});

  @override
  State<_StoryViewCount> createState() => _StoryViewCountState();
}

class _StoryViewCountState extends State<_StoryViewCount> {
  int? _viewCount;

  @override
  void initState() {
    super.initState();
    _fetchViewCount();
  }

  @override
  void didUpdateWidget(covariant _StoryViewCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storyId != widget.storyId) {
      _viewCount = null;
      _fetchViewCount();
    }
  }

  Future<void> _fetchViewCount() async {
    final getter = widget.getViewCount;
    if (getter == null) return;
    try {
      final count = await getter(widget.storyId);
      if (mounted) {
        setState(() => _viewCount = count);
      }
    } catch (_) {
      // Silently fail — view count is non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewCount == null || _viewCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            '$_viewCount vues',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AnimatedBar extends StatelessWidget {
  final AnimationController animController;
  final int position;
  final int currentIndex;

  const AnimatedBar({
    super.key,
    required this.animController,
    required this.position,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                _buildContainer(
                  double.infinity,
                  position < currentIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
                position == currentIndex
                    ? AnimatedBuilder(
                        animation: animController,
                        builder: (context, child) {
                          return _buildContainer(
                            constraints.maxWidth * animController.value,
                            Colors.white,
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ],
            );
          },
        ),
      ),
    );
  }

  Container _buildContainer(double width, Color color) {
    return Container(
      height: 5.0,
      width: width,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black26, width: 0.8),
        borderRadius: BorderRadius.circular(3.0),
      ),
    );
  }
}
