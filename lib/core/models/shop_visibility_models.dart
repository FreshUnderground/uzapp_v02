import '../utils/shop_visibility_utils.dart';

/// Today's engagement snapshot for a seller dashboard.
class ShopTodayStats {
  final int todayViews;
  final int todayWhatsappClicks;
  final int activeProducts;

  const ShopTodayStats({
    required this.todayViews,
    required this.todayWhatsappClicks,
    required this.activeProducts,
  });
}

/// Local ranking within a commune based on today's views.
class ShopLocalRanking {
  final int rank;
  final int totalShops;
  final int averageTodayViews;
  final String? communeLabel;
  final int? previousRank;

  const ShopLocalRanking({
    required this.rank,
    required this.totalShops,
    required this.averageTodayViews,
    this.communeLabel,
    this.previousRank,
  });

  bool get hasComparison => totalShops > 1;
}

/// Combined visibility insight for seller dashboard alerts.
class ShopVisibilityInsight {
  final ShopTodayStats today;
  final ShopLocalRanking ranking;
  final bool isActiveToday;
  final int daysSinceActivity;

  const ShopVisibilityInsight({
    required this.today,
    required this.ranking,
    required this.isActiveToday,
    required this.daysSinceActivity,
  });

  bool get showWarning =>
      !isActiveToday && daysSinceActivity >= kVisibilityWarningDays;

  bool get showCriticalAlert =>
      !isActiveToday && daysSinceActivity >= kVisibilityCriticalDays;

  bool get rankDropped =>
      ranking.previousRank != null &&
      ranking.previousRank! < ranking.rank &&
      showCriticalAlert;
}
