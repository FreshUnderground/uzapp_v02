import 'package:drift/drift.dart';

import '../local/uza_database.dart';

class ReviewRepository {
  final UzaDatabase db;

  ReviewRepository(this.db);

  Stream<List<ProductReview>> watchReviewsForProduct(int productId) {
    return (db.select(db.productReviews)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<double> averageRating(int productId) async {
    final rows = await (db.select(db.productReviews)
          ..where((t) => t.productId.equals(productId)))
        .get();
    if (rows.isEmpty) return 0;
    return rows.map((r) => r.rating).reduce((a, b) => a + b) / rows.length;
  }

  Future<int> addReview({
    required int productId,
    required double rating,
    required String comment,
    String? userName,
  }) {
    return db.into(db.productReviews).insert(
          ProductReviewsCompanion.insert(
            productId: productId,
            rating: rating,
            comment: comment,
            userName: Value(userName),
          ),
        );
  }

  Future<bool> hasReviewForOrder(int productId, String userName) async {
    final row = await (db.select(db.productReviews)
          ..where(
            (t) =>
                t.productId.equals(productId) &
                t.userName.equals(userName),
          ))
        .getSingleOrNull();
    return row != null;
  }
}
