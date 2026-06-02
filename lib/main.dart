import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/res/uza_colors.dart';
import 'core/router/app_router.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/background_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/contact_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/settings_service.dart';
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
import 'data/services/sync_service.dart';
import 'ui/components/error_boundary.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/product_detail_screen.dart';
import 'ui/screens/shop_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class BiometricGuard extends StatefulWidget {
  final Widget child;

  const BiometricGuard({super.key, required this.child});

  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard> {
  bool _isAuthenticated = false;
  bool _isChecking = false;
  bool _authAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final localAuth = LocalAuthentication();
    try {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Déverrouillez UzaApp',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate && mounted) {
        setState(() => _isAuthenticated = true);
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _authAttempted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    // If biometric is disabled or already authenticated, show the app
    if (!settings.biometricEnabled || _isAuthenticated) {
      return widget.child;
    }

    // Show lock screen
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
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
                        Icons.lock_outline,
                        size: 56,
                        color: UzaColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'UzaApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: UzaColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(context, 'app_locked'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: UzaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _authenticate,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.fingerprint, size: 24),
                    label: Text(
                      _isChecking
                          ? tr(context, 'verifying')
                          : tr(context, 'unlock'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UzaColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                if (_authAttempted && !_isAuthenticated) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isChecking ? null : _authenticate,
                    child: Text(
                      tr(context, 'retry'),
                      style: const TextStyle(color: UzaColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class UzaApp extends StatefulWidget {
  const UzaApp({super.key});

  @override
  State<UzaApp> createState() => _UzaAppState();
}

class _UzaAppState extends State<UzaApp> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Initialize services asynchronously without blocking UI
    _initializationFuture = _initializeServices();
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
      final settingsService = SettingsService(database);

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
        settingsService: settingsService,
      );

      // Start sync AFTER a short delay to prioritize UI rendering
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // Public catalog sync — no AuthService.user required
      await syncService.checkFirstSync();
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
      if (!kIsWeb) {
        try {
          final pushService = PushNotificationService(
            notificationService: notificationService,
          );
          await pushService.initialize();
          _listenForNotificationDeepLinks(
            notificationService,
            shopRepository,
            productRepository,
          );
        } catch (e) {
          debugPrint('Error initializing notifications: $e');
        }
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
          // Arrivages are stories; for now navigate to the shop that posted it
          _navigateToShop(navigator, shopRepo, id);
          break;
      }
    });
  }

  void _navigateToShop(NavigatorState navigator, ShopRepository repo, int id) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => FutureBuilder<Shop?>(
          future: repo.getShopById(id),
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

  void _navigateToProduct(
    NavigatorState navigator,
    ProductRepository repo,
    int id,
  ) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => FutureBuilder<Product?>(
          future: repo.getProductById(id),
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

        // Show main app with all services ready
        // Skip BiometricGuard for faster startup - go directly to HomeScreen
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
        ChangeNotifierProvider<SettingsService>(
          create: (context) => _services!.settingsService,
        ),
      ],
      child: ErrorBoundary(
        child: Consumer<SettingsService>(
          builder: (context, settings, child) {
            final router = AppRouter.create(_rootNavigatorKey);
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Uzaapp',
              theme: UzaTheme.lightTheme,
              darkTheme: ThemeData.dark().copyWith(
                primaryColor: UzaColors.primary,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: UzaColors.primary,
                  brightness: Brightness.dark,
                ),
              ),
              themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              locale: Locale(settings.language),
              routerConfig: router,
              builder: (context, child) {
                if (settings.biometricEnabled) {
                  return BiometricGuard(
                    child: child ?? const HomeScreen(),
                  );
                }
                return child ?? const HomeScreen();
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
  final MessageRepository messageRepository;
  final ContactService contactService;
  final SettingsService settingsService;

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
    required this.settingsService,
  });
}
