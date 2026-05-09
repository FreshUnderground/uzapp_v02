import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/res/uza_colors.dart';
import '../../data/local/uza_database.dart';
import 'manage_products_screen.dart';
import 'edit_shop_screen.dart';
import '../../core/services/contact_service.dart';
import '../../data/services/sync_service.dart';
import 'dart:async';
import 'package:drift/drift.dart' as drift;
import '../components/analytics_tab.dart';

class ShopDashboardScreen extends StatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().user?.uid;
    final shopRepo = context.read<ShopRepository>();

    return StreamBuilder<Shop?>(
      stream: shopRepo.watchUserShop(userId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final shop = snapshot.data;
        if (shop == null) {
          return const Scaffold(
            body: Center(child: Text('Boutique introuvable')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: true,
              title: Text(shop.name),
              actions: [
                Consumer<SyncService>(
                  builder: (context, sync, child) {
                    if (sync.isSyncing) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.sync_outlined),
                      tooltip: 'Synchroniser maintenant',
                      onPressed: () => sync.syncNow(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditShopScreen(shop: shop),
                    ),
                  ),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Gestion', icon: Icon(Icons.dashboard_outlined)),
                  Tab(
                    text: 'Statistiques',
                    icon: Icon(Icons.analytics_outlined),
                  ),
                ],
                indicatorColor: UzaColors.primary,
                labelColor: UzaColors.primary,
                unselectedLabelColor: Colors.grey,
              ),
            ),
            body: TabBarView(
              children: [
                // Tab 1: Gestion
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsGrid(shop.id),
                          const SizedBox(height: 32),
                          // Location button for shop dashboard
                          if (shop.latitude != null && shop.longitude != null)
                            _buildLocationButton(context, shop),
                          if (shop.latitude != null && shop.longitude != null)
                            const SizedBox(height: 32),
                          _buildResponsiveLayout(context, shop),
                        ],
                      ),
                    ),
                  ),
                ),
                // Tab 2: Analytics
                AnalyticsTab(shopId: shop.id),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, Shop shop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildRecentContactsSection(shop.id)),
              const SizedBox(width: 48),
              Expanded(
                flex: 2,
                child: _buildManagementSectionWrapper(context, shop),
              ),
            ],
          );
        }

        // Mobile Layout: Stack elements vertically
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildManagementSectionWrapper(context, shop),
            const SizedBox(height: 48),
            _buildRecentContactsSection(shop.id),
          ],
        );
      },
    );
  }

  Widget _buildManagementSectionWrapper(BuildContext context, Shop shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestion',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildManagementSection(context, shop),
      ],
    );
  }

  Widget _buildRecentContactsSection(int shopId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contacts Récents',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildRecentContacts(shopId),
      ],
    );
  }

  Widget _buildStatsGrid(int shopId) {
    return FutureBuilder<Map<String, int>>(
      future: context.read<ShopRepository>().getShopStats(shopId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            final crossAxisCount = isDesktop ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: isDesktop ? 1.8 : 1.3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _statCard(
                  'Suivi',
                  '${stats['totalFollowers'] ?? 0}',
                  Icons.people_outlined,
                  Colors.purple,
                  !isDesktop,
                ),
                _statCard(
                  'Likes',
                  '${stats['totalLikes'] ?? 0}',
                  Icons.favorite_outlined,
                  Colors.red,
                  !isDesktop,
                ),
                _statCard(
                  'Vues Boutique',
                  '${stats['view'] ?? 0}',
                  Icons.storefront_outlined,
                  Colors.blue,
                  !isDesktop,
                ),
                _statCard(
                  'Vues Produits',
                  '${stats['product_view_global'] ?? 0}',
                  Icons.visibility_outlined,
                  Colors.indigo,
                  !isDesktop,
                ),
                _statCard(
                  'Partages',
                  '${stats['totalShares'] ?? 0}',
                  Icons.share_outlined,
                  Colors.orange,
                  !isDesktop,
                ),
                _statCard(
                  'Contacts Client',
                  '${stats['totalContacts'] ?? 0}',
                  Icons.chat_outlined,
                  Colors.green,
                  !isDesktop,
                ),
                _statCard(
                  'Clients Uniques',
                  '${stats['uniqueClients'] ?? 0}',
                  Icons.person_outlined,
                  Colors.deepPurple,
                  !isDesktop,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context, Shop shop) {
    return Column(
      children: [
        // 1. Gérer mes produits
        _managementTile(
          icon: Icons.inventory_2_outlined,
          title: 'Gérer mes produits',
          subtitle: 'Ajouter, modifier ou supprimer',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageProductsScreen(shopId: shop.id),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Gestion et Visibilité
        _buildPromotionSection(shop),
        const SizedBox(height: 24),

        // 3. Partager ma boutique
        _managementTile(
          icon: Icons.share_outlined,
          title: 'Partager ma boutique',
          subtitle: 'Faire connaître votre business',
          iconColor: Colors.blue,
          onTap: () {
            context.read<ContactService>().shareShop(shop);
          },
        ),
      ],
    );
  }

  Widget _buildPromotionSection(Shop shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestion et Visibilité',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusInfo(
          title: 'Booster ma boutique 🚀',
          status: shop.boostStatus,
          onAction: () => _updatePromotionStatus(shop, 'boostStatus', 1),
          isBoostTitle: true,
        ),
        const SizedBox(height: 12),
        _buildStatusInfo(
          title: 'Bannière Publicitaire',
          status: shop.bannerStatus,
          onAction: () => _updatePromotionStatus(shop, 'bannerStatus', 1),
        ),
      ],
    );
  }

  Future<void> _updatePromotionStatus(
    Shop shop,
    String field,
    int status,
  ) async {
    final shopRepo = context.read<ShopRepository>();

    final companion = ShopsCompanion(
      id: drift.Value(shop.id),
      boostStatus: field == 'boostStatus'
          ? drift.Value(status)
          : drift.Value(shop.boostStatus),
      bannerStatus: field == 'bannerStatus'
          ? drift.Value(status)
          : drift.Value(shop.bannerStatus),
    );

    try {
      await shopRepo.updateShop(companion);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Demande envoyée !')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Widget _buildStatusInfo({
    required String title,
    required int status,
    required VoidCallback onAction,
    bool isBoostTitle = false,
  }) {
    Color statusColor = Colors.grey;
    String statusText = "Non actif";
    IconData statusIcon = Icons.info_outline;

    if (status == 1) {
      statusColor = Colors.orange;
      statusText = "En attente (Bureau)";
      statusIcon = Icons.hourglass_empty;
    } else if (status == 2) {
      statusColor = Colors.green;
      statusText = "Actif";
      statusIcon = Icons.check_circle_outline;
    } else if (status == 3) {
      statusColor = Colors.red;
      statusText = "Refusé/Expiré";
      statusIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isBoostTitle ? UzaColors.secondary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (status == 0 || status == 3) const SizedBox(width: 8),
          if (status == 0 || status == 3)
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: UzaColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Demander', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _managementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? UzaColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildRecentContacts(int shopId) {
    return StreamBuilder<List<UserContact>>(
      stream: context.read<ShopRepository>().watchRecentContacts(shopId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.contact_mail_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun contact récent',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = snapshot.data![index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      (contact.contactType == 'whatsapp'
                              ? Colors.green
                              : Colors.blue)
                          .withValues(alpha: 0.1),
                  child: Icon(
                    contact.contactType == 'whatsapp'
                        ? Icons.chat
                        : Icons.phone,
                    color: contact.contactType == 'whatsapp'
                        ? Colors.green
                        : Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(
                  contact.userPhone,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Contacté le ${contact.createdAt.day}/${contact.createdAt.month}/${contact.createdAt.year}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: contact.productId != null
                    ? Tooltip(
                        message: 'Intéressé par un produit',
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: UzaColors.primary,
                        ),
                      )
                    : null,
                onTap: () {}, // Optional: call the user back or chat
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLocationButton(BuildContext context, Shop shop) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditShopScreen(shop: shop)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.withValues(alpha: 0.1),
              Colors.teal.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_location,
                color: Colors.teal,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modifier ma localisation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    'Mettre a jour la position de la boutique',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.teal, size: 28),
          ],
        ),
      ),
    );
  }
}
