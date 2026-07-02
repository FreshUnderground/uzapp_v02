import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/deep_link_service.dart';
import '../../ui/components/async_content.dart';
import '../../core/l10n/tr.dart';
import '../../data/models/ya_cope_listing.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../ui/components/desktop_route_wrapper.dart';
import '../../ui/components/desktop_shell.dart';
import '../../ui/components/home_app_actions.dart';
import '../../ui/screens/b2b_hub_screen.dart';
import '../../ui/screens/admin_screen.dart';
import '../../ui/screens/cart_screen.dart';
import '../../ui/screens/discover_feed_screen.dart';
import '../../ui/screens/home_screen.dart';
import '../../ui/screens/messages_screen.dart';
import '../../ui/screens/orders_screen.dart';
import '../../ui/screens/my_deliveries_screen.dart';
import '../../ui/screens/product_detail_screen.dart';
import '../../ui/screens/profile_screen.dart';
import '../../ui/screens/search_screen.dart';
import '../../ui/screens/shop_profile_screen.dart';
import '../../ui/screens/shops_directory_screen.dart';
import '../../ui/screens/ya_cope_feed_screen.dart';
import '../../ui/screens/ya_cope_detail_screen.dart';
import '../../data/repositories/ya_cope_repository.dart';

/// Central route table for deep links and consistent navigation.
class AppRouter {
  static String initialLocation() {
    final launch = DeepLinkService.consumeLaunchPath();
    if (launch != null && launch.isNotEmpty) {
      return launch;
    }
    if (kIsWeb) {
      final path = Uri.base.path;
      if (isRoutableLaunchPath(path)) {
        return path;
      }
    }
    return '/';
  }

  static bool isRoutableLaunchPath(String path) =>
      isDeepLinkPath(path) || _isSecondaryPath(path);

  static bool isDeepLinkPath(String path) =>
      path.startsWith('/shop/') ||
      path.startsWith('/product/') ||
      path.startsWith('/ya-cope/');

  static bool _isSecondaryPath(String path) =>
      path == '/search' ||
      path == '/cart' ||
      path == '/orders' ||
      path == '/deliveries' ||
      path == '/messages' ||
      path == '/b2b' ||
      path == '/admin' ||
      path == '/discover' ||
      path == '/shops' ||
      path == '/profile';

  /// Re-applies the browser URL after async bootstrap (web splash delay).
  static void ensureWebLocation(GoRouter router) {
    if (!kIsWeb) {
      ensureLaunchLocation(router);
      return;
    }
    final path = Uri.base.path;
    if (!isRoutableLaunchPath(path)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (router.state.uri.path != path) {
        router.go(path);
      }
    });
  }

  /// Mobile backup if the router was created before the launch path was applied.
  static void ensureLaunchLocation(GoRouter router) {
    final path = DeepLinkService.launchPath;
    if (path == null || !isDeepLinkPath(path)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (router.state.uri.path != path) {
        router.go(path);
      }
      DeepLinkService.launchPath = null;
    });
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
                  path: '/ya-cope',
                  builder: (_, __) => const YaCopeFeedScreen(),
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
          ],
        ),
        GoRoute(
          path: '/profile',
          parentNavigatorKey: rootKey,
          builder: (context, __) => DesktopRouteWrapper(
            child: const ProfileScreen(showAppBar: true),
          ),
        ),
        GoRoute(
          path: '/search',
          parentNavigatorKey: rootKey,
          builder: (context, __) => DesktopRouteWrapper(
            appBar: _secondaryAppBar(context, tr(context, 'search_page_title')),
            child: const SearchScreen(showBottomNav: false),
          ),
        ),
        GoRoute(
          path: '/cart',
          parentNavigatorKey: rootKey,
          builder: (context, __) => DesktopRouteWrapper(
            appBar: _secondaryAppBar(context, tr(context, 'cart')),
            child: const CartScreen(showAppBar: false),
          ),
        ),
        GoRoute(
          path: '/orders',
          parentNavigatorKey: rootKey,
          builder: (context, __) => DesktopRouteWrapper(
            appBar: _secondaryAppBar(context, tr(context, 'my_orders')),
            child: const OrdersScreen(),
          ),
        ),
        GoRoute(
          path: '/deliveries',
          parentNavigatorKey: rootKey,
          builder: (context, __) => DesktopRouteWrapper(
            appBar: _secondaryAppBar(context, tr(context, 'my_deliveries')),
            child: const MyDeliveriesScreen(),
          ),
        ),
        GoRoute(
          path: '/messages',
          parentNavigatorKey: rootKey,
          builder: (context, __) => DesktopRouteWrapper(
            appBar: _secondaryAppBar(context, tr(context, 'messages')),
            child: const MessagesScreen(),
          ),
        ),
        GoRoute(
          path: '/b2b',
          parentNavigatorKey: rootKey,
          builder: (context, __) => DesktopRouteWrapper(
            appBar: _secondaryAppBar(context, tr(context, 'b2b_hub_title')),
            child: const B2BHubScreen(),
          ),
        ),
        GoRoute(
          path: '/admin',
          parentNavigatorKey: rootKey,
          builder: (context, __) => const AdminScreen(),
        ),
        GoRoute(
          path: '/shop/:id',
          parentNavigatorKey: rootKey,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return DesktopRouteWrapper(
                child: Scaffold(
                  body: Center(child: Text(tr(context, 'shop_not_found'))),
                ),
              );
            }
            return DesktopRouteWrapper(
              child: FutureRouteContent<Shop>(
                load: () => context.read<ShopRepository>().resolveShopById(id),
                isNotFound: (shop) => shop == null,
                notFound: Scaffold(
                  body: Center(child: Text(tr(context, 'shop_not_found'))),
                ),
                builder: (shop) => ShopProfileScreen(shop: shop),
              ),
            );
          },
        ),
        GoRoute(
          path: '/ya-cope/:id',
          parentNavigatorKey: rootKey,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return DesktopRouteWrapper(
                child: Scaffold(
                  body: Center(child: Text(tr(context, 'load_error'))),
                ),
              );
            }
            return DesktopRouteWrapper(
              child: FutureRouteContent<YaCopeListing>(
                load: () => context.read<YaCopeRepository>().fetchById(id),
                isNotFound: (listing) => listing == null,
                notFound: Scaffold(
                  body: Center(child: Text(tr(context, 'product_not_found'))),
                ),
                builder: (listing) => YaCopeDetailScreen(listing: listing),
              ),
            );
          },
        ),
        GoRoute(
          path: '/product/:id',
          parentNavigatorKey: rootKey,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return DesktopRouteWrapper(
                child: Scaffold(
                  body: Center(child: Text(tr(context, 'product_not_found'))),
                ),
              );
            }
            return DesktopRouteWrapper(
              child: FutureRouteContent<Product>(
                load: () =>
                    context.read<ProductRepository>().resolveProductById(id),
                isNotFound: (product) => product == null,
                notFound: Scaffold(
                  body: Center(
                    child: Text(tr(context, 'product_not_found')),
                  ),
                ),
                builder: (product) => ProductDetailScreen(product: product),
              ),
            );
          },
        ),
      ],
      errorBuilder: (context, state) => DesktopRouteWrapper(
        child: Scaffold(
          body: Center(
            child: Text(
              isDeepLinkPath(state.uri.path)
                  ? tr(context, 'load_error')
                  : 'Page introuvable',
            ),
          ),
        ),
      ),
    );
  }

  static PreferredSizeWidget _secondaryAppBar(
    BuildContext context,
    String title,
  ) {
    return UzaAppBar(
      showLogo: false,
      showBack: true,
      title: title,
      actions: HomeAppActions.build(context),
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
