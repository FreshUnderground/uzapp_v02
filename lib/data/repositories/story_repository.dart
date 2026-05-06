import 'package:drift/drift.dart';
import '../local/uza_database.dart';

class StoryRepository {
  final UzaDatabase db;

  StoryRepository(this.db);

  /// 24-hour expiry for regular stories
  static const Duration storyExpiry = Duration(hours: 24);

  /// 4-day expiry for arrivages
  static const Duration arrivageExpiry = Duration(days: 4);

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
    return (db.select(db.stories)..where(
          (t) =>
              t.isArrivage.equals(true) &
              t.expiresAt.isBiggerThanValue(now) &
              t.createdAt.isBiggerThanValue(cutoff),
        ))
        .watch();
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

    return await db.transaction(() async {
      // Delete story_media rows for expired stories
      await (db.delete(
        db.storyMedia,
      )..where((t) => t.storyId.isIn(expiredIds))).go();

      // Delete the expired stories
      final count = await (db.delete(
        db.stories,
      )..where((t) => t.id.isIn(expiredIds))).go();

      return count;
    });
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

  /// Watch active arrivages grouped by shopId.
  /// Returns a Map of `shopId` to `List of Story`.
  Stream<Map<int, List<Story>>> watchArrivagesGroupedByShop() {
    final now = DateTime.now();
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
          final grouped = <int, List<Story>>{};
          for (final story in stories) {
            grouped.putIfAbsent(story.shopId, () => []).add(story);
          }
          return grouped;
        });
  }
}
