import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/tr.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../ui/screens/b2b_hub_screen.dart';
import '../../ui/screens/cart_screen.dart';
import '../../ui/screens/home_screen.dart';
import '../../ui/screens/messages_screen.dart';
import '../../ui/screens/orders_screen.dart';
import '../../ui/screens/product_detail_screen.dart';
import '../../ui/screens/search_screen.dart';
import '../../ui/screens/shop_profile_screen.dart';

/// Central route table for deep links and consistent navigation.
class AppRouter {
  static GoRouter create(GlobalKey<NavigatorState> rootKey) {
    return GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
            final shortcut = state.uri.queryParameters['shortcut'];
            var index = tab ?? 0;
            if (shortcut == 'shops') index = 2;
            return HomeScreen(initialIndex: index.clamp(0, 3));
          },
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => const SearchScreen(),
        ),
        GoRoute(
          path: '/cart',
          builder: (_, __) => const CartScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, __) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (_, __) => const MessagesScreen(),
        ),
        GoRoute(
          path: '/b2b',
          builder: (_, __) => const B2BHubScreen(),
        ),
        GoRoute(
          path: '/shop/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return Scaffold(
                body: Center(child: Text(tr(context, 'shop_not_found'))),
              );
            }
            return FutureBuilder<Shop?>(
              future: context.read<ShopRepository>().getShopById(id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Scaffold(
                    body: Center(child: Text(tr(context, 'shop_not_found'))),
                  );
                }
                return ShopProfileScreen(shop: snapshot.data!);
              },
            );
          },
        ),
        GoRoute(
          path: '/product/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return Scaffold(
                body: Center(child: Text(tr(context, 'product_not_found'))),
              );
            }
            return FutureBuilder<Product?>(
              future: context.read<ProductRepository>().getProductById(id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Scaffold(
                    body: Center(
                      child: Text(tr(context, 'product_not_found')),
                    ),
                  );
                }
                return ProductDetailScreen(product: snapshot.data!);
              },
            );
          },
        ),
      ],
    );
  }
}
