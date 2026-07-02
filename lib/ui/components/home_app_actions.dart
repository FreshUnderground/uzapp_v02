import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/l10n/tr.dart';
import '../../core/services/settings_service.dart';
import '../../data/repositories/cart_repository.dart';
import '../screens/cart_screen.dart';
import '../utils/page_transitions.dart';

class HomeAppActions {
  static List<Widget> build(
    BuildContext context, {
    bool includeCreate = false,
    VoidCallback? onCreateShop,
    VoidCallback? onCreateProduct,
    bool hasShop = false,
  }) {
    final actions = <Widget>[
      _cartButton(context),
      _languageSelector(context),
      _profileButton(context),
      if (includeCreate && onCreateShop != null && onCreateProduct != null)
        _createButton(
          context,
          hasShop: hasShop,
          onCreateShop: onCreateShop,
          onCreateProduct: onCreateProduct,
        ),
      const SizedBox(width: 8),
    ];
    return actions;
  }

  static Widget _cartButton(BuildContext context) {
    try {
      return StreamBuilder<int>(
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
      );
    } catch (_) {
      return IconButton(
        icon: const Icon(Icons.shopping_cart_outlined),
        onPressed: () =>
            Navigator.push(context, SlideUpRoute(page: const CartScreen())),
      );
    }
  }

  static Widget _languageSelector(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final currentFlag = settings.languagePreference == 'system'
        ? '📱'
        : _getLanguageFlag(settings.currentLanguage);

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 20),
          const SizedBox(width: 4),
          Text(currentFlag, style: const TextStyle(fontSize: 18)),
        ],
      ),
      tooltip: tr(context, 'language'),
      itemBuilder: (context) {
        return AppTranslations.languagePreferenceOptions.map((String code) {
          final languageName = trLanguageName(context, code);
          final flag =
              code == 'system' ? '📱' : _getLanguageFlag(code);
          final isSelected =
              context.read<SettingsService>().languagePreference == code;
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

  static Widget _profileButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.person_outline),
      tooltip: tr(context, 'profile'),
      onPressed: () => context.push('/profile'),
    );
  }

  static Widget _createButton(
    BuildContext context, {
    required bool hasShop,
    required VoidCallback onCreateShop,
    required VoidCallback onCreateProduct,
  }) {
    return IconButton(
      tooltip: hasShop
          ? tr(context, 'add_product')
          : tr(context, 'create_shop'),
      icon: Icon(hasShop ? Icons.add : Icons.storefront),
      onPressed: hasShop ? onCreateProduct : onCreateShop,
    );
  }

  static String _getLanguageFlag(String code) {
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

  static String tabTitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return tr(context, 'home');
      case 1:
        return tr(context, 'discover');
      case 2:
        return tr(context, 'ya_cope');
      case 3:
        return tr(context, 'boutiques');
      default:
        return 'UzaApp';
    }
  }
}
