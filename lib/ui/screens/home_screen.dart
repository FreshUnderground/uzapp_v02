import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/local/uza_database.dart';
import '../components/product_card.dart';
import '../../core/res/uza_colors.dart';
import '../screens/product_detail_screen.dart';
import '../screens/story_view_screen.dart';
import '../screens/notification_screen.dart';
import '../../core/services/notification_service.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'shops_directory_screen.dart';
import 'profile_screen.dart';
import 'story_feed_screen.dart';
import 'discover_feed_screen.dart';
import 'arrivages_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/image_utils.dart';
import '../components/arrivage_thumbnail.dart';
import 'create_shop_screen.dart';
import '../components/responsive_layout.dart';
import 'create_story_screen.dart';
import 'edit_product_screen.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../components/animated_bottom_nav.dart';
import '../../data/services/sync_service.dart';
import '../components/skeletons.dart';
import '../components/tap_animator.dart';
import '../components/custom_refresh_indicator.dart';
import '../components/sync_status_banner.dart';
import '../components/home_discovery_sections.dart';
import '../components/boost_banner_carousel.dart';
import '../utils/page_transitions.dart';
import '../../core/l10n/tr.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/services/settings_service.dart';
import '../components/pwa_install_banner.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  final StatefulNavigationShell? navigationShell;
  const HomeScreen({
    super.key,
    this.initialIndex = 0,
    this.navigationShell,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  List<Story>? _overlayStories;
  int _overlayStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3);

    if (kIsWeb) {
      final shortcut = Uri.base.queryParameters['shortcut'];
      if (shortcut == 'shops') {
        _selectedIndex = 2;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.navigationShell?.goBranch(2);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (kIsWeb && Uri.base.queryParameters['shortcut'] == 'search') {
        Navigator.push(
          context,
          SlideUpRoute(page: const SearchScreen()),
        );
      }
      try {
        final sync = context.read<SyncService>();
        sync.ensureShopsSynced();
        sync.ensureCategoriesSynced();
        sync.syncNow();
      } catch (e) {
        debugPrint('HomeScreen: sync bootstrap failed: $e');
      }
    });
  }

  void _openOverlayStory(List<Story> stories, int index) {
    setState(() {
      _overlayStories = stories;
      _overlayStoryIndex = index;
    });
  }

  void _closeOverlayStory() {
    setState(() {
      _overlayStories = null;
    });
  }

  void _onItemTapped(int index) {
    final shell = widget.navigationShell;
    if (shell != null) {
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  int get _activeIndex =>
      widget.navigationShell?.currentIndex ?? _selectedIndex;

  List<Widget> _getActions() {
    List<Widget> actions = [];

    // Cart icon with Badge
    try {
      actions.add(
        StreamBuilder<int>(
          stream: context.watch<CartRepository>().watchCartCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Badge(
              label: Text('$count'),
              isLabelVisible: count > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  SlideUpRoute(page: const CartScreen()),
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error building cart badge: $e');
      // Fallback: show cart without badge
      actions.add(
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () =>
              Navigator.push(context, SlideUpRoute(page: const CartScreen())),
        ),
      );
    }

    // Notification badge
    actions.add(
      Consumer<NotificationService>(
        builder: (context, notificationService, _) {
          return Badge(
            label: Text('${notificationService.unreadCount}'),
            isLabelVisible: notificationService.unreadCount > 0,
            child: IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => Navigator.push(
                context,
                SlideUpRoute(page: const NotificationScreen()),
              ),
            ),
          );
        },
      ),
    );

    // Language selector dropdown
    actions.add(_buildLanguageSelector());

    actions.add(const SizedBox(width: 8));
    return actions;
  }

  Widget _buildLanguageSelector() {
    final settings = context.watch<SettingsService>();
    final currentFlag = _getLanguageFlag(settings.currentLanguage);

    return PopupMenuButton<String>(
      icon: Text(currentFlag, style: const TextStyle(fontSize: 22)),
      tooltip: 'Change language',
      itemBuilder: (context) {
        return AppTranslations.supportedLocales.map((String code) {
          final languageName = AppTranslations.languageNames[code] ?? code;
          final flag = _getLanguageFlag(code);
          final isSelected =
              context.read<SettingsService>().currentLanguage == code;
          return PopupMenuItem<String>(
            value: code,
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(languageName),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.green, size: 20),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (String languageCode) {
        context.read<SettingsService>().setLanguage(languageCode);
      },
    );
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇬🇧';
      case 'ln':
        return '🇨🇩';
      case 'sw':
        return '🇰🇪';
      default:
        return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _HomeContent(
        onOpenStory: _openOverlayStory,
        isTabActive: _activeIndex == 0,
      ),
      const DiscoverFeedScreen(),
      const ShopsDirectoryScreen(),
      const ProfileScreen(showAppBar: false),
    ];

    return ResponsiveLayout(
      mobile: Scaffold(
        extendBody: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
                title: null,
                actions: _getActions(),
                centerTitle: false,
              ),
            ),
          ),
        ),
        floatingActionButton: _buildDynamicFAB(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(child: _buildBody(pages)),
          ],
        ),
        bottomNavigationBar: AnimatedBottomNav(
          currentIndex: _activeIndex,
          onTap: _onItemTapped,
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              selectedIndex: _activeIndex,
              onDestinationSelected: _onItemTapped,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Image.asset('assets/logo.png', height: 60),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text(tr(context, 'home')),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: Text(tr(context, 'discover')),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: Text(tr(context, 'boutiques')),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text(tr(context, 'profile')),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AppBar(
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
                        leading: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        actions: _getActions(),
                      ),
                    ),
                  ),
                ),
                floatingActionButton: _buildDynamicFAB(context),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
                body: Column(
                  children: [
                    const SyncStatusBanner(),
                    Expanded(child: _buildBody(pages)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Widget> pages) {
    return Stack(
      children: [
        IndexedStack(index: _activeIndex, children: pages),
        if (_overlayStories != null)
          Positioned.fill(
            bottom: 0,
            child: StoryViewScreen(
              stories: _overlayStories!,
              initialIndex: _overlayStoryIndex,
              onClose: _closeOverlayStory,
            ),
          ),
      ],
    );
  }

  Widget? _buildDynamicFAB(BuildContext context) {
    // Hide FAB when story overlay is active
    if (_overlayStories != null) return null;

    // Show FAB only on Accueil (0) tab
    if (_activeIndex != 0) return null;

    final authService = context.watch<AuthService>();
    final shopRepo = context.read<ShopRepository>();
    final user = authService.user;
    final userId = user?.uid;

    return StreamBuilder<Shop?>(
      stream: userId != null
          ? shopRepo.watchUserShop(userId)
          : Stream.value(null),
      builder: (context, snapshot) {
        final hasShop = snapshot.hasData && snapshot.data != null;

        // Home Tab (0)
        if (_activeIndex == 0) {
          if (!hasShop) {
            return FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                SlideUpRoute(page: const CreateShopScreen()),
              ),
              backgroundColor: UzaColors.secondary,
              child: const Icon(Icons.storefront),
            );
          }
          return FloatingActionButton(
            onPressed: () => _showCreateBottomSheet(context, snapshot.data!),
            backgroundColor: UzaColors.primary,
            child: const Icon(Icons.add),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showCreateBottomSheet(BuildContext context, Shop shop) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'Créer',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: UzaColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Que souhaitez-vous publier ?',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Options
                _CreateOptionTile(
                  icon: Icons.shopping_bag_outlined,
                  iconColor: UzaColors.primary,
                  iconBgColor: UzaColors.primary.withValues(alpha: 0.1),
                  title: 'Créer un produit',
                  subtitle: 'Ajoutez un nouveau produit à votre boutique',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      SlideUpRoute(page: EditProductScreen(shopId: shop.id)),
                    );
                  },
                ),
                _CreateOptionTile(
                  icon: Icons.camera_alt_outlined,
                  iconColor: UzaColors.secondary,
                  iconBgColor: UzaColors.secondary.withValues(alpha: 0.1),
                  title: 'Créer une story',
                  subtitle: 'Partagez un moment avec votre communauté',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      SlideUpRoute(page: CreateStoryScreen(shopId: shop.id)),
                    );
                  },
                ),
                _CreateOptionTile(
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFF6C63FF),
                  iconBgColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  title: 'Créer un arrivage',
                  subtitle:
                      'Annoncez les nouvelles arrivées dans votre boutique',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      SlideUpRoute(
                        page: CreateStoryScreen(
                          shopId: shop.id,
                          isArrivage: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: UzaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final Function(List<Story>, int) onOpenStory;
  final bool isTabActive;

  const _HomeContent({
    required this.onOpenStory,
    required this.isTabActive,
  });

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static const _trendingLimit = 10;
  static const _loadMoreBatch = 10;
  static const _poolSize = 40;

  List<Product> _displayedProducts = [];
  List<Product> _allProducts = [];
  List<Product> _productPool = [];
  bool _trendingInitialized = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  StreamSubscription<List<Product>>? _allProductsSub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeProducts());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _allProductsSub?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _hasReachedEnd) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 320) return;
    _loadMoreProducts();
  }

  bool get _canLoadMore =>
      _allProducts.isNotEmpty && !_isLoadingMore && !_hasReachedEnd;

  void _loadMoreProducts() {
    if (!_canLoadMore || !mounted) return;

    _isLoadingMore = true;

    final shownIds = _displayedProducts.map((p) => p.id).toSet();
    final next = _allProducts
        .where((p) => !shownIds.contains(p.id))
        .take(_loadMoreBatch)
        .toList();

    if (next.isEmpty) {
      setState(() => _hasReachedEnd = true);
    } else if (next.isNotEmpty) {
      setState(() => _displayedProducts = [..._displayedProducts, ...next]);
      if (_displayedProducts.length >= _allProducts.length) {
        _hasReachedEnd = true;
      }
    }

    _isLoadingMore = false;
  }

  @override
  void didUpdateWidget(_HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTabActive && widget.isTabActive) {
      _reshuffleTrending();
    }
  }

  void _subscribeProducts() {
    if (!mounted) return;
    _allProductsSub?.cancel();
    _allProductsSub = context
        .read<ProductRepository>()
        .watchAllProducts()
        .listen(_onAllProductsUpdated);
  }

  void _onAllProductsUpdated(List<Product> all) {
    if (!mounted) return;

    _allProducts = all;
    _productPool = all.take(_poolSize).toList();

    if (!_trendingInitialized) {
      if (all.isEmpty) {
        setState(() => _displayedProducts = []);
        return;
      }
      _trendingInitialized = true;
      setState(() {
        _displayedProducts = context
            .read<ProductRepository>()
            .pickTrendingProducts(_productPool, limit: _trendingLimit);
      });
      return;
    }

    final shownIds = _displayedProducts.map((p) => p.id).toSet();
    final newProducts = all.where((p) => !shownIds.contains(p.id)).toList();

    final byId = {for (final p in all) p.id: p};
    final merged = <Product>[];
    for (final product in _displayedProducts) {
      final updated = byId[product.id];
      if (updated != null) merged.add(updated);
    }

    if (newProducts.isEmpty && _sameProductSnapshot(_displayedProducts, merged)) {
      return;
    }

    setState(() {
      if (newProducts.isNotEmpty) {
        _displayedProducts = [...newProducts, ...merged];
        _hasReachedEnd = _displayedProducts.length >= _allProducts.length;
      } else {
        _displayedProducts = merged;
      }
    });
  }

  void _reshuffleTrending() {
    if (!mounted || _productPool.isEmpty) return;
    final next = context
        .read<ProductRepository>()
        .pickTrendingProducts(_productPool, limit: _trendingLimit);
    if (_sameProductSnapshot(_displayedProducts, next)) return;
    setState(() {
      _displayedProducts = next;
      _isLoadingMore = false;
      _hasReachedEnd = false;
    });
  }

  bool _sameProductSnapshot(List<Product> a, List<Product> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].updatedAt != b[i].updatedAt) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleRefresh() async {
    try {
      final syncService = context.read<SyncService>();
      await syncService.ensureShopsSynced();
      await syncService.ensureCategoriesSynced();
      await syncService.syncNow();
      setState(() => _hasReachedEnd = false);
      _reshuffleTrending();
    } catch (e) {
      debugPrint('Error during refresh sync: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Sync failed: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    late final StoryRepository storyRepo;
    late final SyncService syncService;

    try {
      storyRepo = context.watch<StoryRepository>();
      syncService = context.watch<SyncService>();
    } catch (e) {
      debugPrint('Error accessing repositories: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(tr(context, 'loading_error')),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: Text(tr(context, 'retry')),
              ),
            ],
          ),
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final cardWidth = screenWidth * 0.65;
    final responsiveCardWidth = cardWidth.clamp(180.0, 250.0);
    final storyHeight = MediaQuery.of(context).size.height * 0.12;
    final responsiveStoryHeight = storyHeight.clamp(95.0, 115.0);
    final hPad = screenWidth < 360 ? 12.0 : 16.0;
    final hPadWide = screenWidth < 360 ? 12.0 : 20.0;

    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1200 : double.infinity,
          ),
          child: UzaRefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 1. Unified Search Bar (Glassmorphic) - Floating
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 70,
                  flexibleSpace: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPad,
                          vertical: 12,
                        ),
                        child: TapAnimator(
                          onTap: () {
                            Navigator.push(
                              context,
                              FadeThroughRoute(
                                page: const SearchScreen(showAppBar: true),
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 16),
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  tr(context, 'search_hint'),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.tune_rounded,
                                  color: UzaColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Stories
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsiveStoryHeight,
                    child: StoryFeedScreen(
                      onOpenStory: widget.onOpenStory,
                      isCompact: true,
                      onCreateStory: () async {
                        final authService = context.read<AuthService>();
                        final shopRepo = context.read<ShopRepository>();
                        final user = authService.user;
                        final userId = user?.uid;
                        final shop = userId != null
                            ? await shopRepo.watchUserShop(userId).first
                            : null;
                        if (!context.mounted) return;
                        if (shop == null) {
                          Navigator.push(
                            context,
                            SlideUpRoute(page: const CreateShopScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            SlideUpRoute(
                              page: CreateStoryScreen(shopId: shop.id),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),

                // 3. Bannières boostées + découverte
                const SliverToBoxAdapter(
                  child: BoostBannerCarousel(),
                ),
                const SliverToBoxAdapter(
                  child: HomeDiscoverySections(),
                ),

                // 4. Nouveaux Arrivages
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    tr(context, 'new_arrivals_header'),
                    topPadding: 4,
                    bottomPadding: 4,
                    onAction: () => Navigator.push(
                      context,
                      SlideUpRoute(page: const ArrivagesScreen()),
                    ),
                  ),
                ),
                // Arrivage stories sub-section (one card per arrivage)
                SliverToBoxAdapter(
                  child: StreamBuilder<List<Story>>(
                    stream: storyRepo.watchActiveArrivages(),
                    builder: (context, snapshot) {
                      final stories = snapshot.data ?? [];
                      debugPrint(
                        'Arrivages: ${stories.length} cards, connectionState=${snapshot.connectionState}',
                      );
                      if (stories.isEmpty) {
                        // Show shimmer skeletons while first sync is loading
                        if (syncService.isSyncing || syncService.isFirstSync) {
                          return SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: hPad),
                              itemCount: 4,
                              itemBuilder: (_, __) =>
                                  Skeletons.arrivageCard(context),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      return SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return GestureDetector(
                              key: ValueKey('home_arrivage_${story.id}'),
                              onTap: () {
                                final sRepo = context.read<StoryRepository>();
                                sRepo.logStoryView(story.id);
                                widget.onOpenStory([story], 0);
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ArrivageThumbnail(
                                        story: story,
                                        fit: BoxFit.contain,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 6,
                                        right: 6,
                                        bottom: 6,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.store,
                                                size: 12,
                                                color: UzaColors.secondary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: FutureBuilder<Shop?>(
                                                future: context
                                                    .read<ShopRepository>()
                                                    .getShopById(story.shopId),
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.data?.name ??
                                                        '...',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                // 5. Populaires (Grid)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(tr(context, 'popular')),
                ),
                Builder(
                  builder: (context) {
                    final products = _displayedProducts;
                    final isLoading =
                        !_trendingInitialized && _allProducts.isEmpty;

                    if (isLoading) {
                      return SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: hPadWide),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 700
                                    ? 4
                                    : 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: screenWidth < 360
                                    ? 0.78
                                    : (screenWidth > 700 ? 0.75 : 0.86),
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Skeletons.productCard(context),
                            childCount: 4,
                          ),
                        ),
                      );
                    }
                    if (products.isEmpty) {
                      if (syncService.isSyncing) {
                        return SliverToBoxAdapter(
                          child: SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      UzaColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    tr(context, 'loading'),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tr(context, 'no_popular'),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => syncService.syncNow(),
                                  icon: const Icon(Icons.refresh),
                                  label: Text(tr(context, 'retry')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 700 ? 4 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: screenWidth < 360
                              ? 0.78
                              : (screenWidth > 700 ? 0.75 : 0.86),
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ProductCard(
                            product: products[index],
                            onTap: () => Navigator.push(
                              context,
                              SlideUpRoute(
                                page: ProductDetailScreen(
                                  product: products[index],
                                ),
                              ),
                            ),
                          ),
                          childCount: products.length,
                        ),
                      ),
                    );
                  },
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    double topPadding = 20,
    double bottomPadding = 8,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width < 360 ? 12.0 : 16.0,
        topPadding,
        MediaQuery.of(context).size.width < 360 ? 12.0 : 16.0,
        bottomPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                tr(context, 'see_all'),
                style: TextStyle(
                  color: UzaColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
