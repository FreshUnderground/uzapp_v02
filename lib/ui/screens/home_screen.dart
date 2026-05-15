import 'dart:ui';
import 'package:flutter/material.dart';
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
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
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
import '../utils/page_transitions.dart';
import '../../core/l10n/tr.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

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
    // Clamp to valid range for 4-tab layout
    _selectedIndex = widget.initialIndex.clamp(0, 3);

    // Ensure categories are synced from server on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final syncService = context.read<SyncService>();
        syncService.ensureCategoriesSynced();
        debugPrint('HomeScreen: triggered ensureCategoriesSynced');
      } catch (e) {
        debugPrint('HomeScreen: failed to trigger ensureCategoriesSynced: $e');
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
    setState(() {
      _selectedIndex = index;
    });
  }

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
    // 4-tab layout: Accueil, Explorer, Boutiques, Profil
    final List<Widget> pages = [
      _HomeContent(onOpenStory: _openOverlayStory),
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
            Consumer<SyncService>(
              builder: (context, syncService, child) {
                if (syncService.syncStatus == SyncStatus.error ||
                    syncService.syncStatus == SyncStatus.offline) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.orange.withValues(alpha: 0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 14, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          tr(context, 'offline'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox(height: 0);
              },
            ),
            Expanded(child: _buildBody(pages)),
          ],
        ),
        bottomNavigationBar: AnimatedBottomNav(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              selectedIndex: _selectedIndex,
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
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
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
                    Consumer<SyncService>(
                      builder: (context, syncService, child) {
                        if (syncService.syncStatus == SyncStatus.error ||
                            syncService.syncStatus == SyncStatus.offline) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.orange.withValues(alpha: 0.1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  tr(context, 'offline'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox(height: 0);
                      },
                    ),
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
        IndexedStack(index: _selectedIndex, children: pages),
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
    if (_selectedIndex != 0) return null;

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
        if (_selectedIndex == 0) {
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
  const _HomeContent({required this.onOpenStory});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  Future<void> _handleRefresh() async {
    try {
      final syncService = context.read<SyncService>();
      // First ensure categories are synced
      await syncService.ensureCategoriesSynced();
      // Then do a full sync
      await syncService.syncNow();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Sync completed - Categories updated'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
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
    late final ProductRepository productRepo;
    late final StoryRepository storyRepo;
    late final SyncService syncService;

    try {
      productRepo = context.watch<ProductRepository>();
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
    final responsiveStoryHeight = storyHeight.clamp(110.0, 140.0);
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
              slivers: [
                // 1. Unified Search Bar (Glassmorphic) - Floating
                SliverAppBar(
                  floating: true,
                  pinned: false,
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

                // 2. Category Shortcuts
                SliverToBoxAdapter(child: _buildCategoryShortcuts()),

                // 3. Stories
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    tr(context, 'my_stories'),
                    topPadding: 12,
                  ),
                ),
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

                // 4. Nouveaux Arrivages
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    tr(context, 'new_arrivals_header'),
                    onAction: () => Navigator.push(
                      context,
                      SlideUpRoute(page: const ArrivagesScreen()),
                    ),
                  ),
                ),
                // Arrivage stories sub-section
                SliverToBoxAdapter(
                  child: StreamBuilder<Map<int, List<Story>>>(
                    stream: storyRepo.watchArrivagesGroupedByShop(),
                    builder: (context, snapshot) {
                      final grouped = snapshot.data ?? {};
                      debugPrint(
                        'Arrivages grouped: ${grouped.length} shops, connectionState=${snapshot.connectionState}',
                      );
                      if (grouped.isEmpty) {
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
                      final shopIds = grouped.keys.toList();
                      return SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          itemCount: shopIds.length,
                          itemBuilder: (context, index) {
                            final shopId = shopIds[index];
                            final stories = grouped[shopId]!;
                            final firstStory = stories.first;
                            return GestureDetector(
                              onTap: () {
                                final sRepo = context.read<StoryRepository>();
                                sRepo.logStoryView(stories.first.id);
                                widget.onOpenStory(stories, 0);
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
                                      ImageUtils.buildCachedImage(
                                        firstStory.mediaUrl.isNotEmpty
                                            ? CryptoUtils.decrypt(
                                                firstStory.mediaUrl,
                                              )
                                            : '',
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
                                                    .getShopById(shopId),
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
                                            if (stories.length > 1)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: UzaColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${stories.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
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
                StreamBuilder<List<Product>>(
                  stream: productRepo.watchTrendingProducts(limit: 10),
                  builder: (context, snapshot) {
                    final products = snapshot.data ?? [];
                    if (snapshot.connectionState == ConnectionState.waiting) {
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

  Widget _buildCategoryShortcuts() {
    final hPad = MediaQuery.of(context).size.width < 360 ? 12.0 : 16.0;

    late final StreamBuilder<List<Category>> categoryStream;
    try {
      final productRepo = context.watch<ProductRepository>();
      categoryStream = StreamBuilder<List<Category>>(
        stream: productRepo.watchRootCategories(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          debugPrint(
            'Root categories: ${categories.length}, connectionState=${snapshot.connectionState}',
          );
          // Debug: print category details
          if (categories.isNotEmpty) {
            for (var i = 0; i < categories.length && i < 3; i++) {
              debugPrint(
                '  Category[$i]: id=${categories[i].id}, name=${categories[i].name}, level=${categories[i].level}',
              );
            }
          }
          // Show up to 6 root categories to include all categories
          final displayCategories = categories.take(6).toList();

          if (displayCategories.isEmpty) {
            // Check if still loading or truly empty
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show skeleton placeholders while loading
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (_) {
                    return Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 40,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            } else {
              // Categories are empty - show sync button
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                child: Column(
                  children: [
                    Text(
                      'No categories loaded',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final syncService = context.read<SyncService>();
                          await syncService.ensureCategoriesSynced();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Categories synced successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to sync: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.sync, size: 16),
                      label: Text('Sync Categories'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: displayCategories.map((category) {
                final icon = _getCategoryIcon(category.name);
                return Expanded(
                  child: TapAnimator(
                    onTap: () {
                      Navigator.push(
                        context,
                        FadeThroughRoute(
                          page: SearchScreen(
                            showAppBar: true,
                            initialCategoryId: category.id,
                            initialCategoryName: category.name,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: UzaColors.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: UzaColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error building category shortcuts: $e');
      // Fallback: show empty space
      return const SizedBox.shrink();
    }

    return categoryStream;
  }

  /// Map category names to appropriate icons, matching the logic
  /// used in SearchScreen._getCategoryIcon for consistency.
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('téléphone') || name.contains('phone')) {
      return Icons.phone_android;
    }
    if (name.contains('ordinateur') ||
        name.contains('pc') ||
        name.contains('laptop') ||
        name.contains('ordi')) {
      return Icons.laptop;
    }
    if (name.contains('accessoire')) {
      return Icons.headphones;
    }
    if (name.contains('gadget') || name.contains('électronique')) {
      return Icons.devices_other;
    }
    if (name.contains('vêtement') ||
        name.contains('fashion') ||
        name.contains('habit')) {
      return Icons.checkroom;
    }
    if (name.contains('sac') || name.contains('bijou')) {
      return Icons.shopping_bag;
    }
    if (name.contains('maison') ||
        name.contains('home') ||
        name.contains('déco')) {
      return Icons.home;
    }
    if (name.contains('aliment') ||
        name.contains('food') ||
        name.contains('resto') ||
        name.contains('restau')) {
      return Icons.fastfood;
    }
    if (name.contains('beauté') || name.contains('cosmétique')) {
      return Icons.face;
    }
    if (name.contains('sport')) {
      return Icons.sports_soccer;
    }
    if (name.contains('tv') || name.contains('télé')) {
      return Icons.tv;
    }
    if (name.contains('auto') || name.contains('vehicul')) {
      return Icons.directions_car;
    }
    return Icons.category;
  }

  Widget _buildSectionHeader(
    String title, {
    double topPadding = 20,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width < 360 ? 12.0 : 16.0,
        topPadding,
        MediaQuery.of(context).size.width < 360 ? 12.0 : 16.0,
        8,
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
