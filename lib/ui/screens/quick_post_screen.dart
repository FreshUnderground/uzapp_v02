import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import 'package:provider/provider.dart';

import '../../core/res/uza_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/product_upload_service.dart';
import '../../core/utils/picker_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';
import 'package:drift/drift.dart' as drift;

/// Minimal product publish: photo → name/price → local-first save.
class QuickPostScreen extends StatefulWidget {
  final int shopId;

  const QuickPostScreen({super.key, required this.shopId});

  @override
  State<QuickPostScreen> createState() => _QuickPostScreenState();
}

class _QuickPostScreenState extends State<QuickPostScreen> {
  Uint8List? _photo;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) =>
      e.toString().replaceAll('Exception: ', '').trim();

  Future<void> _pickPhoto() async {
    final bytes = await PickerUtils.pickImage(context);
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'product_name_required'))),
      );
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'add_photo_required'))),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final api = context.read<ApiService>();
      final productRepo = context.read<ProductRepository>();
      final syncService = context.read<SyncService>();
      final shopRepo = context.read<ShopRepository>();
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      final price = double.tryParse(_priceController.text) ?? 0;
      final pendingPaths = await ProductUploadService.persistPendingImages([
        (slot: 0, bytes: _photo!),
      ]);
      final metadata = ProductUploadService.mergePendingPaths({}, pendingPaths);

      final companion = ProductsCompanion(
        shopId: drift.Value(widget.shopId),
        name: drift.Value(name),
        description: const drift.Value(''),
        price: drift.Value(price),
        imageUrls: const drift.Value(''),
        metadata: drift.Value(jsonEncode(metadata)),
        updatedAt: drift.Value(DateTime.now()),
      );

      final productId = await productRepo.addProduct(companion);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(tr(context, 'product_published'))),
        );
        navigator.pop(true);
      }

      unawaited(() async {
        try {
          final product = await productRepo.getProductById(productId);
          if (product == null) return;
          final failed = await ProductUploadService.processPendingForProduct(
            product: product,
            api: api,
            productRepo: productRepo,
            shopRepo: shopRepo,
            syncService: syncService,
          );
          unawaited(syncService.forcePush());
          if (failed > 0) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Une photo n’a pas pu être envoyée. Utilisez Synchroniser.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Publication en attente de synchronisation. ${_friendlyError(e)}',
              ),
            ),
          );
        }
      }());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'quick_publish')),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(tr(context, 'publish')),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _saving ? null : _pickPhoto,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _photo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: UzaColors.primary),
                          SizedBox(height: 8),
                          Text(tr(context, 'tap_add_photo')),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_photo!, fit: BoxFit.cover),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du produit',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Prix (USD)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish),
            label: Text(_saving ? 'Enregistrement…' : 'Publier maintenant'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: UzaColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
