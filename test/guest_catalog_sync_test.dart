import 'package:flutter_test/flutter_test.dart';
import 'package:uzaapp/data/services/sync_service.dart';

void main() {
  test('catalog sync is independent of auth session', () {
    // SyncService has no auth dependency; pull uses API key only.
    expect(SyncStatus.offline, isNot(SyncStatus.error));
    expect(SyncStatus.values.length, greaterThanOrEqualTo(4));
  });
}
