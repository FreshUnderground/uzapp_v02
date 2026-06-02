import 'package:flutter_test/flutter_test.dart';
import 'package:uzaapp/data/services/sync_service.dart';

void main() {
  group('SyncStatus', () {
    test('offline is distinct from error', () {
      expect(SyncStatus.offline, isNot(SyncStatus.error));
      expect(SyncStatus.values, contains(SyncStatus.offline));
    });
  });
}
