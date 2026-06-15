import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import '../local/uza_database.dart';
import '../services/sync_service.dart';
import '../../core/utils/image_utils.dart';

/// One displayable slide for a story/arrivage (main media + story_media children).
class StoryMediaSlide {
  final String mediaUrl;
  final String mediaType;

  const StoryMediaSlide({
    required this.mediaUrl,
    required this.mediaType,
  });
}

/// One feed entry = one media item of an active arrivage.
/// Stories with no StoryMedia row fall back to their own mediaUrl.
class ArrivageMediaItem {
  final int storyId;
  final int shopId;
  final String mediaUrl; // encrypted (as stored in DB)
  final String mediaType; // 'image' or 'video'

  const ArrivageMediaItem({
    required this.storyId,
    required this.shopId,
    required this.mediaUrl,
    required this.mediaType,
  });
}

class StoryRepository {
  final UzaDatabase db;
  final SyncService? syncService;

  StoryRepository(this.db, {this.syncService});

  /// 24-hour expiry for regular stories
  static const Duration storyExpiry = Duration(hours: 24);

  /// 4-day expiry for arrivages
  static const Duration arrivageExpiry = Duration(days: 4);

  /// Most recent story in a shop group — used for feed thumbnails.
  static Story previewStoryForGroup(List<Story> stories) {
    assert(stories.isNotEmpty);
    return stories.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
  }

  static List<Story> activeStoriesOnly(List<Story> stories) {
    final now = DateTime.now();
    return stories.where((s) => s.expiresAt.isAfter(now)).toList();
  }

  Future<List<String?>> _collectStoryMediaUrls(int storyId) async {
    final story = await (db.select(db.stories)
          ..where((t) => t.id.equals(storyId)))
        .getSingleOrNull();
    if (story == null) return [];

    final mediaRows = await (db.select(db.storyMedia)
          ..where((t) => t.storyId.equals(storyId)))
        .get();

    return [
      story.mediaUrl,
      ...mediaRows.map((m) => m.mediaUrl),
    ];
  }

  Future<void> _hardDeleteStoryLocally(int storyId) async {
    await db.transaction(() async {
      await (db.delete(db.storyMedia)
            ..where((t) => t.storyId.equals(storyId)))
          .go();
      await (db.delete(db.stories)..where((t) => t.id.equals(storyId))).go();
    });
  }

  int? _serverStoryId(Story story) {
    if (story.remoteId != null && story.remoteId!.isNotEmpty) {
      return int.tryParse(story.remoteId!) ??
          (story.remoteId == story.id.toString() ? story.id : null);
    }
    return story.id;
  }

  /// Watch active regular stories (isArrivage=false, 24h expiry).
  Stream<List<Story>> watchActiveStories() {
    final now = DateTime.now();
    final cutoff = now.subtract(storyExpiry);
    return (db.select(db.stories)..where(
          (t) =>
              t.isArrivage.equals(false) &
              t.expiresAt.isBiggerThanValue(now) &
              t.createdAt.isBiggerThanValue(cutoff),
        ))
        .watch();
  }

  /// Watch active arrivages (isArrivage=true, 4-day expiry).
  Stream<List<Story>> watchActiveArrivages() {
    final now = DateTime.now();
    final cutoff = now.subtract(arrivageExpiry);
    developer.log(
      'watchActiveArrivages: now=$now, cutoff=$cutoff, arrivageExpiry=$arrivageExpiry',
      name: 'StoryRepo',
    );
    return (db.select(db.stories)..where(
          (t) =>
              t.isArrivage.equals(true) &
              t.expiresAt.isBiggerThanValue(now) &
              t.createdAt.isBiggerThanValue(cutoff),
        ))
        .watch()
        .map((stories) {
          developer.log(
            'watchActiveArrivages: found ${stories.length} active arrivages',
            name: 'StoryRepo',
          );
          for (var story in stories) {
            developer.log(
              '  - Story ${story.id}: shopId=${story.shopId}, isArrivage=${story.isArrivage}, createdAt=${story.createdAt}, expiresAt=${story.expiresAt}',
              name: 'StoryRepo',
            );
          }
          return stories;
        });
  }

  /// Add a regular story (24h expiry, single media, no story_media children).
  Future<int> addStory(StoriesCompanion story) async {
    final expiresAtValue = story.expiresAt.present
        ? story.expiresAt.value
        : DateTime.now().add(storyExpiry);
    final adjustedStory = story.copyWith(
      expiresAt: Value(expiresAtValue),
      isArrivage: const Value(false),
    );
    return await db.into(db.stories).insert(adjustedStory);
  }

  /// Creates an arrivage with linked media items (4-day expiry, isArrivage=true).
  Future<int> addStoryWithMedia(
    StoriesCompanion story,
    List<StoryMediaCompanion> mediaItems,
  ) async {
    final expiresAtValue = story.expiresAt.present
        ? story.expiresAt.value
        : DateTime.now().add(arrivageExpiry);
    final adjustedStory = story.copyWith(
      expiresAt: Value(expiresAtValue),
      isArrivage: const Value(true),
    );

    return await db.transaction(() async {
      final storyId = await db.into(db.stories).insert(adjustedStory);

      for (var i = 0; i < mediaItems.length; i++) {
        final media = mediaItems[i];
        await db
            .into(db.storyMedia)
            .insert(
              StoryMediaCompanion.insert(
                storyId: storyId,
                mediaUrl: media.mediaUrl.present ? media.mediaUrl.value : '',
                mediaType: media.mediaType.present
                    ? media.mediaType
                    : const Value('image'),
                sortOrder: Value(
                  media.sortOrder.present ? media.sortOrder.value : i,
                ),
              ),
            );
      }

      return storyId;
    });
  }

  /// Watch all media items for a given story.
  Stream<List<StoryMediaData>> watchStoryMedia(int storyId) {
    return (db.select(db.storyMedia)
          ..where((t) => t.storyId.equals(storyId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Get all media items for a given story (one-shot).
  Future<List<StoryMediaData>> getStoryMedia(int storyId) {
    return (db.select(db.storyMedia)
          ..where((t) => t.storyId.equals(storyId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Thumbnail for list cards: main mediaUrl, or first story_media row.
  Future<String?> resolveStoryPreviewUrl(Story story) async {
    if (story.mediaUrl.isNotEmpty) return story.mediaUrl;
    final children = await getStoryMedia(story.id);
    for (final child in children) {
      if (child.mediaUrl.isNotEmpty) return child.mediaUrl;
    }
    return null;
  }

  /// Ordered slides for story viewer (main + children, no duplicates).
  Future<List<StoryMediaSlide>> getStoryMediaSlides(Story story) async {
    final children = await getStoryMedia(story.id);
    final slides = <StoryMediaSlide>[];

    if (story.mediaUrl.isNotEmpty) {
      slides.add(
        StoryMediaSlide(
          mediaUrl: story.mediaUrl,
          mediaType: story.mediaType,
        ),
      );
    }

    for (final child in children) {
      if (child.mediaUrl.isEmpty) continue;
      final isDuplicate =
          slides.isNotEmpty && child.mediaUrl == slides.first.mediaUrl;
      if (!isDuplicate) {
        slides.add(
          StoryMediaSlide(
            mediaUrl: child.mediaUrl,
            mediaType: child.mediaType,
          ),
        );
      }
    }

    return slides;
  }

  /// Delete stories that have expired, along with their media items.
  /// Returns the number of stories deleted.
  Future<int> deleteExpiredStories() async {
    final now = DateTime.now();

    // Find expired story IDs
    final expiredStories = await (db.select(
      db.stories,
    )..where((t) => t.expiresAt.isSmallerThanValue(now))).get();

    if (expiredStories.isEmpty) return 0;

    final expiredIds = expiredStories.map((s) => s.id).toList();
    final mediaUrls = <String?>[];
    for (final id in expiredIds) {
      mediaUrls.addAll(await _collectStoryMediaUrls(id));
    }

    final count = await db.transaction(() async {
      await (db.delete(
        db.storyMedia,
      )..where((t) => t.storyId.isIn(expiredIds))).go();

      return await (db.delete(
        db.stories,
      )..where((t) => t.id.isIn(expiredIds))).go();
    });

    await ImageUtils.evictCachedSources(mediaUrls);
    return count;
  }

  /// Delete a specific story by ID (for shop owners)
  Future<void> deleteStory(int storyId) async {
    final mediaUrls = await _collectStoryMediaUrls(storyId);
    await _hardDeleteStoryLocally(storyId);
    await ImageUtils.evictCachedSources(mediaUrls);
  }

  /// Hard-delete locally, push DELETE to server, evict images, full reset sync.
  Future<void> deleteStoryWithSync(int storyId) async {
    final story = await (db.select(
      db.stories,
    )..where((t) => t.id.equals(storyId))).getSingleOrNull();

    if (story == null) {
      developer.log('Story not found: $storyId', name: 'StoryRepo');
      return;
    }

    final mediaUrls = await _collectStoryMediaUrls(storyId);
    final serverId = _serverStoryId(story);

    await _hardDeleteStoryLocally(storyId);
    await ImageUtils.evictCachedSources(mediaUrls);

    if (syncService != null && serverId != null) {
      await syncService!.markStoryDeletedRemotely(serverId.toString());
      await syncService!.addToQueue('DELETE', 'stories', {'id': serverId});
      developer.log(
        'Queued story deletion for sync: serverId=$serverId',
        name: 'StoryRepo',
      );
      await syncService!.forcePush();
    } else {
      developer.log(
        'Story deletion NOT synced - missing syncService or serverId',
        name: 'StoryRepo',
      );
    }
  }

  Future<void> logStoryView(int storyId) async {
    await db
        .into(db.analytics)
        .insert(
          AnalyticsCompanion.insert(
            entityType: 'story',
            entityId: storyId,
            interactionType: 'view',
          ),
        );
  }

  /// Fetch all active (non-expired) stories for a specific shop.
  Future<List<Story>> getStoriesForShop(int shopId) {
    final now = DateTime.now();
    return (db.select(db.stories)
          ..where(
            (t) => t.shopId.equals(shopId) & t.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Count view analytics entries for a specific story.
  Future<int> getStoryViewCount(int storyId) async {
    final rows =
        await (db.select(db.analytics)..where(
              (t) =>
                  t.entityId.equals(storyId) &
                  t.entityType.equals('story') &
                  t.interactionType.equals('view'),
            ))
            .get();
    return rows.length;
  }

  /// Watch active regular stories grouped by shopId (stories only, not arrivages).
  /// Returns a Map of `shopId` to `List of Story`.
  Stream<Map<int, List<Story>>> watchStoriesGroupedByShop() {
    final now = DateTime.now();
    return (db.select(db.stories)
          ..where(
            (t) =>
                t.isArrivage.equals(false) & t.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.shopId),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch()
        .map((stories) {
          final grouped = <int, List<Story>>{};
          for (final story in stories) {
            grouped.putIfAbsent(story.shopId, () => []).add(story);
          }
          return grouped;
        });
  }

  /// Watch active regular stories (isArrivage=false) for a specific shop.
  Stream<List<Story>> watchStoriesByShop(int shopId) {
    final now = DateTime.now();
    return (db.select(db.stories)
          ..where(
            (t) =>
                t.shopId.equals(shopId) &
                t.isArrivage.equals(false) &
                t.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch active arrivages (isArrivage=true) for a specific shop.
  Stream<List<Story>> watchArrivagesByShop(int shopId) {
    final now = DateTime.now();
    return (db.select(db.stories)
          ..where(
            (t) =>
                t.shopId.equals(shopId) &
                t.isArrivage.equals(true) &
                t.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<Story?> getStoryById(int id) {
    return (db.select(db.stories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Story?> findStoryByAnyId(int id) async {
    final byLocal = await getStoryById(id);
    if (byLocal != null) return byLocal;
    return (db.select(db.stories)
          ..where((t) => t.remoteId.equals(id.toString())))
        .getSingleOrNull();
  }

  Future<List<Story>> getActiveArrivagesByShop(int shopId) {
    final now = DateTime.now();
    return (db.select(db.stories)
          ..where(
            (t) =>
                t.shopId.equals(shopId) &
                t.isArrivage.equals(true) &
                t.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Watch active arrivages grouped by shopId.
  /// Returns a Map of `shopId` to `List of Story`.
  Stream<Map<int, List<Story>>> watchArrivagesGroupedByShop() {
    final now = DateTime.now();
    developer.log('watchArrivagesGroupedByShop: now=$now', name: 'StoryRepo');
    return (db.select(db.stories)
          ..where(
            (t) =>
                t.isArrivage.equals(true) & t.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.shopId),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch()
        .map((stories) {
          developer.log(
            'watchArrivagesGroupedByShop: raw stories count=${stories.length}',
            name: 'StoryRepo',
          );
          for (var story in stories) {
            developer.log(
              '  - Story ${story.id}: shopId=${story.shopId}, createdAt=${story.createdAt}, expiresAt=${story.expiresAt}',
              name: 'StoryRepo',
            );
          }
          final grouped = <int, List<Story>>{};
          for (final story in stories) {
            grouped.putIfAbsent(story.shopId, () => []).add(story);
          }
          developer.log(
            'watchArrivagesGroupedByShop: grouped into ${grouped.length} shops',
            name: 'StoryRepo',
          );
          return grouped;
        });
  }

  bool _isDisplayableArrivageMedia(ArrivageMediaItem item) {
    if (item.mediaUrl.isEmpty) return false;
    if (item.mediaType == 'video') {
      return ImageUtils.resolveImageUrl(item.mediaUrl)?.isNotEmpty ?? false;
    }
    return ImageUtils.hasDisplayableImage(item.mediaUrl);
  }

  /// JOIN stream: one entry per StoryMedia row, fallback to story.mediaUrl.
  /// Re-emits whenever stories OR storyMedia changes — no race condition.
  Stream<List<ArrivageMediaItem>> watchArrivageMediaFeed() {
    final now = DateTime.now();

    // Apply where/orderBy on SimpleSelectStatement first, then join
    final baseSelect = db.select(db.stories)
      ..where(
        (t) => t.isArrivage.equals(true) & t.expiresAt.isBiggerThanValue(now),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.shopId),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);

    final joinQuery = baseSelect.join([
      leftOuterJoin(
        db.storyMedia,
        db.storyMedia.storyId.equalsExp(db.stories.id),
      ),
    ]);

    return joinQuery.watch().map((rows) {
      final items = <ArrivageMediaItem>[];
      final storiesWithMedia = <int>{};

      for (final row in rows) {
        final story = row.readTable(db.stories);
        final media = row.readTableOrNull(db.storyMedia);

        if (media != null) {
          if (media.mediaUrl.isEmpty) continue;
          storiesWithMedia.add(story.id);
          items.add(
            ArrivageMediaItem(
              storyId: story.id,
              shopId: story.shopId,
              mediaUrl: media.mediaUrl,
              mediaType: media.mediaType,
            ),
          );
        } else if (!storiesWithMedia.contains(story.id)) {
          if (story.mediaUrl.isEmpty) continue;
          items.add(
            ArrivageMediaItem(
              storyId: story.id,
              shopId: story.shopId,
              mediaUrl: story.mediaUrl,
              mediaType: story.mediaType,
            ),
          );
        }
      }

      final filtered = items
          .where((item) => _isDisplayableArrivageMedia(item))
          .toList();

      developer.log(
        'watchArrivageMediaFeed: ${filtered.length} media entries',
        name: 'StoryRepo',
      );
      return filtered;
    });
  }
}
