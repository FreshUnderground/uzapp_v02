import 'package:drift/drift.dart';
import 'package:drift/web.dart';

DatabaseConnection ensureConnection() {
  return DatabaseConnection(WebDatabase.withStorage(
    DriftWebStorage.indexedDb('uzaapp'),
  ));
}
