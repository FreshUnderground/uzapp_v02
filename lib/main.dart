import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'core/res/uza_colors.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/contact_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_service.dart';
import 'core/theme/uza_theme.dart';
import 'data/local/uza_database.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'data/repositories/story_repository.dart';
import 'data/services/sync_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/product_detail_screen.dart';
import 'ui/screens/shop_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow fetching fonts from the internet if AssetManifest.json is missing on web
  GoogleFonts.config.allowRuntimeFetching = true;

  try {
    final database = UzaDatabase();

    // Data is now fetched via SyncService from the production API

    // Use local URL for development if production is not reachable
    const String baseUrl = 'https://uzaapp.com/api';
    // const String baseUrl = 'http://localhost/uzaapp/server/api';

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NotificationService()),
          Provider<UzaDatabase>.value(value: database),
          Provider<ApiService>(create: (_) => ApiService(baseUrl: baseUrl)),
          ChangeNotifierProxyProvider3<
            UzaDatabase,
            ApiService,
            NotificationService,
            SyncService
          >(
            create: (context) => SyncService(
              context.read<UzaDatabase>(),
              context.read<ApiService>(),
              notificationService: context.read<NotificationService>(),
            ),
            update: (_, db, api, notification, current) => current!,
          ),
          Provider<AuthRepository>(create: (_) => AuthRepository(database)),
          Provider<CartRepository>(create: (_) => CartRepository(database)),
          ChangeNotifierProxyProvider<AuthRepository, AuthService>(
            create: (context) => AuthService(context.read<AuthRepository>()),
            update: (context, repo, current) => current ?? AuthService(repo),
          ),
          ProxyProvider<UzaDatabase, ShopRepository>(
            update: (_, db, __) => ShopRepository(db),
          ),
          ProxyProvider2<UzaDatabase, SyncService, ProductRepository>(
            update: (_, db, sync, __) =>
                ProductRepository(db, syncService: sync),
          ),
          ProxyProvider<UzaDatabase, StoryRepository>(
            update: (_, db, __) => StoryRepository(db),
          ),
          ProxyProvider<UzaDatabase, ContactService>(
            update: (_, db, __) => ContactService(db),
          ),
          ChangeNotifierProvider<SettingsService>(
            create: (context) => SettingsService(context.read<UzaDatabase>()),
          ),
        ],
        child: const UzaApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint("BOOTSTRAP ERROR: $e");
    debugPrint("STACK TRACE: $stack");
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text("Erreur au démarrage: $e"))),
      ),
    );
  }
}

class BiometricGuard extends StatefulWidget {
  const BiometricGuard({super.key});

  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard> {
  bool _isAuthenticated = false;
  bool _isChecking = false;

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
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    // If biometric is disabled or already authenticated, show the app
    if (!settings.biometricEnabled || _isAuthenticated) {
      return const HomeScreen();
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
                const Text(
                  'L\'app est verrouillée',
                  style: TextStyle(
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
                      _isChecking ? 'Vérification...' : 'Déverrouiller',
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
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isChecking
                      ? null
                      : () => setState(() => _isAuthenticated = true),
                  child: const Text(
                    'Passer (mode invité)',
                    style: TextStyle(color: UzaColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UzaApp extends StatelessWidget {
  const UzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Start background sync
    final syncService = context.read<SyncService>();
    context.read<AuthService>().syncService = syncService;
    context.read<AuthService>().shopRepository = context.read<ShopRepository>();
    syncService.startAutoSync(
      interval: const Duration(minutes: 1),
    ); // Faster for demo
    // Eager initial sync — don't wait for the timer interval
    syncService.checkFirstSync(); // Initialise isFirstSync flag from local DB
    syncService.syncNow();

    return Consumer2<SettingsService, SyncService>(
      builder: (context, settings, sync, child) {
        return MaterialApp(
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
          home: const BiometricGuard(),
          onGenerateRoute: (settings) {
            // Deep link handling for uzaapp.com (#/shop/1 or #/product/1)
            final uri = Uri.parse(settings.name ?? '');
            if (uri.pathSegments.length >= 2) {
              final id = int.tryParse(uri.pathSegments[1]);
              if (id != null) {
                if (uri.pathSegments[0] == 'shop') {
                  return MaterialPageRoute(
                    builder: (context) => FutureBuilder<Shop?>(
                      future: context.read<ShopRepository>().getShopById(id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        if (!snapshot.hasData || snapshot.data == null)
                          return const Scaffold(
                            body: Center(child: Text('Boutique introuvable')),
                          );
                        return ShopProfileScreen(shop: snapshot.data!);
                      },
                    ),
                  );
                } else if (uri.pathSegments[0] == 'product') {
                  return MaterialPageRoute(
                    builder: (context) => FutureBuilder<Product?>(
                      future: context.read<ProductRepository>().getProductById(
                        id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        if (!snapshot.hasData || snapshot.data == null)
                          return const Scaffold(
                            body: Center(child: Text('Produit introuvable')),
                          );
                        return ProductDetailScreen(product: snapshot.data!);
                      },
                    ),
                  );
                }
              }
            }
            return null;
          },
        );
      },
    );
  }
}
