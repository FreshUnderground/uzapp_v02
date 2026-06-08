import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/res/uza_colors.dart';
import '../../core/services/contact_service.dart';
import '../../core/services/whatsapp_status_scheduler.dart';
import '../../core/services/whatsapp_status_service.dart';
import '../../data/local/uza_database.dart';
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
  bool _fromDailyBatch = false;
  DateTime? _batchPreparedAt;
  DateTime? _batchNextAt;
  String? _error;
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndPrepare());
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de la préparation.';
        _phase = _StatusPhase.empty;
        _isRegenerating = false;
      });
    }
  }

  Future<void> _regenerate() async {
    if (_isRegenerating || _products.isEmpty) return;
    setState(() => _isRegenerating = true);
    _applyRandomSelection();
    await _prepareCollection();
  }

  Rect? _shareOriginRect() {
    final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareCollection() async {
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
        const SnackBar(content: Text('Partage impossible. Réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statut WhatsApp'),
        backgroundColor: UzaColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_phase == _StatusPhase.result && _products.isNotEmpty)
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
                label: const Text('Réessayer'),
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
                label: const Text('Gérer mes produits'),
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
              Text(
                '${_preparedImages.length} image(s) prête(s)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
              const SizedBox(height: 4),
              Text(
                kIsWeb
                    ? 'Partagez ou téléchargez via votre navigateur.'
                    : 'Partagez via WhatsApp ou une autre app.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isRegenerating || _isSharing ? null : _regenerate,
                child: _isRegenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Regénérer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                key: _shareButtonKey,
                onPressed: _isSharing || _isRegenerating ? null : _shareCollection,
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(kIsWeb ? 'Partager / Télécharger' : 'Partager'),
                style: FilledButton.styleFrom(
                  backgroundColor: UzaColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
