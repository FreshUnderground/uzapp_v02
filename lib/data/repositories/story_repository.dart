import 'package:drift/drift.dart';
import '../local/uza_database.dart';

class StoryRepository {
  final UzaDatabase db;

  StoryRepository(this.db);

  Stream<List<Story>> watchActiveStories() {
    final now = DateTime.now();
    return (db.select(
      db.stories,
    )..where((t) => t.expiresAt.isBiggerThanValue(now))).watch();
  }

  Future<int> addStory(StoriesCompanion story) async {
    return await db.into(db.stories).insert(story);
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

  /// Watch active stories grouped by shopId.
  /// Returns a Map of `shopId` to `List of Story`.
  Stream<Map<int, List<Story>>> watchStoriesGroupedByShop() {
    final now = DateTime.now();
    return (db.select(db.stories)
          ..where((t) => t.expiresAt.isBiggerThanValue(now))
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
