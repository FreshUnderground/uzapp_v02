import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import 'package:provider/provider.dart';

import '../../core/models/product_update_type.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/product_update_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/picker_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import 'edit_product_screen.dart' show ProductImage;

/// Focused flow: update an existing product and publish a public notification.
class UpdateProductScreen extends StatefulWidget {
  final int shopId;
  final Product? product;

  const UpdateProductScreen({
    super.key,
    required this.shopId,
    this.product,
  });

  @override
  State<UpdateProductScreen> createState() => _UpdateProductScreenState();
}

class _UpdateProductScreenState extends State<UpdateProductScreen> {
  Product? _product;
  ProductUpdateType _updateType = ProductUpdateType.arrivage;
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _noteController = TextEditingController();
  bool _showStock = false;
  bool _markAvailable = false;
  bool _isSaving = false;
  bool _isPicking = false;

  final List<ProductImage> _images = List.generate(3, (_) => ProductImage());

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    if (_product != null) _initFromProduct(_product!);
  }

  void _initFromProduct(Product product) {
    _priceController.text = product.price?.toString() ?? '';
    _stockController.text = product.stockCount?.toString() ?? '';
    _showStock = product.showStock;
    _markAvailable = product.isSold;

    final urls = _decodeUrls(product.imageUrls);
    for (var i = 0; i < urls.length && i < 3; i++) {
      _images[i] = ProductImage(url: urls[i]);
    }
  }

  List<String> _decodeUrls(String encrypted) {
    if (encrypted.isEmpty) return [];
    try {
      final decoded = CryptoUtils.decrypt(encrypted);
      return decoded.split(',').where((u) => u.trim().isNotEmpty).toList();
    } catch (_) {
      return encrypted.split(',').where((u) => u.trim().isNotEmpty).toList();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final products = await context
        .read<ProductRepository>()
        .watchProductsByShop(widget.shopId)
        .first;
    if (!mounted) return;

    final picked = await showModalBottomSheet<Product>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(tr(context, 'no_product_to_update')),
          );
        }
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (_, i) {
            final p = products[i];
            return ListTile(
              leading: SizedBox(
                width: 48,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ImageUtils.buildCachedFirstProductImage(
                    p.imageUrls,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(p.name),
              subtitle: Text(p.isSold ? 'Vendu' : 'En vente'),
              onTap: () => Navigator.pop(ctx, p),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _product = picked;
        _initFromProduct(picked);
      });
    }
  }

  Future<void> _pickImage(int index) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final bytes = await PickerUtils.pickImage(context);
      if (bytes != null && mounted) {
        setState(() {
          _images[index] = ProductImage(bytes: bytes);
          if (_updateType != ProductUpdateType.photos) {
            _updateType = ProductUpdateType.photos;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _publish() async {
    final product = _product;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'select_product'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final shopRepo = context.read<ShopRepository>();
      final updateService = context.read<ProductUpdateService>();
      final shop = await shopRepo.getShopById(widget.shopId);
      if (shop == null) throw Exception('Boutique introuvable');

      final newImages = <({int slot, Uint8List bytes})>[];
      final existingBySlot = <int, String>{};
      for (var i = 0; i < _images.length; i++) {
        final img = _images[i];
        if (img.bytes != null) {
          newImages.add((slot: i, bytes: img.bytes!));
        } else if (img.url != null) {
          final resolved = ImageUtils.resolveImageUrl(img.url);
          if (resolved != null && resolved.isNotEmpty) {
            existingBySlot[i] = resolved;
          }
        }
      }

      final input = PublishProductUpdateInput(
        product: product,
        shop: shop,
        updateType: _updateType,
        note: _noteController.text.trim().isEmpty
            ? _updateType.label
            : _noteController.text.trim(),
        price: double.tryParse(_priceController.text),
        stockCount: int.tryParse(_stockController.text),
        showStock: _showStock,
        markAvailable: _markAvailable && product.isSold,
        setArrival: _updateType == ProductUpdateType.arrivage,
        newImages: newImages.isEmpty ? null : newImages,
        existingImageUrlsBySlot:
            existingBySlot.isEmpty ? null : existingBySlot,
      );

      await updateService.publishUpdate(input);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔔 Mise à jour publiée — ${product.name}',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'update_product')),
        backgroundColor: UzaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: UzaColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: UzaColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'Pas besoin de republier un nouveau produit. Mettez à jour celui-ci — '
              'chaque mise à jour envoie une notification publique à vos clients.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
          const SizedBox(height: 20),
          if (_product == null)
            FilledButton.icon(
              onPressed: _pickProduct,
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(tr(context, 'choose_product')),
            )
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 56,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ImageUtils.buildCachedFirstProductImage(
                    _product!.imageUrls,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                _product!.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(_product!.isSold ? 'Vendu' : 'En vente'),
              trailing: TextButton(
                onPressed: _pickProduct,
                child: Text(tr(context, 'change')),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type de mise à jour',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductUpdateType.values.map((type) {
                final selected = _updateType == type;
                return FilterChip(
                  label: Text('${type.emoji} ${type.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _updateType = type),
                  selectedColor: UzaColors.primary.withValues(alpha: 0.15),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note publique (optionnel)',
                hintText: 'Ex: Nouvel arrivage, stock limité…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Prix 💰',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Stock 📦',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(context, 'show_stock')),
              value: _showStock,
              onChanged: (v) => setState(() => _showStock = v),
            ),
            if (_product!.isSold)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr(context, 'resell_product')),
                value: _markAvailable,
                onChanged: (v) => setState(() {
                  _markAvailable = v;
                  if (v) _updateType = ProductUpdateType.restock;
                }),
              ),
            const SizedBox(height: 8),
            Text(
              'Photos 📸',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(3, (i) {
                final img = _images[i];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: InkWell(
                        onTap: _isPicking ? null : () => _pickImage(i),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: img.isEmpty
                              ? const Icon(Icons.add_a_photo_outlined)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: img.bytes != null
                                      ? Image.memory(
                                          img.bytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : ImageUtils.buildCachedImage(
                                          ImageUtils.resolveImageUrl(img.url) ?? '',
                                          fit: BoxFit.cover,
                                        ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _product == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _publish,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.campaign_outlined),
                  label: Text(tr(context, 'publish_update')),
                  style: FilledButton.styleFrom(
                    backgroundColor: UzaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
    );
  }
}
