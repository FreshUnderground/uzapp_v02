import 'package:drift/drift.dart';
import 'connection/connection.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

part 'uza_database.g.dart';

enum ShopType { retail, wholesale }

class Shops extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()(); // ID from MySQL
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get type => textEnum<ShopType>()();
  TextColumn get ownerId => text().nullable()(); // Linked to Auth Uid
  TextColumn get address => text().nullable()();

  // Contact Links
  TextColumn get whatsapp => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();

  // Social Links
  TextColumn get instagramUrl => text().nullable()();
  TextColumn get tiktokUrl => text().nullable()();
  TextColumn get facebookUrl => text().nullable()();
  TextColumn get youtubeUrl => text().nullable()();
  TextColumn get bannerUrl => text().nullable()();
  TextColumn get videoUrl => text().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isBoosted => boolean().withDefault(const Constant(false))();

  // Lifecycle status (0: None, 1: Pending, 2: Active, 3: Rejected)
  IntColumn get boostStatus => integer().withDefault(const Constant(0))();
  IntColumn get bannerStatus => integer().withDefault(const Constant(0))();
  TextColumn get bannerText => text().nullable()();
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  IntColumn get responseTimeMinutes => integer().nullable()();
  TextColumn get commune => text().nullable()();
  TextColumn get city => text().nullable()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get parentId => integer().nullable()();
  IntColumn get level => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get shopId => integer().references(Shops, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  RealColumn get price => real().nullable()();
  TextColumn get category => text().nullable()(); // Legacy string category
  TextColumn get imageUrls => text()(); // Store as JSON string

  BoolColumn get isArrival => boolean().withDefault(const Constant(false))();
  BoolColumn get isPromotion => boolean().withDefault(const Constant(false))();
  IntColumn get stockCount => integer().nullable()();
  BoolColumn get hidePrice => boolean().withDefault(const Constant(false))();
  BoolColumn get showStock => boolean().withDefault(const Constant(false))();
  BoolColumn get isBoosted => boolean().withDefault(const Constant(false))();
  TextColumn get promotionMessage => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Engagement Stats (Synced from server)
  IntColumn get viewsCount => integer().withDefault(const Constant(0))();
  IntColumn get sharesCount => integer().withDefault(const Constant(0))();
  IntColumn get ratingsCount => integer().withDefault(const Constant(0))();
  RealColumn get ratingAvg => real().withDefault(const Constant(0.0))();

  // Lifecycle status (0: None, 1: Pending, 2: Active, 3: Rejected)
  IntColumn get boostStatus => integer().withDefault(const Constant(0))();
  TextColumn get condition => text().withDefault(const Constant('new'))();
  IntColumn get reportCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSold => boolean().withDefault(const Constant(false))();
  TextColumn get metadata => text().nullable()();
}

class Stories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  IntColumn get shopId => integer().references(Shops, #id)();
  TextColumn get mediaUrl => text()();
  TextColumn get mediaType => text()(); // 'image' or 'video'
  BoolColumn get isArrivage => boolean().withDefault(const Constant(false))();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class StoryMedia extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storyId => integer().references(Stories, #id)();
  TextColumn get mediaUrl => text()();
  TextColumn get mediaType => text().withDefault(const Constant('image'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class OfflineQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // 'product', 'shop', 'story', 'user'
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get payload => text()(); // JSON payload
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, syncing, failed, synced
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get entityType => text()(); // 'shops', 'products', 'stories'
  TextColumn get entityData => text()(); // JSON representation of the change
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Analytics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'product', 'story', 'shop'
  TextColumn get interactionType =>
      text()(); // 'view', 'whatsapp', 'call', 'sms', 'social'
  IntColumn get entityId => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class UserProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get remoteId => text().nullable()();
  TextColumn get phone => text().withLength(min: 7, max: 20)();
  TextColumn get name => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isPhoneVerified =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CartItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class UserContacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shopId => integer().references(Shops, #id)();
  TextColumn get userPhone => text()(); // The phone of the person who contacted
  TextColumn get userName => text().nullable()();
  TextColumn get contactType => text()(); // 'whatsapp', 'call', 'sms'
  IntColumn get productId => integer().nullable().references(Products, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WishlistProducts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class FollowedShops extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shopId => integer().references(Shops, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ProductReviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get userName => text().nullable()();
  TextColumn get comment => text()();
  RealColumn get rating => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AppPreferences extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get isDarkMode => boolean().withDefault(const Constant(false))();
  TextColumn get language => text().withDefault(const Constant('fr'))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isLiteMode => boolean().withDefault(const Constant(false))();
  BoolColumn get biometricEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get userCommune => text().nullable()();

  DateTimeColumn get lastSync => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Shops,
    Products,
    Categories,
    Stories,
    SyncQueue,
    OfflineQueue,
    Analytics,
    UserProfiles,
    CartItems,
    UserContacts,
    AppPreferences,
    WishlistProducts,
    FollowedShops,
    ProductReviews,
    StoryMedia,
  ],
)
class UzaDatabase extends _$UzaDatabase {
  UzaDatabase() : super(ensureConnection());

  @override
  int get schemaVersion => 22;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) await m.addColumn(shops, shops.address);
        if (from < 3) {
          await m.addColumn(shops, shops.isBoosted);
          await m.addColumn(products, products.isBoosted);
        }
        if (from < 4) {
          await m.addColumn(products, products.stockCount);
          await m.createTable(userContacts);
        }
        if (from < 5) await m.createTable(appPreferences);
        if (from < 6) await m.addColumn(products, products.showStock);
        if (from < 7) {
          await m.addColumn(shops, shops.bannerUrl);
          await m.addColumn(products, products.promotionMessage);
        }
        if (from < 8) {
          await m.addColumn(shops, shops.bannerStatus);
          await m.addColumn(shops, shops.bannerText);
          await m.addColumn(shops, shops.boostStatus);
          await m.addColumn(products, products.boostStatus);
        }
        if (from < 9) {
          await m.addColumn(appPreferences, appPreferences.lastSync);
        }
        if (from < 10) {
          await m.createTable(categories);
          await m.addColumn(products, products.categoryId);
        }
        if (from < 11) {
          await m.addColumn(shops, shops.isVerified);
        }
        if (from < 12) {
          await m.addColumn(products, products.viewsCount);
          await m.addColumn(products, products.sharesCount);
          await m.addColumn(products, products.ratingsCount);
          await m.addColumn(products, products.ratingAvg);
        }
        if (from < 13) {
          await m.createTable(wishlistProducts);
          await m.createTable(followedShops);
          await m.createTable(productReviews);
        }
        if (from < 14) {
          await m.addColumn(shops, shops.videoUrl);
        }
        if (from < 15) {
          await m.createTable(offlineQueue);
        }
        if (from < 16) {
          await m.addColumn(shops, shops.responseTimeMinutes);
          await m.addColumn(products, products.condition);
          await m.addColumn(products, products.reportCount);
        }
        if (from < 17) {
          await m.addColumn(products, products.isSold);
          await m.addColumn(appPreferences, appPreferences.isLiteMode);
        }
        if (from < 18) {
          await m.addColumn(shops, shops.commune);
          await m.addColumn(shops, shops.city);
          await m.addColumn(appPreferences, appPreferences.userCommune);
        }
        if (from < 19) {
          await m.addColumn(appPreferences, appPreferences.biometricEnabled);
        }
        if (from < 20) {
          await m.addColumn(userProfiles, userProfiles.isPhoneVerified);
        }
        if (from < 21) {
          await customStatement(
            'ALTER TABLE categories ADD COLUMN parent_id INTEGER',
          );
          await customStatement(
            'ALTER TABLE categories ADD COLUMN level INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE products ADD COLUMN metadata TEXT',
          );
          await customStatement(
            'ALTER TABLE shops ADD COLUMN verified_at INTEGER',
          );
          await customStatement('ALTER TABLE shops ADD COLUMN latitude REAL');
          await customStatement('ALTER TABLE shops ADD COLUMN longitude REAL');
          await customStatement("""
            CREATE TABLE story_media (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              story_id INTEGER NOT NULL REFERENCES stories(id),
              media_url TEXT NOT NULL,
              media_type TEXT NOT NULL DEFAULT 'image',
              sort_order INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
            )
          """);
        }
        if (from < 22) {
          await customStatement(
            'ALTER TABLE stories ADD COLUMN is_arrivage INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }
}
