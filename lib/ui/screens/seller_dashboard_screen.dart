import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import '../components/modern_card.dart';
import '../components/tap_animator.dart';
import '../components/staggered_list.dart';
import '../components/retention_widgets.dart';

class SellerDashboardScreen extends StatefulWidget {
  final int shopId;
  const SellerDashboardScreen({super.key, required this.shopId});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  Map<String, int>? _shopStats;
  Map<String, int>? _weeklyStats;
  List<Map<String, dynamic>>? _topProducts;
  List<Map<String, dynamic>>? _regularClients;
  List<Map<String, dynamic>>? _recentActivity;
  Shop? _shop;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final shopRepo = context.read<ShopRepository>();
    final productRepo = context.read<ProductRepository>();

    final shop = shopRepo.getShopById(widget.shopId);

    // Load all data in parallel
    final results = await Future.wait([
      shopRepo.getShopStats(widget.shopId),
      shopRepo.getWeeklyStats(widget.shopId),
      productRepo.getTopProducts(widget.shopId),
      shopRepo.getRegularClients(widget.shopId),
      shopRepo.getRecentActivity(widget.shopId),
      shop,
    ]);

    if (mounted) {
      setState(() {
        _shopStats = results[0] as Map<String, int>;
        _weeklyStats = results[1] as Map<String, int>;
        _topProducts = results[2] as List<Map<String, dynamic>>;
        _regularClients = results[3] as List<Map<String, dynamic>>;
        _recentActivity = results[4] as List<Map<String, dynamic>>;
        _shop = results[5] as Shop?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: UzaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _loadData, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    final hasAnyData =
        _shopStats != null &&
        (_shopStats!['totalViews']! > 0 ||
            _shopStats!['totalContacts']! > 0 ||
            _shopStats!['productsCount']! > 0);

    if (!hasAnyData && (_topProducts?.isEmpty ?? true)) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        // Header with shop name
        if (_shop != null) _buildHeader(),
        const SizedBox(height: 8),

        // Weekly metrics banner
        StaggeredListItem(
          index: 0,
          child: WeeklyMetricsBanner(
            weeklyViews: _weeklyStats?['weeklyViews'] ?? 0,
            weeklyContacts: _weeklyStats?['weeklyContacts'] ?? 0,
          ),
        ),

        // Stats card
        StaggeredListItem(
          index: 1,
          child: SellerStatsCard(
            totalViews: _shopStats?['totalViews'] ?? 0,
            totalContacts: _shopStats?['totalContacts'] ?? 0,
            totalFollowers: _shopStats?['totalFollowers'] ?? 0,
            productsCount: _shopStats?['productsCount'] ?? 0,
          ),
        ),

        const SizedBox(height: 8),

        // Top products section
        if (_topProducts != null && _topProducts!.isNotEmpty)
          StaggeredListItem(index: 2, child: _buildTopProductsSection()),

        const SizedBox(height: 8),

        // Regular clients section
        StaggeredListItem(
          index: 3,
          child: RegularClientsSection(
            regularClients: (_regularClients ?? []).map((c) {
              return ClientContact(
                phone: c['phone'] as String,
                contactCount: c['contactCount'] as int,
                lastContact: c['lastContact'] as DateTime,
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Activity timeline
        if (_recentActivity != null && _recentActivity!.isNotEmpty)
          StaggeredListItem(index: 4, child: _buildActivityTimeline()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            UzaColors.primary,
            UzaColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: UzaColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _shop?.logoUrl != null && _shop!.logoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ImageUtils.buildCachedImage(
                      _shop!.logoUrl,
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover,
                      placeholder: const Icon(Icons.store, color: Colors.white),
                    ),
                  )
                : const Icon(Icons.store, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shop!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tableau de bord',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection() {
    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UzaColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: UzaColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tes meilleurs produits',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._topProducts!.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return _TopProductItem(product: product, rank: index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UzaColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: UzaColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Activité récente',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._recentActivity!.map((activity) {
            return _ActivityItem(activity: activity);
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 24),
        const Text(
          'Aucune stat encore',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Publie des produits pour commencer à voir tes stats ici',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: UzaColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),
        if (_shopStats != null)
          SellerStatsCard(
            totalViews: _shopStats!['totalViews'] ?? 0,
            totalContacts: _shopStats!['totalContacts'] ?? 0,
            totalFollowers: _shopStats!['totalFollowers'] ?? 0,
            productsCount: _shopStats!['productsCount'] ?? 0,
          ),
      ],
    );
  }
}

/// A single top product row with rank, image, name, and metrics
class _TopProductItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final int rank;

  const _TopProductItem({required this.product, required this.rank});

  @override
  Widget build(BuildContext context) {
    final imageUrls = product['imageUrls'] as String? ?? '';
    final firstImage = imageUrls.split(',').firstOrNull ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapAnimator(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? UzaColors.primary.withValues(alpha: 0.1)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: rank <= 3
                          ? UzaColors.primary
                          : UzaColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Product image
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: firstImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ImageUtils.buildCachedImage(
                          firstImage,
                          height: 44,
                          width: 44,
                          fit: BoxFit.cover,
                          placeholder: const Icon(
                            Icons.image_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 12),

              // Product name + metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MetricChip(
                          icon: Icons.visibility_outlined,
                          value: product['views'] ?? 0,
                          color: UzaColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _MetricChip(
                          icon: Icons.phone_android_rounded,
                          value: product['contacts'] ?? 0,
                          color: UzaColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        _MetricChip(
                          icon: Icons.share_outlined,
                          value: product['shares'] ?? 0,
                          color: const Color(0xFF6C5CE7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact metric chip: icon + count
class _MetricChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// A single activity timeline row
class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isContact = activity['isContact'] as bool? ?? false;
    final productName = activity['productName'] as String?;
    final createdAt = activity['createdAt'] as DateTime?;
    final interactionType = activity['interactionType'] as String? ?? '';

    final String description;
    final IconData icon;
    final Color color;

    if (isContact) {
      description = productName != null
          ? "Quelqu'un t'a contacté pour $productName"
          : "Quelqu'un t'a contacté";
      icon = Icons.phone_android_rounded;
      color = UzaColors.secondary;
    } else if (interactionType == 'share') {
      description = productName != null
          ? "Quelqu'un a partagé $productName"
          : "Quelqu'un a partagé ta boutique";
      icon = Icons.share_outlined;
      color = const Color(0xFF6C5CE7);
    } else {
      description = productName != null
          ? "Quelqu'un a vu $productName"
          : "Quelqu'un a vu ta boutique";
      icon = Icons.visibility_outlined;
      color = UzaColors.primary;
    }

    final timeAgo = createdAt != null ? _getTimeAgo(createdAt) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 10,
              color: UzaColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return 'Il y a ${diff.inDays ~/ 7} sem.';
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}min';
    return "À l'instant";
  }
}
