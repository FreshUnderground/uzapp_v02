import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import '../components/responsive_layout.dart';
import 'admin/widgets/admin_activity_tab.dart';
import 'admin/widgets/admin_dashboard_tab.dart';
import 'admin/widgets/admin_moderation_panel.dart';
import 'admin/widgets/admin_reports_tab.dart';
import 'admin/widgets/admin_validation_tab.dart';

enum AdminSection { dashboard, moderation, reports, activity }

/// Central admin console: KPIs, moderation, reports, and live activity.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AdminSection _section = AdminSection.dashboard;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(context, 'admin_panel'))),
        body: Center(child: Text(tr(context, 'access_denied'))),
      );
    }

    return ResponsiveLayout(
      mobile: _buildMobile(context),
      desktop: _buildDesktop(context),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'admin_panel')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: _buildContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _section.index,
        onDestinationSelected: (i) =>
            setState(() => _section = AdminSection.values[i]),
        destinations: _navDestinations(context),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'admin_panel')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1300,
            selectedIndex: _section.index,
            onDestinationSelected: (i) =>
                setState(() => _section = AdminSection.values[i]),
            labelType: NavigationRailLabelType.all,
            destinations: _navDestinations(context)
                .map(
                  (d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  List<NavigationDestination> _navDestinations(BuildContext context) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: tr(context, 'admin_nav_dashboard'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.verified_user_outlined),
        selectedIcon: const Icon(Icons.verified_user),
        label: tr(context, 'admin_nav_moderation'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.flag_outlined),
        selectedIcon: const Icon(Icons.flag),
        label: tr(context, 'admin_nav_reports'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.timeline_outlined),
        selectedIcon: const Icon(Icons.timeline),
        label: tr(context, 'admin_nav_activity'),
      ),
    ];
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!ResponsiveLayout.isDesktop(context))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            color: UzaColors.secondary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: UzaColors.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _sectionTitle(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_section),
              child: _sectionWidget(),
            ),
          ),
        ),
      ],
    );
  }

  String _sectionTitle(BuildContext context) {
    switch (_section) {
      case AdminSection.dashboard:
        return tr(context, 'admin_nav_dashboard');
      case AdminSection.moderation:
        return tr(context, 'admin_nav_moderation');
      case AdminSection.reports:
        return tr(context, 'admin_nav_reports');
      case AdminSection.activity:
        return tr(context, 'admin_nav_activity');
    }
  }

  Widget _sectionWidget() {
    switch (_section) {
      case AdminSection.dashboard:
        return AdminDashboardTab(
          onOpenModeration: () =>
              setState(() => _section = AdminSection.moderation),
        );
      case AdminSection.moderation:
        return const AdminValidationTab();
      case AdminSection.reports:
        return const AdminReportsTab();
      case AdminSection.activity:
        return const AdminActivityTab();
    }
  }
}
