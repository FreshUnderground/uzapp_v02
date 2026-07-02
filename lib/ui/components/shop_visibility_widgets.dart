import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import '../../core/models/shop_visibility_models.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/shop_visibility_utils.dart';
import '../../data/local/uza_database.dart';
import 'tap_animator.dart';

/// Active badge on shop cards in directory.
class ShopActiveBadge extends StatelessWidget {
  final Shop shop;

  const ShopActiveBadge({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    if (!isShopActiveToday(shop, DateTime.now())) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF00B894),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tr(context, 'shop_active_badge'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Today stats + local ranking for seller dashboard.
class ShopTodayStatsPanel extends StatelessWidget {
  final ShopVisibilityInsight insight;

  const ShopTodayStatsPanel({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranking = insight.ranking;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr(context, 'today_label'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (insight.isActiveToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tr(context, 'shop_visible_badge'),
                    style: const TextStyle(
                      color: Color(0xFF00B894),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tr(context, 'shop_hidden_badge'),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TodayStatTile(
                  icon: Icons.visibility_outlined,
                  label: tr(context, 'views'),
                  value: insight.today.todayViews,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TodayStatTile(
                  icon: Icons.chat_outlined,
                  label: tr(context, 'whatsapp_label'),
                  value: insight.today.todayWhatsappClicks,
                  color: const Color(0xFF25D366),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TodayStatTile(
                  icon: Icons.inventory_2_outlined,
                  label: tr(context, 'products'),
                  value: insight.today.activeProducts,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          if (ranking.hasComparison) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _rankingLabel(ranking),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _rankingLabel(ShopLocalRanking ranking) {
    final place = ranking.communeLabel != null && ranking.communeLabel!.isNotEmpty
        ? ' à ${ranking.communeLabel}'
        : '';
    final avg = ranking.averageTodayViews > 0
        ? ' — moyenne locale : ${ranking.averageTodayViews} vues/jour'
        : '';
    return '#${ranking.rank} sur ${ranking.totalShops} boutiques$place$avg';
  }
}

class _TodayStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _TodayStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning when visibility dropped due to inactivity.
class ShopVisibilityAlertBanner extends StatelessWidget {
  final ShopVisibilityInsight insight;
  final VoidCallback? onPostNow;

  const ShopVisibilityAlertBanner({
    super.key,
    required this.insight,
    this.onPostNow,
  });

  @override
  Widget build(BuildContext context) {
    if (!insight.showWarning) return const SizedBox.shrink();

    final isCritical = insight.showCriticalAlert;
    final bg = isCritical
        ? Colors.red.withValues(alpha: 0.08)
        : Colors.orange.withValues(alpha: 0.08);
    final border = isCritical ? Colors.red : Colors.orange;
    final icon = isCritical ? Icons.warning_amber_rounded : Icons.info_outline;

    final days = insight.daysSinceActivity;
    final ranking = insight.ranking;

    String message;
    if (insight.rankDropped && ranking.previousRank != null) {
      message =
          'Votre boutique a baissé de visibilité car vous n\'avez pas posté depuis $days jour${days > 1 ? 's' : ''}. '
          'Vous êtes passé de #${ranking.previousRank} à #${ranking.rank}.';
    } else if (isCritical) {
      message =
          'Votre boutique a baissé de visibilité car vous n\'avez pas posté depuis $days jours. '
          'Postez pour réapparaître en tête de l\'annuaire.';
    } else {
      message =
          '0 vue aujourd\'hui. Les boutiques actives reçoivent en moyenne ${ranking.averageTodayViews} vues. '
          'Postez pour rester visible.';
    }

    return TapAnimator(
      onTap: onPostNow,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: border, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (onPostNow != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPostNow,
                  icon: const Icon(Icons.collections_outlined, size: 18),
                  label: Text(tr(context, 'post_whatsapp_status')),
                  style: FilledButton.styleFrom(
                    backgroundColor: border,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
