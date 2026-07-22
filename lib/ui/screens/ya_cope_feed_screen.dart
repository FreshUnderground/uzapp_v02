import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../data/models/ya_cope_listing.dart';
import '../../data/repositories/ya_cope_repository.dart';
import '../components/custom_refresh_indicator.dart';
import '../components/skeletons.dart';

class YaCopeFeedScreen extends StatefulWidget {
  const YaCopeFeedScreen({super.key});

  @override
  State<YaCopeFeedScreen> createState() => YaCopeFeedScreenState();
}

class YaCopeFeedScreenState extends State<YaCopeFeedScreen> {
  List<YaCopeListing>? _listings;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refreshListings({bool showLoading = true}) =>
      _load(showLoading: showLoading);

  void prependListing(YaCopeListing listing) {
    setState(() {
      _listings ??= [];
      if (!_listings!.any((l) => l.id == listing.id)) {
        _listings = [listing, ..._listings!];
      }
      _loading = false;
      _error = null;
    });
    _load(showLoading: false);
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = context.read<YaCopeRepository>();
      final items = await repo.fetchListings();
      if (!mounted) return;
      setState(() {
        _listings = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!showLoading) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _openDetail(YaCopeListing listing) {
    context.push('/ya-cope/${listing.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: UzaRefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  tr(context, 'ya_cope'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: UzaColors.primary,
                      ),
                ),
              ),
            ),
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ProductCardSkeleton(),
                    childCount: 6,
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(tr(context, 'retry')),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_listings == null || _listings!.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      tr(context, 'ya_cope_empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: UzaColors.onSurfaceSecondary(context),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = _listings![index];
                      final image = listing.images.isNotEmpty
                          ? listing.images.first
                          : null;
                      return _YaCopeCard(
                        listing: listing,
                        imageUrl: image,
                        onTap: () => _openDetail(listing),
                      );
                    },
                    childCount: _listings!.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _YaCopeCard extends StatelessWidget {
  final YaCopeListing listing;
  final String? imageUrl;
  final VoidCallback onTap;

  const _YaCopeCard({
    required this.listing,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: UzaColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(UzaColors.radiusSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl != null
                  ? ImageUtils.buildCachedImage(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Occasion',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
                  if (listing.daysRemaining != null && listing.daysRemaining! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      trf(context, 'ya_cope_expires_in', {
                        'days': '${listing.daysRemaining}',
                      }),
                      style: TextStyle(
                        fontSize: 11,
                        color: UzaColors.onSurfaceSecondary(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    tr(context, 'price_on_request'),
                    style: TextStyle(
                      color: UzaColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
