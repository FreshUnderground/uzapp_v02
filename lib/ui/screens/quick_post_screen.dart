import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/res/uza_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_prepare_utils.dart';
import '../../core/utils/picker_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/services/sync_service.dart';
import 'package:drift/drift.dart' as drift;

/// Minimal 3-step product publish: photo → name/price → save.
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
  String? _uploadProgress;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final bytes = await PickerUtils.pickImage(context);
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom du produit requis')),
      );
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une photo')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _uploadProgress = 'Préparation…';
    });

    try {
      final api = context.read<ApiService>();
      final productRepo = context.read<ProductRepository>();
      final syncService = context.read<SyncService>();
      final shopRepo = context.read<ShopRepository>();

      setState(() => _uploadProgress = 'Envoi photo (1/1)…');
      final prepared = await ImagePrepareUtils.prepareForUpload(
        _photo!,
        prefix: 'quick',
      );
      final bytes = await ImagePrepareUtils.ensureUploadSize(prepared.bytes);
      final url = await api.uploadFileOrThrow(
        bytes,
        prepared.fileName,
        folder: 'produits',
        timeout: const Duration(seconds: 45),
      );

      final encrypted = CryptoUtils.encrypt(url);
      final price = double.tryParse(_priceController.text) ?? 0;

      final companion = ProductsCompanion(
        shopId: drift.Value(widget.shopId),
        name: drift.Value(name),
        description: const drift.Value(''),
        price: drift.Value(price),
        imageUrls: drift.Value(encrypted),
        updatedAt: drift.Value(DateTime.now()),
      );

      final productId = await productRepo.addProduct(companion);
      final shop = await shopRepo.getShopById(widget.shopId);
      final remoteShopId = int.tryParse(shop?.remoteId ?? '') ?? widget.shopId;

      await syncService.addToQueue('CREATE', 'products', {
        'local_id': productId,
        'shop_id': remoteShopId,
        'name': name,
        'price': price,
        'image_urls': url,
      });
      await syncService.forcePush();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit publié !')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication rapide'),
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _uploadProgress ?? '…',
                style: const TextStyle(fontSize: 12),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Publier'),
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
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: UzaColors.primary),
                          SizedBox(height: 8),
                          Text('Appuyez pour ajouter une photo'),
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
              labelText: 'Prix (CDF)',
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
            label: Text(_saving ? 'Publication…' : 'Publier maintenant'),
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
