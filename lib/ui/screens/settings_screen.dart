import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/settings_service.dart';
import '../../core/l10n/tr.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Map<String, String> _languages = {
    'fr': 'Français',
    'en': 'English',
    'ln': 'Lingala',
    'sw': 'Swahili',
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: UzaColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          tr(context, 'settings'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Language Section
          _buildSectionHeader(Icons.language, tr(context, 'language')),
          _buildCard(
            child: Column(
              children: _languages.entries.map((entry) {
                final isSelected = settings.currentLanguage == entry.key;
                return ListTile(
                  dense: true,
                  leading: Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? UzaColors.primary
                          : UzaColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? UzaColors.primary
                          : UzaColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: UzaColors.primary,
                          size: 22,
                        )
                      : const Icon(
                          Icons.circle_outlined,
                          color: UzaColors.divider,
                          size: 22,
                        ),
                  onTap: () => settings.setLanguage(entry.key),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader(Icons.security, tr(context, 'security')),
          _buildCard(
            child: SwitchListTile(
              secondary: const Icon(
                Icons.fingerprint,
                color: UzaColors.primary,
              ),
              title: Text(
                tr(context, 'biometric_lock'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                settings.biometricEnabled
                    ? tr(context, 'biometric_enabled')
                    : tr(context, 'biometric_disabled'),
                style: const TextStyle(fontSize: 13),
              ),
              value: settings.biometricEnabled,
              onChanged: (val) => _onBiometricToggle(context, settings, val),
            ),
          ),
          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader(Icons.tune, tr(context, 'preferences')),
          _buildCard(
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
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.dark_mode_outlined,
                    color: UzaColors.primary,
                  ),
                  title: Text(
                    tr(context, 'dark_mode'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    settings.isDarkMode
                        ? tr(context, 'enabled')
                        : tr(context, 'disabled'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: settings.isDarkMode,
                  onChanged: (val) => settings.toggleDarkMode(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // More Section
          _buildSectionHeader(Icons.more_horiz, tr(context, 'more')),
          _buildCard(
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
                  Icons.share,
                  tr(context, 'invite_friends'),
                  tr(context, 'share_app'),
                  onTap: () {
                    const message =
                        "Découvrez UzaApp - Le catalogue de produits #1 en RDC!\n\n"
                        "Téléchargez l'application: https://uzaapp.com\n\n"
                        "Envoyé depuis UzaApp";
                    Share.share(message, subject: 'Téléchargez UzaApp');
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  context,
                  Icons.info_outline,
                  tr(context, 'terms'),
                  null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  context,
                  Icons.privacy_tip_outlined,
                  tr(context, 'privacy'),
                  null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _onBiometricToggle(
    BuildContext context,
    SettingsService settings,
    bool value,
  ) async {
    if (!value) {
      // Turning off - no need to check biometrics
      await settings.toggleBiometric(false);
      return;
    }

    // Turning on - check if device supports biometrics
    final localAuth = LocalAuthentication();
    final isSupported = await localAuth.isDeviceSupported();
    final canCheck = await localAuth.canCheckBiometrics;

    if (!isSupported || !canCheck) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'biometric_not_supported')),
            backgroundColor: UzaColors.error,
          ),
        );
      }
      return;
    }

    await settings.toggleBiometric(true);
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

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
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
