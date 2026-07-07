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
import 'core/services/daily_engagement_scheduler.dart';
import 'core/services/system_push_notifier.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/contact_service.dart';
import 'core/services/whatsapp_status_service.dart';
import 'core/services/whatsapp_status_scheduler.dart';
import 'core/services/product_update_service.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/product_update_repository.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/web_notification_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/uza_theme.dart';
import 'core/l10n/app_translations.dart';
import 'core/l10n/tr.dart';
import 'core/utils/test_data_cleanup.dart';
import 'data/local/uza_database.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/message_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/delivery_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'data/repositories/story_repository.dart';
import 'data/repositories/cash_repository.dart';
import 'data/repositories/ya_cope_repository.dart';
import 'data/repositories/review_repository.dart';
import 'core/services/platform_analytics_service.dart';
import 'core/services/product_alerts_service.dart';
import 'core/services/referral_service.dart';
import 'data/services/sync_service.dart';
import 'ui/components/async_content.dart';
import 'ui/components/error_boundary.dart';
import 'ui/screens/product_detail_screen.dart';
import 'ui/screens/shop_profile_screen.dart';
import 'ui/screens/story_view_screen.dart';
import 'ui/screens/whatsapp_status_screen.dart';
import 'ui/screens/seller_deliveries_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await DeepLinkService.captureLaunchUri().timeout(
      const Duration(seconds: 2),
      onTimeout: () => debugPrint('DeepLinkService.captureLaunchUri timeout'),
    );
  } catch (e) {
    debugPrint('DeepLinkService.captureLaunchUri error: $e');
  }
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

  // Notifications bootstrap runs after first frame — must not block runApp().
  if (!kIsWeb) {
    unawaited(
      PushNotificationService.ensureReady(requestPermission: false).catchError(
        (e) => debugPrint('PushNotificationService bootstrap error: $e'),
      ),
    );
  } else {
    // Defer web notification permission — avoids races during Flutter bootstrap.
  }

  // Initialize background tasks (Workmanager) - non-blocking
  if (!kIsWeb) {
    try {
      BackgroundService.initialize();
    } catch (e) {
      debugPrint('BackgroundService initialization error: $e');
    }
  }

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
      final api = _services?.apiService;
      final phone = _services?.authService.user?.phoneNumber;
      if (api != null) {
        unawaited(PlatformAnalyticsService.trackSessionResume(
          api,
          userPhone: phone,
        ));
      }
      final db = _services?.database;
      if (db != null) {
        unawaited(DailyEngagementScheduler.planOnAppOpen(db));
        unawaited(SystemPushNotifier.notifyRandomAfterAppOpen(db));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializationFuture = _initializeServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        unawaited(PushNotificationService.requestOsPermissions());
      }
    });
  }

  Future<void> _runWaStatusScheduler() async {
    final scheduler = _waStatusScheduler;
    if (scheduler == null) return;
    try {
      final services = _services;
      if (services != null) {
        final phone = services.authService.user?.phoneNumber;
        await scheduler.registerShopOwner(phone);
        if (phone != null && phone.isNotEmpty) {
          final userShop = await services.shopRepository.getUserShop(phone);
          if (userShop != null) {
            await scheduler.registerShop(userShop.id);
          }
        }
      }
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
      final database = UzaDatabase();

      // Ensure migrations finish before parallel DB access (SettingsService, sync).
      try {
        await database.customSelect('SELECT 1').getSingle();
      } catch (e) {
        debugPrint('Database warmup error: $e');
        rethrow;
      }

      const String baseUrl = 'https://uzaapp.com/api';

      if (!mounted) return;

      final notificationService = NotificationService();
      final connectivityService = ConnectivityService();
      final apiService = ApiService(baseUrl: baseUrl);
      unawaited(PlatformAnalyticsService.trackAppOpen(apiService));
      final syncService = SyncService(
        database,
        apiService,
        notificationService: notificationService,
      );
      final shopRepository = ShopRepository(database, syncService: syncService);
      final storyRepository = StoryRepository(
        database,
        syncService: syncService,
        shopRepository: shopRepository,
      );
      syncService.storyRepository = storyRepository;
      final authRepository = AuthRepository(database);
      final authService = AuthService(authRepository);
      final productRepository = ProductRepository(
        database,
        syncService: syncService,
        shopRepository: shopRepository,
      );
      final cartRepository = CartRepository(database);
      final orderRepository = OrderRepository(database);
      final deliveryRepository = DeliveryRepository(database);
      syncService.productRepository = productRepository;
      syncService.shopRepository = shopRepository;
      syncService.orderRepository = orderRepository;
      syncService.deliveryRepository = deliveryRepository;
      syncService.productAlertsService = ProductAlertsService();
      final messageRepository = MessageRepository(database);
      final contactService = ContactService(database, syncService: syncService);
      final whatsAppStatusService = WhatsAppStatusService(database);
      final waStatusScheduler = WhatsAppStatusScheduler(
        database,
        whatsAppStatusService,
      );
      _waStatusScheduler = waStatusScheduler;
      final settingsService = SettingsService(database);
      final cashRepository = CashRepository(apiService);
      final fcmService = FcmService(apiService);

      authService.syncService = syncService;
      authService.shopRepository = shopRepository;

      await syncService.checkFirstSync();

      final productUpdateRepository = ProductUpdateRepository(database);
      final productUpdateService = ProductUpdateService(
        db: database,
        productRepository: productRepository,
        updateRepository: productUpdateRepository,
        shopRepository: shopRepository,
        apiService: apiService,
        notificationService: notificationService,
      );

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
        deliveryRepository: deliveryRepository,
        messageRepository: messageRepository,
        contactService: contactService,
        whatsAppStatusService: whatsAppStatusService,
        settingsService: settingsService,
        cashRepository: cashRepository,
        fcmService: fcmService,
        productUpdateRepository: productUpdateRepository,
        productUpdateService: productUpdateService,
      );

      // Sync, connectivity, notifications — after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _services == null) return;
        unawaited(_runDeferredStartupTasks(_services!));
      });
    } catch (e, stack) {
      debugPrint('Service initialization error: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  /// Non-blocking startup: sync, connectivity, notifications, media prefetch.
  Future<void> _runDeferredStartupTasks(_UzaServices services) async {
    try {
      await _runDeferredStartupTasksImpl(services);
    } catch (e, stack) {
      debugPrint('Deferred startup error: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  Future<void> _runDeferredStartupTasksImpl(_UzaServices services) async {
    if (kIsWeb) {
      unawaited(
        WebNotificationService.requestPermission().catchError((e) {
          debugPrint('WebNotificationService permission error: $e');
          return false;
        }),
      );
    }

    final database = services.database;
    final syncService = services.syncService;
    final connectivityService = services.connectivityService;
    final notificationService = services.notificationService;
    final settingsService = services.settingsService;
    final authService = services.authService;
    final shopRepository = services.shopRepository;
    final productRepository = services.productRepository;
    final storyRepository = services.storyRepository;
    final waStatusScheduler = _waStatusScheduler;
    final fcmService = services.fcmService;

    syncService.liteMode = settingsService.isLiteMode;

    unawaited(
      TestDataCleanup.purgeLocal(database).then((purged) {
        if (purged > 0) {
          debugPrint('TestDataCleanup deferred: removed $purged local test records');
        }
      }).catchError(
        (e) {
          debugPrint('TestDataCleanup deferred error: $e');
        },
      ),
    );

    unawaited(
      applyPendingReferralToDb(database).catchError(
        (e) => debugPrint('applyPendingReferralToDb error: $e'),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_app_open',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('SharedPreferences error: $e');
    }

    // Connectivity first so sync uses adaptive timeouts and offline detection.
    unawaited(
      connectivityService.initialize().then(
        (_) {
          syncService.bindConnectivity(connectivityService);
          syncService.startAutoSync();
        },
        onError: (e) => debugPrint('Connectivity init error: $e'),
      ),
    );

    if (!kIsWeb) {
      unawaited(_registerFcmTokenDeferred(
        fcmService: fcmService,
        authService: authService,
        shopRepository: shopRepository,
      ));
    }

    await syncService.checkFirstSync();
    unawaited(
      syncService.requestBootstrapSync().catchError((e) {
        debugPrint('Deferred bootstrap sync error: $e');
      }),
    );

    try {
      PushNotificationService.attachDeepLinkHandler(notificationService);
      PushNotificationService.attachNotificationsGate(
        () => settingsService.notificationsEnabled,
      );
      notificationService.setEnabled(settingsService.notificationsEnabled);
      settingsService.addListener(() {
        notificationService.setEnabled(settingsService.notificationsEnabled);
      });
      _listenForNotificationDeepLinks(
        notificationService,
        shopRepository,
        productRepository,
        storyRepository,
      );
      unawaited(
        DailyEngagementScheduler.planOnAppOpen(database).catchError(
          (e) => debugPrint('DailyEngagementScheduler error: $e'),
        ),
      );
      unawaited(
        SystemPushNotifier.notifyRandomAfterAppOpen(database).catchError(
          (e) => debugPrint('SystemPushNotifier error: $e'),
        ),
      );
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }

    if (waStatusScheduler != null) {
      unawaited(_initWaStatusSchedulerDeferred(
        waStatusScheduler: waStatusScheduler,
        authService: authService,
        shopRepository: shopRepository,
      ));
    }

    // Prefetch media only after the UI has had time to render.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 5)).then((_) async {
        if (!mounted) return;
        await syncService.warmMediaCache();
      }).catchError(
        (e) {
          debugPrint('warmMediaCache error: $e');
        },
      ),
    );
  }

  Future<void> _registerFcmTokenDeferred({
    required FcmService fcmService,
    required AuthService authService,
    required ShopRepository shopRepository,
  }) async {
    try {
      final phone = authService.user?.phoneNumber;
      if (phone != null && phone.isNotEmpty) {
        await shopRepository
            .reconnectShopsForUser(phone)
            .timeout(const Duration(seconds: 5));
        final shop = await shopRepository
            .watchUserShop(phone)
            .first
            .timeout(const Duration(seconds: 3));
        final remoteShopId = shop?.remoteId != null
            ? int.tryParse(shop!.remoteId!)
            : null;
        await fcmService
            .registerToken(userPhone: phone, shopId: remoteShopId)
            .timeout(const Duration(seconds: 5));
      } else {
        await fcmService
            .registerToken(userPhone: phone)
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('FCM deferred registration error: $e');
    }
  }

  Future<void> _initWaStatusSchedulerDeferred({
    required WhatsAppStatusScheduler waStatusScheduler,
    required AuthService authService,
    required ShopRepository shopRepository,
  }) async {
    try {
      await waStatusScheduler
          .registerShopOwner(authService.user?.phoneNumber)
          .timeout(const Duration(seconds: 3));
      final userShop = await shopRepository
          .getUserShop(authService.user?.phoneNumber ?? '')
          .timeout(const Duration(seconds: 3));
      if (userShop != null) {
        await waStatusScheduler
            .registerShop(userShop.id)
            .timeout(const Duration(seconds: 3));
      }
      unawaited(_runWaStatusScheduler());
      _startWaStatusPeriodicCheck();
    } catch (e) {
      debugPrint('WaStatus scheduler init error: $e');
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
        case 'delivery':
          final shopId = link['shop_id'] as int? ?? id;
          _navigateToDeliveries(navigator, shopRepo, shopId);
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
        builder: (_) => FutureRouteContent<Shop>(
          load: () => repo.resolveShopById(shopId),
          isNotFound: (shop) => shop == null,
          notFound: Scaffold(
            body: Center(child: Text(tr(context, 'shop_not_found'))),
          ),
          builder: (shop) => WhatsAppStatusScreen(shop: shop),
        ),
      ),
    );
  }

  void _navigateToDeliveries(
    NavigatorState navigator,
    ShopRepository repo,
    int shopIdOrRemote,
  ) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => FutureRouteContent<Shop>(
          load: () => repo.resolveShopById(shopIdOrRemote),
          isNotFound: (shop) => shop == null,
          notFound: Scaffold(
            body: Center(child: Text(tr(context, 'shop_not_found'))),
          ),
          builder: (shop) => SellerDeliveriesScreen(shopId: shop.id),
        ),
      ),
    );
  }

  void _navigateToShop(NavigatorState navigator, ShopRepository repo, int id) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => FutureRouteContent<Shop>(
          load: () => repo.resolveShopById(id),
          isNotFound: (shop) => shop == null,
          notFound: Scaffold(
            body: Center(child: Text(tr(context, 'shop_not_found'))),
          ),
          builder: (shop) => ShopProfileScreen(shop: shop),
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
        builder: (_) => FutureRouteContent<Product>(
          load: () => repo.resolveProductById(id),
          isNotFound: (product) => product == null,
          notFound: Scaffold(
            body: Center(child: Text(tr(context, 'product_not_found'))),
          ),
          builder: (product) => ProductDetailScreen(product: product),
        ),
      ),
    );
  }

  void _retryInitialization() {
    setState(() {
      _initializationFuture = _initializeServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen();
        }

        if (snapshot.hasError ||
            (snapshot.connectionState == ConnectionState.done &&
                _services == null)) {
          return _buildInitErrorScreen();
        }

        return _buildMainApp();
      },
    );
  }

  Widget _buildInitErrorScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Uzaapp',
      theme: UzaTheme.lightTheme,
      locale: const Locale('fr'),
      localizationsDelegates: AppTranslations.localizationsDelegates,
      supportedLocales: AppTranslations.materialLocales,
      home: Scaffold(
        body: ErrorFallback(
          message: AppTranslations.translate('init_error_hint', 'fr'),
          onRetry: _retryInitialization,
        ),
      ),
    );
  }

  Widget _buildSplashScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Uzaapp',
      theme: UzaTheme.lightTheme,
      locale: const Locale('fr'),
      localizationsDelegates: AppTranslations.localizationsDelegates,
      supportedLocales: AppTranslations.materialLocales,
      home: Scaffold(
        backgroundColor: UzaColors.surfaceOf(context),
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
        Provider<DeliveryRepository>.value(value: _services!.deliveryRepository),
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
        ProxyProvider<ApiService, YaCopeRepository>(
          update: (_, api, __) => YaCopeRepository(api),
        ),
        Provider<ReviewRepository>(
          create: (_) => ReviewRepository(_services!.database),
        ),
        Provider<ProductAlertsService>(
          create: (_) => ProductAlertsService(),
        ),
        Provider<ReferralService>(
          create: (_) => ReferralService(),
        ),
        Provider<ProductUpdateRepository>.value(
          value: _services!.productUpdateRepository,
        ),
        Provider<ProductUpdateService>.value(
          value: _services!.productUpdateService,
        ),
      ],
      child: ErrorBoundary(
        child: Consumer<SettingsService>(
          builder: (context, settings, child) {
            _services!.syncService.liteMode = settings.isLiteMode;
            _router ??= AppRouter.create(_rootNavigatorKey);
            AppRouter.ensureWebLocation(_router!);
            _deepLinkService ??= DeepLinkService(_router!)..init();
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Uzaapp',
              theme: UzaTheme.lightTheme,
              darkTheme: UzaTheme.darkTheme,
              themeMode: settings.themeMode,
              locale: settings.locale,
              localizationsDelegates: AppTranslations.localizationsDelegates,
              supportedLocales: AppTranslations.materialLocales,
              routerConfig: _router!,
              builder: (context, child) {
                final media = MediaQuery.of(context);
                final padding = media.padding;
                final viewPadding = media.viewPadding;
                // Some Android devices report zero padding in edge-to-edge mode.
                final effectivePadding = EdgeInsets.fromLTRB(
                  padding.left > 0 ? padding.left : viewPadding.left,
                  padding.top > 0 ? padding.top : viewPadding.top,
                  padding.right > 0 ? padding.right : viewPadding.right,
                  padding.bottom > 0 ? padding.bottom : viewPadding.bottom,
                );
                return MediaQuery(
                  data: media.copyWith(padding: effectivePadding),
                  child: child ??
                      const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      ),
                );
              },
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
  final DeliveryRepository deliveryRepository;
  final MessageRepository messageRepository;
  final ContactService contactService;
  final WhatsAppStatusService whatsAppStatusService;
  final SettingsService settingsService;
  final CashRepository cashRepository;
  final FcmService fcmService;
  final ProductUpdateRepository productUpdateRepository;
  final ProductUpdateService productUpdateService;

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
    required this.deliveryRepository,
    required this.messageRepository,
    required this.contactService,
    required this.whatsAppStatusService,
    required this.settingsService,
    required this.cashRepository,
    required this.fcmService,
    required this.productUpdateRepository,
    required this.productUpdateService,
  });
}
