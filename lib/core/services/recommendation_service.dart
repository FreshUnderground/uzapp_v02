import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';

/// Simple on-device recommendations (category + recency). No ML required.
class RecommendationService {
  final ProductRepository productRepository;

  RecommendationService(this.productRepository);

  Future<List<Product>> similarProducts({
    required Product source,
    int limit = 12,
  }) async {
    final all = await productRepository.getProductsByShop(source.shopId);
    final sameCategory = all
        .where(
          (p) =>
              p.id != source.id &&
              (p.categoryId == source.categoryId ||
                  p.category == source.category),
        )
        .take(limit)
        .toList();
    if (sameCategory.length >= limit) return sameCategory;
    final fallback = all.where((p) => p.id != source.id).take(limit).toList();
    return sameCategory.isNotEmpty ? sameCategory : fallback;
  }
}
