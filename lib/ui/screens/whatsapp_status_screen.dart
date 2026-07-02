import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../core/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/res/platform_brands.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/contact_service.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/services/system_push_notifier.dart';
import '../../core/services/web_notification_service.dart';
import '../../core/services/whatsapp_status_scheduler.dart';
import '../../core/services/whatsapp_status_service.dart';
import '../../core/utils/status_image_composer.dart';
import '../../core/utils/status_template_prefs.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../components/marketing_share_sheet.dart';
import '../components/uza_secondary_app_bar.dart';
import '../utils/page_transitions.dart';
import 'manage_products_screen.dart';

enum _StatusPhase { loading, preparing, result, empty }

class WhatsAppStatusScreen extends StatefulWidget {
  final Shop shop;

  const WhatsAppStatusScreen({super.key, required this.shop});

  @override
  State<WhatsAppStatusScreen> createState() => _WhatsAppStatusScreenState();
}

class _WhatsAppStatusScreenState extends State<WhatsAppStatusScreen> {
  _StatusPhase _phase = _StatusPhase.loading;
  List<Product> _products = [];
  final Set<int> _selectedIds = {};
  List<Uint8List> _preparedImages = [];
  int _prepareCurrent = 0;
  int _prepareTotal = 0;
  int _randomCount = 0;
  bool _isSharing = false;
  bool _isRegenerating = false;
  bool _isTikTokGenerating = false;
  bool _fromDailyBatch = false;
  DateTime? _batchPreparedAt;
  DateTime? _batchNextAt;
  String? _error;
  StatusVisualTemplate _template = StatusVisualTemplate.classic;
  bool _showTemplateOptions = false;
  bool _customSchedule = false;
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 18, minute: 0);
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrefs());
    unawaited(_ensureNotificationPermission());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndPrepare());
  }

  Future<void> _loadPrefs() async {
    final template = await StatusTemplatePrefs.loadTemplate();
    final schedule = await StatusTemplatePrefs.loadSchedule();
    if (!mounted) return;
    setState(() {
      _template = template;
      _customSchedule = schedule.enabled;
      _scheduleTime = TimeOfDay(hour: schedule.hour, minute: schedule.minute);
    });
  }

  Future<void> _ensureNotificationPermission() async {
    if (kIsWeb) {
      await WebNotificationService.requestPermission();
      return;
    }
    final granted = await PushNotificationService.ensureNotificationsEnabled();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Activez les notifications pour être alerté quand la vidéo est prête.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Autoriser',
            onPressed: () {
              unawaited(PushNotificationService.ensureNotificationsEnabled());
            },
          ),
        ),
      );
    }
  }

  Future<void> _loadAndPrepare() async {
    setState(() {
      _phase = _StatusPhase.loading;
      _error = null;
      _fromDailyBatch = false;
    });

    try {
      final scheduler = WhatsAppStatusScheduler(
        context.read<UzaDatabase>(),
        context.read<WhatsAppStatusService>(),
      );
      await scheduler.registerShop(widget.shop.id);

      final cached = await scheduler.loadPreparedBatch(widget.shop.id);
      if (!mounted) return;

      if (cached != null && cached.images.isNotEmpty) {
        setState(() {
          _preparedImages = cached.images;
          _randomCount = cached.images.length;
          _fromDailyBatch = true;
          _batchPreparedAt = cached.preparedAt;
          _batchNextAt = cached.nextAt;
          _phase = _StatusPhase.result;
        });
        return;
      }

      final service = context.read<WhatsAppStatusService>();
      final products = await service.getEligibleProducts(widget.shop.id);
      if (!mounted) return;

      if (products.isEmpty) {
        setState(() => _phase = _StatusPhase.empty);
        return;
      }

      _products = products;
      _applyRandomSelection(service);
      await _prepareCollection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de préparer la collection.';
        _phase = _StatusPhase.empty;
      });
    }
  }

  void _applyRandomSelection([WhatsAppStatusService? service]) {
    final statusService = service ?? context.read<WhatsAppStatusService>();
    _randomCount = statusService.pickRandomTargetCount(_products.length);
    _selectedIds
      ..clear()
      ..addAll(
        statusService.pickRandomProductIds(
          _products,
          count: _randomCount,
        ),
      );
  }

  List<Product> get _selectedProducts =>
      _products.where((p) => _selectedIds.contains(p.id)).toList();

  Future<void> _prepareCollection() async {
    final selected = _selectedProducts;
    if (selected.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Aucun produit sélectionné.';
        _phase = _StatusPhase.empty;
      });
      return;
    }

    setState(() {
      _phase = _StatusPhase.preparing;
      _prepareCurrent = 0;
      _prepareTotal = selected.length;
      _preparedImages = [];
      _error = null;
    });

    try {
      final service = context.read<WhatsAppStatusService>();
      final images = await service.prepareCollection(
        shop: widget.shop,
        products: selected,
        template: _template,
        onProgress: (current, total) {
          if (!mounted) return;
          setState(() {
            _prepareCurrent = current;
            _prepareTotal = total;
          });
        },
      );

      if (!mounted) return;

      if (images.isEmpty) {
        setState(() {
          _error = 'Aucune image n\'a pu être préparée.';
          _phase = _StatusPhase.empty;
        });
        return;
      }

      setState(() {
        _preparedImages = images;
        _phase = _StatusPhase.result;
        _isRegenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${images.length} image(s) prête(s) — notification envoyée',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      unawaited(
        SystemPushNotifier.notifyStatusGenerationComplete(
          shopId: widget.shop.id,
          shopName: widget.shop.name,
          imageCount: images.length,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de la préparation.';
        _phase = _StatusPhase.empty;
        _isRegenerating = false;
      });
    }
  }

  Future<void> _ensureProductsLoaded() async {
    if (_products.isNotEmpty) return;
    final service = context.read<WhatsAppStatusService>();
    final products = await service.getEligibleProducts(widget.shop.id);
    if (!mounted) return;
    _products = products;
  }

  Future<void> _regenerate() async {
    if (_isRegenerating) return;

    setState(() {
      _isRegenerating = true;
      _fromDailyBatch = false;
      _preparedImages = [];
      _error = null;
    });

    try {
      await _ensureProductsLoaded();
      if (!mounted) return;

      if (_products.isEmpty) {
        setState(() {
          _error = 'Aucun produit avec photo disponible.';
          _phase = _StatusPhase.empty;
          _isRegenerating = false;
        });
        return;
      }

      _applyRandomSelection();
      await _prepareCollection();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de régénérer les images.';
        _phase = _StatusPhase.empty;
        _isRegenerating = false;
      });
    }
  }

  Rect? _shareOriginRect() {
    final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareToFacebook() async {
    if (_preparedImages.isEmpty || _isSharing) return;

    await MarketingShareSheet.showStatusCollection(
      context,
      shop: widget.shop,
      imageCount: _preparedImages.length,
      shareLabel: 'Partager sur Facebook',
      onShare: _executeShareToFacebook,
    );
  }

  Future<void> _executeShareToFacebook() async {
    if (_preparedImages.isEmpty || _isSharing) return;
    setState(() => _isSharing = true);
    try {
      final statusService = context.read<WhatsAppStatusService>();
      final contactService = context.read<ContactService>();
      final (xfiles, tempPaths) = await statusService.toShareableFiles(
        widget.shop.id,
        _preparedImages,
      );
      if (!mounted) return;
      await contactService.shareStatusToFacebook(
        shop: widget.shop,
        images: xfiles,
        tempPaths: tempPaths.isEmpty ? null : tempPaths,
        sharePositionOrigin: _shareOriginRect(),
        rawImagesForWebFallback: _preparedImages,
      );
      if (!mounted) return;
      unawaited(
        context.read<ShopRepository>().recordShopActivity(widget.shop.id),
      );
      if (mounted && kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'share_images_hint')),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'share_facebook_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareToTikTok() async {
    if (_preparedImages.isEmpty || _isTikTokGenerating) return;

    await MarketingShareSheet.showStatusCollection(
      context,
      shop: widget.shop,
      imageCount: _preparedImages.length,
      shareLabel: 'Créer et partager sur TikTok',
      onShare: _executeShareToTikTok,
    );
  }

  Future<void> _executeShareToTikTok() async {
    if (_preparedImages.isEmpty || _isTikTokGenerating) return;

    setState(() => _isTikTokGenerating = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎬 Vidéo TikTok en préparation en arrière-plan…',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }

    final shop = widget.shop;
    final images = List<Uint8List>.from(_preparedImages);
    final contactService = context.read<ContactService>();
    final shareOrigin = _shareOriginRect();

    unawaited(_generateTikTokInBackground(
      shop: shop,
      images: images,
      contactService: contactService,
      shareOrigin: shareOrigin,
    ));
  }

  Future<void> _generateTikTokInBackground({
    required Shop shop,
    required List<Uint8List> images,
    required ContactService contactService,
    Rect? shareOrigin,
  }) async {
    try {
      // Let the snackbar paint before heavy encode work starts.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final export = await contactService.buildTikTokStatusExport(
        shop: shop,
        images: images,
      );

      final notified = await SystemPushNotifier.notifyTikTokVideoReady(
        shopId: shop.id,
        shopName: shop.name,
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            notified
                ? 'Vidéo TikTok prête — notification envoyée'
                : 'Vidéo TikTok prête',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Partager',
            onPressed: () {
              unawaited(
                contactService.shareTikTokStatusExport(
                  shop: shop,
                  export: export,
                  fallbackImages: images,
                  sharePositionOrigin: shareOrigin,
                ),
              );
            },
          ),
        ),
      );

      if (!notified) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Notifications désactivées — autorisez-les dans les réglages du téléphone.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Autoriser',
              onPressed: () {
                unawaited(PushNotificationService.ensureNotificationsEnabled());
              },
            ),
          ),
        );
      }

      if (kIsWeb && export == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Sur le web, partagez les images (MP4 disponible sur mobile).',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'tiktok_video_failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTikTokGenerating = false);
    }
  }

  Future<void> _shareCollection() async {
    if (_preparedImages.isEmpty || _isSharing) return;

    await MarketingShareSheet.showStatusCollection(
      context,
      shop: widget.shop,
      imageCount: _preparedImages.length,
      shareLabel: 'Publier / partager',
      onShare: _executeShareCollection,
    );
  }

  Future<void> _executeShareCollection() async {
    if (_preparedImages.isEmpty || _isSharing) return;

    setState(() => _isSharing = true);

    try {
      final statusService = context.read<WhatsAppStatusService>();
      final contactService = context.read<ContactService>();
      final (xfiles, tempPaths) = await statusService.toShareableFiles(
        widget.shop.id,
        _preparedImages,
      );

      if (!mounted) return;
      await contactService.shareStatusCollection(
        shop: widget.shop,
        images: xfiles,
        tempPaths: tempPaths.isEmpty ? null : tempPaths,
        sharePositionOrigin: _shareOriginRect(),
        rawImagesForWebFallback: _preparedImages,
      );

      if (!mounted) return;
      unawaited(
        context.read<ShopRepository>().recordShopActivity(widget.shop.id),
      );
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Images téléchargées ou partagées selon votre navigateur.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'share_failed_retry'))),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UzaBackScope(
      child: Scaffold(
      appBar: UzaSecondaryAppBar(
        title: tr(context, 'whatsapp_status'),
        backgroundColor: UzaColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_phase == _StatusPhase.result &&
              (_products.isNotEmpty || _preparedImages.isNotEmpty))
            IconButton(
              tooltip: 'Nouvelle sélection aléatoire',
              onPressed: _isRegenerating ? null : _regenerate,
              icon: _isRegenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shuffle),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _StatusPhase.loading:
        return _buildLoadingView();
      case _StatusPhase.empty:
        return _buildEmptyState();
      case _StatusPhase.preparing:
        return _buildPreparingView();
      case _StatusPhase.result:
        return _buildResultView();
    }
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: UzaColors.primary),
          const SizedBox(height: 20),
          Text(
            'Préparation automatique…',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélection aléatoire des photos produits',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Aucun produit avec photo disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            if (_products.isNotEmpty)
              FilledButton.icon(
                onPressed: _loadAndPrepare,
                icon: const Icon(Icons.refresh),
                label: Text(tr(context, 'retry')),
              ),
            if (_products.isEmpty) ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  SlideUpRoute(
                    page: ManageProductsScreen(shopId: widget.shop.id),
                  ),
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(tr(context, 'manage_my_products')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreparingView() {
    final progress = _prepareTotal == 0
        ? 0.0
        : _prepareCurrent / _prepareTotal;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 8,
                color: UzaColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Préparation $_prepareCurrent/$_prepareTotal…',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '$_randomCount photo(s) choisie(s) au hasard',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: _showTemplateOptions ? 2 : 1,
                    child: Text(
                      '${_preparedImages.length} image(s) prête(s)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_showTemplateOptions)
                    Expanded(
                      flex: 3,
                      child: _buildTemplateSelector(compact: true),
                    )
                  else
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Style visuel',
                      icon: Icon(
                        Icons.palette_outlined,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                      onPressed: () =>
                          setState(() => _showTemplateOptions = true),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _fromDailyBatch
                    ? 'Collection quotidienne automatique · $_randomCount image(s)'
                    : 'Collection générée automatiquement · $_randomCount produit(s) au hasard',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              if (_fromDailyBatch && _batchPreparedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _batchNextAt != null
                      ? 'Préparé ${_formatRelative(_batchPreparedAt!)} · prochain dans ${_formatRelative(_batchNextAt!, future: true)}'
                      : 'Préparé ${_formatRelative(_batchPreparedAt!)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              _buildScheduleSelector(),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 9 / 16,
            ),
            itemCount: _preparedImages.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _preparedImages[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector({bool compact = false}) {
    const labels = {
      StatusVisualTemplate.classic: 'Classique',
      StatusVisualTemplate.minimal: 'Minimal',
      StatusVisualTemplate.promo: 'Promo',
      StatusVisualTemplate.flash: 'Flash',
    };
    final chips = StatusVisualTemplate.values.map((t) {
      final selected = _template == t;
      return Padding(
        padding: EdgeInsets.only(right: compact ? 6 : 8),
        child: ChoiceChip(
          label: Text(
            labels[t]!,
            style: TextStyle(fontSize: compact ? 11 : 13),
          ),
          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 4)
              : null,
          materialTapTargetSize: compact
              ? MaterialTapTargetSize.shrinkWrap
              : MaterialTapTargetSize.padded,
          selected: selected,
          onSelected: (v) async {
            if (!v) return;
            setState(() => _template = t);
            await StatusTemplatePrefs.saveTemplate(t);
          },
        ),
      );
    }).toList();

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildScheduleSelector() {
    return Row(
      children: [
        Switch(
          value: _customSchedule,
          onChanged: (v) async {
            setState(() => _customSchedule = v);
            await StatusTemplatePrefs.saveSchedule(
              enabled: v,
              hour: _scheduleTime.hour,
              minute: _scheduleTime.minute,
            );
          },
        ),
        Expanded(
          child: Text(
            _customSchedule
                ? 'Planifié à ${_scheduleTime.hour.toString().padLeft(2, '0')}:${_scheduleTime.minute.toString().padLeft(2, '0')}'
                : 'Préparation auto toutes les 24h30',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
        if (_customSchedule)
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _scheduleTime,
              );
              if (picked == null) return;
              setState(() => _scheduleTime = picked);
              await StatusTemplatePrefs.saveSchedule(
                enabled: true,
                hour: picked.hour,
                minute: picked.minute,
              );
            },
            child: Text(tr(context, 'change')),
          ),
      ],
    );
  }

  String _formatRelative(DateTime time, {bool future = false}) {
    final diff = future ? time.difference(DateTime.now()) : DateTime.now().difference(time);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (future) {
      if (hours >= 24) return '${hours ~/ 24}j ${hours % 24}h';
      if (hours > 0) return '${hours}h ${minutes}min';
      return '${diff.inMinutes}min';
    }
    if (hours > 0) return 'il y a ${hours}h';
    if (minutes > 0) return 'il y a ${minutes}min';
    return 'à l\'instant';
  }

  Widget? _buildBottomBar() {
    if (_phase != _StatusPhase.result) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: _SharePlatformButton(
                label: 'Regénérer',
                icon: Icons.shuffle_rounded,
                color: UzaColors.primary,
                onPressed: _isRegenerating ? null : _regenerate,
                iconOnly: true,
                loading: _isRegenerating,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SharePlatformButton(
                key: _shareButtonKey,
                label: 'WhatsApp',
                icon: PlatformBrands.whatsAppIcon,
                color: PlatformBrands.whatsApp,
                onPressed: _isSharing ? null : _shareCollection,
                iconOnly: true,
                loading: _isSharing,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SharePlatformButton(
                label: 'Facebook',
                icon: PlatformBrands.facebookIcon,
                color: PlatformBrands.facebook,
                onPressed: _isSharing ? null : _shareToFacebook,
                iconOnly: true,
                loading: _isSharing,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SharePlatformButton(
                label: 'TikTok',
                icon: PlatformBrands.tikTokIcon,
                color: PlatformBrands.tikTok,
                onPressed: _isTikTokGenerating ? null : _shareToTikTok,
                iconOnly: true,
                loading: _isTikTokGenerating,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharePlatformButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool iconOnly;
  final bool loading;

  const _SharePlatformButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.iconOnly = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    const barHeight = 52.0;

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: barHeight,
          padding: iconOnly
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: iconOnly
              ? Center(child: _buildContent())
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildContent(),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    if (PlatformBrands.isFontAwesomeBrand(icon)) {
      return FaIcon(icon, color: color, size: iconOnly ? 22 : 20);
    }
    return Icon(icon, color: color, size: iconOnly ? 22 : 20);
  }
}
