import '../../data/local/uza_database.dart';

/// Window during which a shop counts as "active today" for directory visibility.
const Duration kShopActivityWindow = Duration(hours: 24);

/// Grace period for new boutiques before inactivity rules apply.
const Duration kNewShopGracePeriod = Duration(hours: 48);

/// Days without activity before showing a strong visibility warning.
const int kVisibilityWarningDays = 1;

/// Days without activity before showing rank-drop messaging.
const int kVisibilityCriticalDays = 3;

bool isShopActiveToday(Shop shop, DateTime now) {
  if (shop.lastActiveAt != null) {
    return now.difference(shop.lastActiveAt!) < kShopActivityWindow;
  }
  return now.difference(shop.updatedAt) < kNewShopGracePeriod;
}

int daysSinceLastActivity(Shop shop, DateTime now) {
  final reference = shop.lastActiveAt ?? shop.updatedAt;
  return now.difference(reference).inDays;
}

/// Sort: boosted active → active today → inactive; within groups by recency.
List<Shop> sortShopsByVisibility(List<Shop> shops, DateTime now) {
  final boosted = <Shop>[];
  final active = <Shop>[];
  final inactive = <Shop>[];

  for (final shop in shops) {
    if (shop.boostStatus == 2) {
      boosted.add(shop);
    } else if (isShopActiveToday(shop, now)) {
      active.add(shop);
    } else {
      inactive.add(shop);
    }
  }

  int compareRecency(Shop a, Shop b) {
    final aTime = a.lastActiveAt ?? a.updatedAt;
    final bTime = b.lastActiveAt ?? b.updatedAt;
    return bTime.compareTo(aTime);
  }

  boosted.sort(compareRecency);
  active.sort(compareRecency);
  inactive.sort(compareRecency);

  return [...boosted, ...active, ...inactive];
}

DateTime startOfToday(DateTime now) =>
    DateTime(now.year, now.month, now.day);
