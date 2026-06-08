import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/res/uza_colors.dart';
import 'core/router/app_router.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/background_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/contact_service.dart';
import 'core/services/whatsapp_status_service.dart';
import 'core/services/whatsapp_status_scheduler.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/web_notification_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/uza_theme.dart';
import 'core/l10n/tr.dart';
import 'data/local/uza_database.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/message_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'data/repositories/story_repository.dart';
import 'data/repositories/cash_repository.dart';
import 'data/services/sync_service.dart';
import 'ui/components/error_boundary.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/product_detail_screen.dart';
import 'ui/screens/shop_profile_screen.dart';
import 'ui/screens/story_view_screen.dart';
import 'ui/screens/whatsapp_status_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Set up global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('GLOBAL ERROR: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Allow fetching fonts from the internet if AssetManifest.json is missing on web
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize background tasks (Workmanager) - non-blocking
  if (!kIsWeb) {
    try {
      // Don't await - let it initialize in background
      BackgroundService.initialize();
    } catch (e) {
      debugPrint('BackgroundService initialization error: $e');
    }
  }

  // Run app immediately with splash screen
  // Database and services will initialize asynchronously
  runApp(const UzaApp());
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class UzaApp extends StatefulWidget {
  const UzaApp({super.key});

  @override
  State<UzaApp> createState() => _UzaAppState();
}

class _UzaAppState extends State<UzaApp> with WidgetsBindingObserver {
  late Future<void> _initializationFuture;
  GoRouter? _router;
  DeepLinkService? _deepLinkService;
  Timer? _waStatusTimer;
  WhatsAppStatusScheduler? _waStatusScheduler;

  @override
  void dispose() {
    _waStatusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkService?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runWaStatusScheduler());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize services asynchronously without blocking UI
    _initializationFuture = _initializeServices();
  }

  Future<void> _runWaStatusScheduler() async {
    final scheduler = _waStatusScheduler;
    if (scheduler == null) return;
    try {
      await scheduler.prepareIfDue();
      await scheduler.syncWebReminder();
    } catch (e) {
      debugPrint('WaStatus scheduler tick error: $e');
    }
  }

  void _startWaStatusPeriodicCheck() {
    _waStatusTimer?.cancel();
    _waStatusTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => unawaited(_runWaStatusScheduler()),
    );
  }

  Future<void> _initializeServices() async {
    try {
      // Track last app open time - non-critical, can fail silently
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_app_open',
          DateTime.now().toIso8601String(),
        );
      } catch (e) {
        debugPrint('SharedPreferences error: $e');
      }

      // Initialize database
      final database = UzaDatabase();

      const String baseUrl = 'https://uzaapp.com/api';

      // Set up providers
      if (!mounted) return;

      final notificationService = NotificationService();
      final connectivityService = ConnectivityService();
      final apiService = ApiService(baseUrl: baseUrl);
      final syncService = SyncService(
        database,
        apiService,
        notificationService: notificationService,
      );
      final storyRepository = StoryRepository(
        database,
        syncService: syncService,
      );
      final authRepository = AuthRepository(database);
      final authService = AuthService(authRepository);
      final shopRepository = ShopRepository(database, syncService: syncService);
      final productRepository = ProductRepository(
        database,
        syncService: syncService,
      );
      final cartRepository = CartRepository(database);
      final orderRepository = OrderRepository(database);
      final messageRepository = MessageRepository(database);
      final contactService = ContactService(database);
      final whatsAppStatusService = WhatsAppStatusService(database);
      final waStatusScheduler = WhatsAppStatusScheduler(
        database,
        whatsAppStatusService,
      );
      _waStatusScheduler = waStatusScheduler;
      final settingsService = SettingsService(database);
      final cashRepository = CashRepository(apiService);
      final fcmService = FcmService(apiService);

      // Connect cross-references
      authService.syncService = syncService;
      authService.shopRepository = shopRepository;

      // Store in context for child widgets
      _services = _UzaServices(
        database: database,
        notificationService: notificationService,
        connectivityService: connectivityService,
        apiService: apiService,
        storyRepository: storyRepository,
        syncService: syncService,
        authRepository: authRepository,
        authService: authService,
        shopRepository: shopRepository,
        productRepository: productRepository,
        cartRepository: cartRepository,
        orderRepository: orderRepository,
        messageRepository: messageRepository,
        contactService: contactService,
        whatsAppStatusService: whatsAppStatusService,
        settingsService: settingsService,
        cashRepository: cashRepository,
        fcmService: fcmService,
      );

      if (!kIsWeb) {
        fcmService.registerToken(userPhone: authService.user?.phoneNumber);
      }

      // Start sync AFTER a short delay to prioritize UI rendering
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // Public catalog sync — no AuthService.user required
      await syncService.checkFirstSync();
      unawaited(syncService.warmMediaCache());
      await connectivityService.initialize();
      syncService.bindConnectivity(connectivityService);
      syncService.startAutoSync();
      unawaited(syncService.syncNow());
      unawaited(
        syncService.repairShopsWithoutRemoteId().then((_) {
          if (!syncService.isSyncing) {
            return syncService.syncNow();
          }
        }),
      );

      // Initialize local notifications
      try {
        if (!kIsWeb) {
          final pushService = PushNotificationService(
            notificationService: notificationService,
          );
          await pushService.initialize();
        } else {
          await WebNotificationService.requestPermission();
        }
        _listenForNotificationDeepLinks(
          notificationService,
          shopRepository,
          productRepository,
          storyRepository,
        );
      } catch (e) {
        debugPrint('Error initializing notifications: $e');
      }

      // Daily WhatsApp status auto-prep (24h30)
      try {
        await waStatusScheduler.registerShopOwner(authService.user?.phoneNumber);
        final userShop = await shopRepository.getUserShop(
          authService.user?.phoneNumber ?? '',
        );
        if (userShop != null) {
          await waStatusScheduler.registerShop(userShop.id);
        }
        unawaited(_runWaStatusScheduler());
        _startWaStatusPeriodicCheck();
      } catch (e) {
        debugPrint('WaStatus scheduler init error: $e');
      }
    } catch (e, stack) {
      debugPrint('Service initialization error: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  _UzaServices? _services;

  void _listenForNotificationDeepLinks(
    NotificationService notifService,
    ShopRepository shopRepo,
    ProductRepository productRepo,
    StoryRepository storyRepo,
  ) {
    notifService.addListener(() {
      final link = notifService.consumePendingDeepLink();
      if (link == null) return;

      final type = link['type'] as String?;
      final id = link['id'] as int?;
      if (type == null || id == null) return;

      final navigator = _rootNavigatorKey.currentState;
      if (navigator == null) return;

      switch (type) {
        case 'shop':
          _navigateToShop(navigator, shopRepo, id);
          break;
        case 'product':
          _navigateToProduct(navigator, productRepo, id);
          break;
        case 'arrivage':
          _navigateToArrivage(navigator, storyRepo, shopRepo, id);
          break;
        case 'whatsapp_status':
          _navigateToWhatsAppStatus(navigator, shopRepo, id);
          break;
      }
    });
  }

  void _navigateToWhatsAppStatus(
    NavigatorState navigator,
    ShopRepository repo,
    int shopId,
  ) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => FutureBuilder<Shop?>(
          future: repo.getShopById(shopId),
          builder: (_, snapshot) {
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
            return WhatsAppStatusScreen(shop: snapshot.data!);
          },
        ),
      ),
    );
  }

  void _navigateToShop(NavigatorState navigator, ShopRepository repo, int id) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => FutureBuilder<Shop?>(
          future: repo.resolveShopById(id),
          builder: (_, snapshot) {
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
        ),
      ),
    );
  }

  void _navigateToArrivage(
    NavigatorState navigator,
    StoryRepository storyRepo,
    ShopRepository shopRepo,
    int storyId,
  ) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => FutureBuilder<Story?>(
          future: storyRepo.findStoryByAnyId(storyId),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final story = snapshot.data;
            if (story == null) {
              return Scaffold(
                body: Center(child: Text(tr(context, 'no_arrivals'))),
              );
            }
            return FutureBuilder<List<dynamic>>(
              future: Future.wait([
                storyRepo.getActiveArrivagesByShop(story.shopId),
                shopRepo.getShopById(story.shopId),
              ]),
              builder: (_, dataSnapshot) {
                if (dataSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final arrivages =
                    dataSnapshot.data?[0] as List<Story>? ?? [story];
                final shop = dataSnapshot.data?[1] as Shop?;
                final index = arrivages.indexWhere((s) => s.id == story.id);
                final shopLookup = shop != null ? {shop.id: shop} : <int, Shop>{};
                return StoryViewScreen(
                  stories: arrivages,
                  initialIndex: index >= 0 ? index : 0,
                  shopLookup: shopLookup,
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _navigateToProduct(
    NavigatorState navigator,
    ProductRepository repo,
    int id,
  ) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => FutureBuilder<Product?>(
          future: repo.resolveProductById(id),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return Scaffold(
                body: Center(child: Text(tr(context, 'product_not_found'))),
              );
            }
            return ProductDetailScreen(product: snapshot.data!);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Show splash screen while initializing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen();
        }

        return _buildMainApp();
      },
    );
  }

  Widget _buildSplashScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Uzaapp',
      theme: UzaTheme.lightTheme,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: UzaColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 56,
                      color: UzaColors.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'UzaApp',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: UzaColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: UzaColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainApp() {
    if (_services == null) {
      return _buildSplashScreen();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _services!.notificationService),
        Provider<UzaDatabase>.value(value: _services!.database),
        Provider<ApiService>.value(value: _services!.apiService),
        ProxyProvider<UzaDatabase, StoryRepository>(
          update: (_, db, __) => _services!.storyRepository,
        ),
        ChangeNotifierProxyProvider4<
          UzaDatabase,
          ApiService,
          NotificationService,
          StoryRepository,
          SyncService
        >(
          create: (context) => _services!.syncService,
          update: (_, db, api, notification, storyRepo, current) =>
              _services!.syncService,
        ),
        Provider<AuthRepository>.value(value: _services!.authRepository),
        Provider<CartRepository>.value(value: _services!.cartRepository),
        Provider<OrderRepository>.value(value: _services!.orderRepository),
        Provider<MessageRepository>.value(value: _services!.messageRepository),
        ChangeNotifierProvider<ConnectivityService>.value(
          value: _services!.connectivityService,
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthService>(
          create: (context) => _services!.authService,
          update: (context, repo, current) => _services!.authService,
        ),
        ProxyProvider2<UzaDatabase, SyncService, ShopRepository>(
          update: (_, db, sync, __) => _services!.shopRepository,
        ),
        ProxyProvider2<UzaDatabase, SyncService, ProductRepository>(
          update: (_, db, sync, __) => _services!.productRepository,
        ),
        ProxyProvider<UzaDatabase, ContactService>(
          update: (_, db, __) => _services!.contactService,
        ),
        ProxyProvider<UzaDatabase, WhatsAppStatusService>(
          update: (_, db, __) => _services!.whatsAppStatusService,
        ),
        ChangeNotifierProvider<SettingsService>(
          create: (context) => _services!.settingsService,
        ),
        Provider<CashRepository>.value(value: _services!.cashRepository),
      ],
      child: ErrorBoundary(
        child: Consumer<SettingsService>(
          builder: (context, settings, child) {
            _router ??= AppRouter.create(_rootNavigatorKey);
            _deepLinkService ??= DeepLinkService(_router!)..init();
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Uzaapp',
              theme: UzaTheme.lightTheme,
              darkTheme: UzaTheme.darkTheme,
              themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              locale: Locale(settings.language),
              routerConfig: _router!,
              builder: (context, child) => child ?? const HomeScreen(),
            );
          },
        ),
      ),
    );
  }
}

/// Container for all app services
class _UzaServices {
  final UzaDatabase database;
  final NotificationService notificationService;
  final ConnectivityService connectivityService;
  final ApiService apiService;
  final StoryRepository storyRepository;
  final SyncService syncService;
  final AuthRepository authRepository;
  final AuthService authService;
  final ShopRepository shopRepository;
  final ProductRepository productRepository;
  final CartRepository cartRepository;
  final OrderRepository orderRepository;
  final MessageRepository messageRepository;
  final ContactService contactService;
  final WhatsAppStatusService whatsAppStatusService;
  final SettingsService settingsService;
  final CashRepository cashRepository;
  final FcmService fcmService;

  _UzaServices({
    required this.database,
    required this.notificationService,
    required this.connectivityService,
    required this.apiService,
    required this.storyRepository,
    required this.syncService,
    required this.authRepository,
    required this.authService,
    required this.shopRepository,
    required this.productRepository,
    required this.cartRepository,
    required this.orderRepository,
    required this.messageRepository,
    required this.contactService,
    required this.whatsAppStatusService,
    required this.settingsService,
    required this.cashRepository,
    required this.fcmService,
  });
}
