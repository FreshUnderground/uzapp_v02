import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../components/product_card.dart';
import '../screens/product_detail_screen.dart';
import '../screens/story_view_screen.dart';
import 'shops_directory_screen.dart';
import 'ya_cope_feed_screen.dart';
import 'add_ya_cope_screen.dart';
import 'story_feed_screen.dart';
import 'discover_feed_screen.dart';
import 'arrivages_screen.dart';
import '../../core/services/auth_service.dart';
import '../components/arrivage_thumbnail.dart';
import 'seller_onboarding_screen.dart';
import 'create_shop_screen.dart';
import '../components/responsive_layout.dart';
import 'create_story_screen.dart';
import 'edit_product_screen.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../components/animated_bottom_nav.dart';
import '../../data/services/sync_service.dart';
import '../components/skeletons.dart';
import '../components/custom_refresh_indicator.dart';
import '../utils/page_transitions.dart';
import '../utils/seller_gate.dart';
import '../../core/l10n/tr.dart';
import '../components/desktop_shell.dart';
import '../components/uza_search_bar.dart';
import '../components/home_app_actions.dart';
import '../components/product_updates_feed.dart';
import '../../core/res/uza_colors.dart';

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
  final _yaCopeFeedKey = GlobalKey<YaCopeFeedScreenState>();
  var _openingYaCopeAdd = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.navigationShell?.currentIndex ??
        widget.initialIndex.clamp(0, 3);

    if (kIsWeb) {
      final shortcut = Uri.base.queryParameters['shortcut'];
      if (shortcut == 'shops') {
        _selectedIndex = 3;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onItemTapped(3);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (kIsWeb && Uri.base.queryParameters['shortcut'] == 'search') {
        context.go('/search');
      }
      try {
        final sync = context.read<SyncService>();
        sync.requestBootstrapSync();
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
    final safeIndex = index.clamp(0, 3);
    if (_selectedIndex != safeIndex) {
      setState(() => _selectedIndex = safeIndex);
    }
    final shell = widget.navigationShell;
    if (shell != null) {
      shell.goBranch(
        safeIndex,
        initialLocation: safeIndex == shell.currentIndex,
      );
    }
  }

  int get _activeIndex => _selectedIndex;

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isDesktop,
    bool showCreateInToolbar = false,
  }) {
    final authService = context.watch<AuthService>();
    final shopRepo = context.read<ShopRepository>();
    final userId = authService.user?.uid;

    // Boutique tab has its own shop search — avoid duplicate search bars.
    final showGlobalSearch = _activeIndex != 3;

    Widget? searchField;
    if (isDesktop && showGlobalSearch) {
      searchField = SizedBox(
        width: 420,
        child: UzaSearchBar(
          variant: UzaSearchBarVariant.inline,
          onTap: () => context.go('/search'),
        ),
      );
    }

    List<Widget> actions;
    if (showCreateInToolbar && userId != null) {
      actions = [
        StreamBuilder<Shop?>(
          stream: shopRepo.watchUserShop(userId),
          builder: (context, snapshot) {
            final hasShop = snapshot.hasData && snapshot.data != null;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: HomeAppActions.build(
                context,
                includeCreate: _activeIndex == 0,
                hasShop: hasShop,
                onCreateShop: () => Navigator.push(
                  context,
                  SlideUpRoute(page: const CreateShopScreen()),
                ),
                onCreateProduct: () async {
                  final shop = snapshot.data;
                  if (shop != null) {
                    _openCreateProduct(context, shop);
                  } else {
                    final resolved = await resolveSellerShop(context);
                    if (resolved != null && context.mounted) {
                      _openCreateProduct(context, resolved);
                    }
                  }
                },
              ),
            );
          },
        ),
      ];
    } else {
      actions = HomeAppActions.build(context);
    }

    return UzaAppBar(
      showLogo: !isDesktop,
      title: isDesktop ? HomeAppActions.tabTitle(context, _activeIndex) : null,
      titleWidget: isDesktop ? searchField : null,
      actions: actions,
      bottom: !isDesktop && showGlobalSearch
          ? UzaSearchBar(
              onTap: () => context.go('/search'),
              variant: UzaSearchBarVariant.compact,
            )
          : null,
      height: kToolbarHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _HomeContent(
        onOpenStory: _openOverlayStory,
        isTabActive: _activeIndex == 0,
      ),
      const DiscoverFeedScreen(),
      YaCopeFeedScreen(key: _yaCopeFeedKey),
      const ShopsDirectoryScreen(),
    ];

    return ResponsiveLayout(
      mobile: Scaffold(
        extendBody: true,
        appBar: _buildAppBar(context, isDesktop: false),
        floatingActionButton: _buildDynamicFAB(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: _buildBody(pages),
        bottomNavigationBar: AnimatedBottomNav(
          currentIndex: _activeIndex,
          onTap: _onItemTapped,
        ),
      ),
      desktop: DesktopShell(
        selectedIndex: _activeIndex,
        onDestinationSelected: _onItemTapped,
        appBar: _buildAppBar(
          context,
          isDesktop: true,
          showCreateInToolbar: true,
        ),
        floatingActionButton: _buildDynamicFAB(context, includeDesktop: true),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        child: _buildBody(pages),
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

  void _openAddYaCope() {
    if (_openingYaCopeAdd) return;
    _openingYaCopeAdd = true;
    Navigator.push(
      context,
      SlideUpRoute(page: const AddYaCopeScreen()),
    ).then((created) {
      if (created == true) {
        _yaCopeFeedKey.currentState?.refreshListings();
      }
    }).whenComplete(() {
      _openingYaCopeAdd = false;
    });
  }

  Widget? _buildDynamicFAB(BuildContext context, {bool includeDesktop = false}) {
    if (!includeDesktop && ResponsiveLayout.isDesktop(context)) return null;
    // Hide FAB when story overlay is active
    if (_overlayStories != null) return null;

    if (_activeIndex == 2) {
      return FloatingActionButton.extended(
        onPressed: _openAddYaCope,
        backgroundColor: const Color(0xFF019C94),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(tr(context, 'ya_cope_add')),
      );
    }

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
              onPressed: () async {
                if (userId == null) {
                  await SellerOnboardingScreen.open(context);
                } else {
                  Navigator.push(
                    context,
                    SlideUpRoute(page: const CreateShopScreen()),
                  );
                }
              },
              backgroundColor: UzaColors.secondary,
              child: const Icon(Icons.storefront),
            );
          }
          return FloatingActionButton(
            onPressed: () => _openCreateProduct(context, snapshot.data!),
            backgroundColor: UzaColors.primary,
            child: const Icon(Icons.add),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _openCreateProduct(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      SlideUpRoute(page: EditProductScreen(shopId: shop.id)),
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

  int _gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (ResponsiveLayout.isDesktop(context)) {
      return width >= 1400 ? 5 : 4;
    }
    return 2;
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

    final productRepo = context.read<ProductRepository>();
    all = productRepo.deduplicateForDisplay(all);

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
        _displayedProducts = productRepo.deduplicateForDisplay([
          ...newProducts,
          ...merged,
        ]);
        _hasReachedEnd = _displayedProducts.length >= _allProducts.length;
      } else {
        _displayedProducts = productRepo.deduplicateForDisplay(merged);
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

  Future<void> _openCreateStory({bool isArrivage = false}) async {
    final shop = await resolveSellerShop(context);
    if (!mounted || shop == null) return;
    Navigator.push(
      context,
      SlideUpRoute(
        page: CreateStoryScreen(shopId: shop.id, isArrivage: isArrivage),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    try {
      final syncService = context.read<SyncService>();
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
                Expanded(
                  child: Text(trf(context, 'sync_failed', {'error': '$e'})),
                ),
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
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final gridColumns = _gridCrossAxisCount(context);
    final aspectRatio = screenWidth < 360 ? 0.74 : (isDesktop ? 0.72 : 0.76);
    final storyHeight = MediaQuery.of(context).size.height * 0.12;
    final responsiveStoryHeight = storyHeight.clamp(95.0, 115.0);
    final hPad = screenWidth < 360 ? 12.0 : 16.0;
    final hPadWide = screenWidth < 360 ? 12.0 : 20.0;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
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
                // 1. Stories
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsiveStoryHeight,
                    child: StoryFeedScreen(
                      onOpenStory: widget.onOpenStory,
                      isCompact: true,
                      showAddButton: true,
                      onCreateStory: () => _openCreateStory(isArrivage: false),
                    ),
                  ),
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
                        if (syncService.isSyncing &&
                            syncService.isFirstSync &&
                            !syncService.hasLocalCatalog) {
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
                      }

                      final itemCount = stories.length + 1;

                      return SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _AddArrivageCard(
                                onTap: () => _openCreateStory(isArrivage: true),
                              );
                            }

                            final story = stories[index - 1];
                                return GestureDetector(
                                  key: ValueKey('home_arrivage_${story.id}'),
                                  onTap: () {
                                    final sRepo = context.read<StoryRepository>();
                                    sRepo.logStoryView(story.id);
                                    final index = stories.indexWhere(
                                      (s) => s.id == story.id,
                                    );
                                    widget.onOpenStory(
                                      stories,
                                      index >= 0 ? index : 0,
                                    );
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

                // 4b. Mises à jour produits récentes
                const SliverToBoxAdapter(
                  child: ProductUpdatesFeed(),
                ),

                // 5. Populaires (Grid)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(tr(context, 'popular')),
                ),
                Builder(
                  builder: (context) {
                    final products = _displayedProducts;
                    final isLoading = !_trendingInitialized &&
                        _allProducts.isEmpty &&
                        syncService.isFirstSync &&
                        syncService.isSyncing;

                    if (isLoading) {
                      return SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: hPadWide),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridColumns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: aspectRatio,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Skeletons.productCard(context),
                            childCount: 4,
                          ),
                        ),
                      );
                    }
                    if (products.isEmpty) {
                      if (syncService.isFirstSync &&
                          syncService.syncStatus == SyncStatus.offline) {
                        return SliverToBoxAdapter(
                          child: SizedBox(
                            height: 220,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wifi_off,
                                      size: 48,
                                      color: UzaColors.onSurfaceSecondary(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      tr(context, 'first_launch_offline'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: UzaColors.onSurfaceSecondary(
                                          context,
                                        ),
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
                          ),
                        );
                      }
                      if (syncService.isSyncing && syncService.isFirstSync) {
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
                                    syncService.syncStatus ==
                                            SyncStatus.offline
                                        ? tr(context, 'first_launch_offline')
                                        : tr(context, 'first_launch_loading'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: UzaColors.onSurfaceSecondary(
                                        context,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (syncService.syncStatus !=
                                      SyncStatus.offline) ...[
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        tr(context, 'first_launch_slow_hint'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: UzaColors.onSurfaceSecondary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                                    color: UzaColors.onSurfaceSecondary(
                                      context,
                                    ),
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
                          crossAxisCount: gridColumns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: aspectRatio,
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

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: UzaColors.onSurface(context),
            ),
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

/// Quick-add arrivage card shown first in the horizontal arrivages row.
class _AddArrivageCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddArrivageCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.35),
            width: 1.5,
          ),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF6C63FF),
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mon arrivage',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
