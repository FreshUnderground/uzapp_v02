import 'package:drift/drift.dart';
import '../local/uza_database.dart';

class AuthRepository {
  final UzaDatabase db;

  AuthRepository(this.db);

  Stream<UserProfile?> watchCurrentUser() {
    return db.select(db.userProfiles).watchSingleOrNull();
  }

  Future<UserProfile?> getCurrentUser() {
    return db.select(db.userProfiles).getSingleOrNull();
  }

  Future<void> saveProfile(UserProfile profile) {
    // Force ID 1 to maintain a single-user-only constraint
    return db
        .into(db.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: const Value(1),
            remoteId: Value(profile.remoteId),
            phone: profile.phone,
            name: Value(profile.name),
            avatarUrl: Value(profile.avatarUrl),
            passwordHash: Value(profile.passwordHash),
          ),
        );
  }

  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? phone,
    String? passwordHash,
  }) async {
    final current = await getCurrentUser();
    if (current == null) return;

    await (db.update(
      db.userProfiles,
    )..where((t) => t.id.equals(current.id))).write(
      UserProfilesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        avatarUrl: avatarUrl != null ? Value(avatarUrl) : const Value.absent(),
        phone: phone != null ? Value(phone) : const Value.absent(),
        passwordHash: passwordHash != null
            ? Value(passwordHash)
            : const Value.absent(),
      ),
    );
  }

  /// Clears the login session by nullifying [remoteId] while preserving
  /// [phone] and [name] so that shops can be reassociated on next login.
  /// The user profile row is NOT deleted — the phone number is the stable
  /// identifier that links local shops (via [ownerId]) back to the user.
  Future<void> logout() async {
    final current = await getCurrentUser();
    if (current == null) return;
    await (db.update(db.userProfiles)..where((t) => t.id.equals(current.id)))
        .write(const UserProfilesCompanion(remoteId: Value(null)));
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
