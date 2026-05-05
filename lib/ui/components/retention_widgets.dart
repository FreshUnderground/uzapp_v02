import 'package:flutter/material.dart';
import '../../core/res/uza_colors.dart';
import 'modern_card.dart';
import 'tap_animator.dart';

/// Shows "Tu as X produits dans ta liste" reminder
class WishlistReminder extends StatelessWidget {
  final int wishlistCount;
  final VoidCallback onTap;

  const WishlistReminder({
    super.key,
    required this.wishlistCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (wishlistCount == 0) return const SizedBox.shrink();

    return TapAnimator(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              UzaColors.primary.withValues(alpha: 0.08),
              UzaColors.secondary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UzaColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: UzaColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: UzaColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu as $wishlistCount produit${wishlistCount > 1 ? 's' : ''} dans ta liste',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ils pourraient ne plus être disponibles',
                    style: TextStyle(
                      color: UzaColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: UzaColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Voir ma liste',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows "X vendeurs ont ajouté des produits" notification-style
class SellerActivityCard extends StatelessWidget {
  final int activeSellerCount;
  final VoidCallback onTap;

  const SellerActivityCard({
    super.key,
    required this.activeSellerCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activeSellerCount == 0) return const SizedBox.shrink();

    return TapAnimator(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UzaColors.secondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UzaColors.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: UzaColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: UzaColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$activeSellerCount vendeur${activeSellerCount > 1 ? 's' : ''} ont ajouté des produits',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: UzaColors.secondary, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Shows engagement stats for sellers in a 2x2 grid
class SellerStatsCard extends StatelessWidget {
  final int totalViews;
  final int totalContacts;
  final int totalFollowers;
  final int productsCount;

  const SellerStatsCard({
    super.key,
    required this.totalViews,
    required this.totalContacts,
    required this.totalFollowers,
    required this.productsCount,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tes statistiques',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.visibility_outlined,
                  label: 'vues',
                  value: totalViews,
                  color: UzaColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatItem(
                  icon: Icons.phone_android_rounded,
                  label: 'contacts',
                  value: totalContacts,
                  color: UzaColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.people_outline_rounded,
                  label: 'abonnés',
                  value: totalFollowers,
                  color: const Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'produits',
                  value: productsCount,
                  color: const Color(0xFFFDCB6E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: UzaColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Tu as reçu X demandes cette semaine" banner for sellers
class WeeklyMetricsBanner extends StatelessWidget {
  final int weeklyViews;
  final int weeklyContacts;

  const WeeklyMetricsBanner({
    super.key,
    required this.weeklyViews,
    required this.weeklyContacts,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyViews == 0 && weeklyContacts == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            UzaColors.primary,
            UzaColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: UzaColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Cette semaine: $weeklyViews vue${weeklyViews > 1 ? 's' : ''}, $weeklyContacts contact${weeklyContacts > 1 ? 's' : ''} reçus ✨',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Regular clients section for sellers — shows phone numbers that contacted multiple times
class RegularClientsSection extends StatelessWidget {
  final List<ClientContact> regularClients;

  const RegularClientsSection({super.key, required this.regularClients});

  @override
  Widget build(BuildContext context) {
    if (regularClients.isEmpty) return const SizedBox.shrink();

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
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.repeat_rounded,
                  color: Color(0xFF6C5CE7),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tes clients réguliers',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: regularClients.map((client) {
              return _ClientChip(client: client);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ClientChip extends StatelessWidget {
  final ClientContact client;

  const _ClientChip({required this.client});

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(client.phone);
    final timeAgo = _getTimeAgo(client.lastContact);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                '${client.contactCount}× · $timeAgo',
                style: TextStyle(color: UzaColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String phone) {
    if (phone.length >= 2) return phone.substring(phone.length - 2);
    return phone;
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return 'Il y a ${diff.inDays ~/ 7} sem.';
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    return "Récemment";
  }
}

/// Data model for a client who contacted a seller multiple times
class ClientContact {
  final String phone;
  final int contactCount;
  final DateTime lastContact;

  ClientContact({
    required this.phone,
    required this.contactCount,
    required this.lastContact,
  });
}
