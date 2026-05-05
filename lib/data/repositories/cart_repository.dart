import 'package:drift/drift.dart';
import '../local/uza_database.dart';

class CartRepository {
  final UzaDatabase db;

  CartRepository(this.db);

  Stream<List<CartItem>> watchCartItems() {
    return db.select(db.cartItems).watch();
  }

  Future<List<CartItem>> getCartItems() {
    return db.select(db.cartItems).get();
  }

  Future<void> addToCart(int productId, {int quantity = 1}) async {
    final existing = await (db.select(db.cartItems)..where((t) => t.productId.equals(productId))).getSingleOrNull();

    if (existing != null) {
      await (db.update(db.cartItems)..where((t) => t.id.equals(existing.id))).write(
        CartItemsCompanion(
          quantity: Value(existing.quantity + quantity),
        ),
      );
    } else {
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              productId: productId,
              quantity: Value(quantity),
            ),
          );
    }
  }

  Future<void> removeFromCart(int cartItemId) {
    return (db.delete(db.cartItems)..where((t) => t.id.equals(cartItemId))).go();
  }

  Future<void> updateQuantity(int cartItemId, int quantity) {
    return (db.update(db.cartItems)..where((t) => t.id.equals(cartItemId))).write(
      CartItemsCompanion(quantity: Value(quantity)),
    );
  }

  Future<void> clearCart() {
    return db.delete(db.cartItems).go();
  }

  /// Joined query to get products in cart
  Stream<List<CartItemWithProduct>> watchCartWithProducts() {
    final query = db.select(db.cartItems).join([
      innerJoin(db.products, db.products.id.equalsExp(db.cartItems.productId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CartItemWithProduct(
          cartItem: row.readTable(db.cartItems),
          product: row.readTable(db.products),
        );
      }).toList();
    });
  }

  Stream<int> watchCartCount() {
    final count = db.cartItems.quantity.sum();
    final query = db.selectOnly(db.cartItems)..addColumns([count]);

    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }
}

class CartItemWithProduct {
  final CartItem cartItem;
  final Product product;

  CartItemWithProduct({required this.cartItem, required this.product});
}
