import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/marketing_share_sheet.dart';
import '../components/uza_secondary_app_bar.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/settings_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/l10n/tr.dart';
import '../../core/l10n/app_translations.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    final surface = Theme.of(context).scaffoldBackgroundColor;

    return UzaBackScope(
      child: Scaffold(
      backgroundColor: surface,
      appBar: UzaSecondaryAppBar(
        title: tr(context, 'settings'),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Language Section with Dropdown
          _buildSectionHeader(Icons.language, tr(context, 'language')),
          _buildCard(
            context,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: settings.languagePreference,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: UzaColors.primary,
                    size: 24,
                  ),
                  iconSize: 24,
                  elevation: 8,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  items: AppTranslations.languagePreferenceOptions.map((code) {
                    final languageName = trLanguageName(context, code);
                    final flag = code == 'system'
                        ? '📱'
                        : _getLanguageFlag(code);
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Row(
                        children: [
                          Text(flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Text(languageName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setLanguage(newValue);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(Icons.dark_mode_outlined, tr(context, 'dark_mode')),
          _buildCard(
            context,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: settings.themeModePreference,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: UzaColors.primary,
                    size: 24,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  items: AppTranslations.themeModeOptions.map((mode) {
                    return DropdownMenuItem<String>(
                      value: mode,
                      child: Text(trThemeMode(context, mode)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setThemeMode(newValue);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader(Icons.tune, tr(context, 'preferences')),
          _buildCard(
            context,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_none,
                    color: UzaColors.primary,
                  ),
                  title: Text(
                    tr(context, 'notifications'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    tr(context, 'notifications_subtitle'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (val) => settings.toggleNotifications(val),
                ),
                _buildWaStatusToggle(context, settings),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // More Section
          _buildSectionHeader(Icons.more_horiz, tr(context, 'more')),
          _buildCard(
            context,
            child: Column(
              children: [
                _buildTile(
                  context,
                  Icons.person_outline,
                  tr(context, 'personal_info'),
                  tr(context, 'manage_profile'),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  context,
                  Icons.group_add_rounded,
                  tr(context, 'invite_friends'),
                  tr(context, 'share_app'),
                  onTap: () => MarketingShareSheet.showAppInvite(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  context,
                  Icons.info_outline,
                  tr(context, 'terms'),
                  null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalScreen(
                        type: LegalDocumentType.terms,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  context,
                  Icons.privacy_tip_outlined,
                  tr(context, 'privacy'),
                  null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalScreen(
                        type: LegalDocumentType.privacy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _buildWaStatusToggle(BuildContext context, SettingsService settings) {
    final userId = context.read<AuthService>().user?.uid ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder(
      stream: context.read<ShopRepository>().watchUserShop(userId),
      builder: (context, snapshot) {
        final hasShop = snapshot.hasData && snapshot.data != null;
        if (!hasShop) return const SizedBox.shrink();

        return Column(
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              secondary: const Icon(
                Icons.collections_outlined,
                color: Color(0xFF25D366),
              ),
              title: Text(
                tr(context, 'wa_status_auto'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                settings.waStatusAutoEnabled
                    ? tr(context, 'wa_status_auto_on')
                    : tr(context, 'wa_status_auto_off'),
                style: const TextStyle(fontSize: 13),
              ),
              value: settings.waStatusAutoEnabled,
              onChanged: (val) => settings.toggleWaStatusAuto(val),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: UzaColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: UzaColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      child: child,
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    String? subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: UzaColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 13))
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: UzaColors.divider,
      ),
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title ${tr(context, 'coming_soon')}')),
            );
          },
    );
  }
}
