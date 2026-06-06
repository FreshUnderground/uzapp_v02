import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/tr.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../ui/screens/b2b_hub_screen.dart';
import '../../ui/screens/cart_screen.dart';
import '../../ui/screens/discover_feed_screen.dart';
import '../../ui/screens/home_screen.dart';
import '../../ui/screens/messages_screen.dart';
import '../../ui/screens/orders_screen.dart';
import '../../ui/screens/product_detail_screen.dart';
import '../../ui/screens/profile_screen.dart';
import '../../ui/screens/search_screen.dart';
import '../../ui/screens/shop_profile_screen.dart';
import '../../ui/screens/shops_directory_screen.dart';

/// Central route table for deep links and consistent navigation.
class AppRouter {
  static String initialLocation() {
    if (kIsWeb) {
      final path = Uri.base.path;
      if (path.isNotEmpty && path != '/') {
        return path;
      }
    }
    return '/';
  }

  static GoRouter create(GlobalKey<NavigatorState> rootKey) {
    return GoRouter(
      navigatorKey: rootKey,
      initialLocation: initialLocation(),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const _HomeTabPlaceholder(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/discover',
                  builder: (_, __) => const DiscoverFeedScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/shops',
                  builder: (_, __) => const ShopsDirectoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, __) =>
                      const ProfileScreen(showAppBar: false),
                ),
              ],
            ),
          ],
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
              future: context.read<ShopRepository>().resolveShopById(id),
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
              future: context.read<ProductRepository>().resolveProductById(id),
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

/// Placeholder for home tab — actual content rendered by [HomeScreen] overlay.
class _HomeTabPlaceholder extends StatelessWidget {
  const _HomeTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
