import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/local/uza_database.dart';

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
        setState(() {
          if (_currentIndex + 1 < widget.stories.length) {
            _currentIndex++;
            _loadStory(story: widget.stories[_currentIndex]);
          } else {
            _closeViewer();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _closeViewer() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _loadStory({required Story story, bool animateToPage = true}) {
    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(seconds: 5);
    _animController.forward();

    if (animateToPage && _pageController.hasClients) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getRelativeTime(DateTime createdAt) {
    // If createdAt is in UTC (from server), convert to local for accurate diff
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
      setState(() {
        if (_currentIndex - 1 >= 0) {
          _currentIndex--;
          _loadStory(story: widget.stories[_currentIndex]);
        }
      });
    } else if (relativeDx > 2 * effectiveWidth / 3) {
      setState(() {
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex++;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          _closeViewer();
        }
      });
    }
  }

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _isPaused = true);
    _animController.stop();
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    setState(() => _isPaused = false);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred background for desktop
          if (isDesktop)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.stories[_currentIndex].mediaUrl,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.6),
                colorBlendMode: BlendMode.darken,
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
                          // Story content with crossfade
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: CachedNetworkImage(
                              key: ValueKey(_currentIndex),
                              imageUrl: widget.stories[_currentIndex].mediaUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
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
                                // Progress bars
                                Row(
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
                                ),

                                // Header row with shop info
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                    vertical: 12.0,
                                  ),
                                  child: _buildStoryHeader(),
                                ),
                              ],
                            ),
                          ),

                          // View count at bottom
                          Positioned(
                            bottom: 40.0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _StoryViewCount(
                                storyId: widget.stories[_currentIndex].id,
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

  Widget _buildStoryHeader() {
    final story = widget.stories[_currentIndex];
    final shop = widget.shopLookup[story.shopId];

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white24,
          backgroundImage: shop?.logoUrl != null && shop!.logoUrl!.isNotEmpty
              ? CachedNetworkImageProvider(shop.logoUrl!)
              : null,
          child: shop?.logoUrl == null || shop!.logoUrl!.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
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
            Text(
              _getRelativeTime(story.createdAt),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: _closeViewer,
        ),
      ],
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
