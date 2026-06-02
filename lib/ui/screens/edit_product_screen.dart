import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/local/uza_database.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:typed_data';

import '../components/responsive_layout.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/picker_utils.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../data/services/sync_service.dart';
import 'dart:convert';
import '../components/category_forms/vehicule_form.dart';
import '../components/category_forms/restaurant_form.dart';
import '../components/category_forms/phone_tablet_form.dart';
import '../components/category_forms/informatique_form.dart';
import '../components/category_forms/gadget_form.dart';
import '../components/category_forms/style_form.dart';
import '../../core/utils/category_helper.dart';

class ProductImage {
  final Uint8List? bytes;
  final String? url;
  ProductImage({this.bytes, this.url});
  bool get isEmpty => bytes == null && url == null;
}

class EditProductScreen extends StatefulWidget {
  final int shopId;
  final Product? product;
  const EditProductScreen({super.key, required this.shopId, this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  int? _selectedCategoryId;
  List<Category> _categories = [];
  List<Category> _rootCategories = [];
  List<Category> _subCategories = [];
  int? _selectedRootCategoryId;
  bool _isLoadingCategories = true;
  late TextEditingController _stockController;
  late TextEditingController _promoMsgController;

  // Max 3 images
  final List<ProductImage> _productImages = List.generate(
    3,
    (_) => ProductImage(),
  );
  bool _isUploading = false;
  bool _isSaving = false;

  bool _hidePrice = false;
  bool _showStock = false;
  int _boostStatus = 0;

  // Category-specific form keys
  final GlobalKey<VehiculeFormState> _vehiculeFormKey =
      GlobalKey<VehiculeFormState>();
  final GlobalKey<RestaurantFormState> _restaurantFormKey =
      GlobalKey<RestaurantFormState>();
  final GlobalKey<PhoneTabletFormState> _phoneTabletFormKey =
      GlobalKey<PhoneTabletFormState>();
  final GlobalKey<InformatiqueFormState> _informatiqueFormKey =
      GlobalKey<InformatiqueFormState>();
  final GlobalKey<GadgetFormState> _gadgetFormKey =
      GlobalKey<GadgetFormState>();
  final GlobalKey<StyleFormState> _styleFormKey = GlobalKey<StyleFormState>();

  Map<String, dynamic>? _existingMetadata;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _descController = TextEditingController(text: widget.product?.description);
    _priceController = TextEditingController(
      text: widget.product?.price?.toString() ?? '0.0',
    );
    _selectedCategoryId = widget.product?.categoryId;
    _stockController = TextEditingController(
      text: widget.product?.stockCount?.toString(),
    );
    _promoMsgController = TextEditingController(
      text: widget.product?.promotionMessage,
    );
    _hidePrice = widget.product?.hidePrice ?? false;
    _showStock = widget.product?.showStock ?? false;
    _boostStatus = widget.product?.boostStatus ?? 0;

    // Parse existing metadata for category forms
    if (widget.product?.metadata != null &&
        widget.product!.metadata!.isNotEmpty) {
      try {
        _existingMetadata =
            jsonDecode(widget.product!.metadata!) as Map<String, dynamic>;
      } catch (_) {
        _existingMetadata = null;
      }
    }

    _loadCategories();

    if (widget.product?.imageUrls != null) {
      final urls = ImageUtils.getDecryptedList(widget.product!.imageUrls);
      for (int i = 0; i < urls.length && i < 3; i++) {
        _productImages[i] = ProductImage(url: urls[i]);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _promoMsgController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      // Ensure categories are synced from server before loading
      final syncService = context.read<SyncService>();
      await syncService.ensureCategoriesSynced();

      final repo = context.read<ProductRepository>();
      final cats = await repo.getCategories();
      debugPrint('Loaded ${cats.length} total categories from local DB');

      if (mounted) {
        setState(() {
          _categories = cats;
          // Filter only root categories (level=0)
          _rootCategories = cats.where((c) => c.level == 0).toList();
          debugPrint('Found ${_rootCategories.length} root categories');
          for (var root in _rootCategories) {
            debugPrint('  - Root: ${root.name} (id=${root.id})');
          }

          // If editing existing product, initialize root category and subcategories
          if (widget.product?.categoryId != null) {
            final existingCategory = cats
                .where((c) => c.id == widget.product!.categoryId)
                .firstOrNull;
            if (existingCategory != null) {
              if (existingCategory.level == 0) {
                // Selected category is a root category
                _selectedRootCategoryId = existingCategory.id;
                _selectedCategoryId = existingCategory.id;
                // Load its children
                _subCategories = cats
                    .where((c) => c.parentId == existingCategory.id)
                    .toList();
                debugPrint(
                  'Loaded ${_subCategories.length} subcategories for existing root category',
                );
              } else if (existingCategory.parentId != null) {
                // Selected category is a subcategory
                _selectedRootCategoryId = existingCategory.parentId;
                _selectedCategoryId = existingCategory.id;
                // Load siblings
                _subCategories = cats
                    .where((c) => c.parentId == existingCategory.parentId)
                    .toList();
                debugPrint(
                  'Loaded ${_subCategories.length} sibling subcategories',
                );
              }
            }
          }

          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _onRootCategoryChanged(int? rootCategoryId) {
    debugPrint('Root category changed to: $rootCategoryId');
    setState(() {
      _selectedRootCategoryId = rootCategoryId;
      // Load subcategories for selected root category
      if (rootCategoryId != null) {
        _subCategories = _categories
            .where((c) => c.parentId == rootCategoryId)
            .toList();
        debugPrint(
          'Found ${_subCategories.length} subcategories for root category $rootCategoryId',
        );
        for (var sub in _subCategories) {
          debugPrint('  - Subcategory: ${sub.name} (id=${sub.id})');
        }
        // If no subcategories exist, use root category as the final selection.
        // Otherwise reset so user must pick a subcategory (or keep root via dropdown).
        _selectedCategoryId = _subCategories.isEmpty ? rootCategoryId : null;
      } else {
        _subCategories = [];
        _selectedCategoryId = null;
      }
    });
  }

  void _onSubCategoryChanged(int? subCategoryId) {
    setState(() {
      _selectedCategoryId = subCategoryId;
    });
  }

  Category? get _selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (_) {
      return null;
    }
  }

  /// Get the root category for form type detection
  Category? get _selectedRootCategory {
    if (_selectedRootCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedRootCategoryId);
    } catch (_) {
      return null;
    }
  }

  String? _getFormType(Category? category) {
    // First try to get form type from selected category
    final formType = CategoryHelper.getFormType(category);
    if (formType != 'generic') return formType;

    // If generic, try the root category (parent)
    if (_selectedRootCategory != null) {
      final rootFormType = CategoryHelper.getFormType(_selectedRootCategory);
      if (rootFormType != 'generic') return rootFormType;
    }

    return null;
  }

  bool _isRentalCategory(Category? category) {
    if (category == null) return false;
    final name = category.name.toLowerCase();
    return name.contains('location') ||
        name.contains('rental') ||
        name.contains('louer');
  }

  Widget _buildCategoryForm() {
    final category = _selectedCategory;
    final formType = _getFormType(category);
    final initialData = _existingMetadata;

    switch (formType) {
      case 'vehicule':
        return VehiculeForm(
          key: _vehiculeFormKey,
          initialData: initialData,
          isRental: _isRentalCategory(category),
        );
      case 'restaurant':
        return RestaurantForm(
          key: _restaurantFormKey,
          initialData: initialData,
        );
      case 'phone':
        return PhoneTabletForm(
          key: _phoneTabletFormKey,
          initialData: initialData,
        );
      case 'informatique':
        return InformatiqueForm(
          key: _informatiqueFormKey,
          initialData: initialData,
        );
      case 'gadget':
        return GadgetForm(key: _gadgetFormKey, initialData: initialData);
      case 'style':
        return StyleForm(key: _styleFormKey, initialData: initialData);
      default:
        return const SizedBox.shrink();
    }
  }

  Map<String, dynamic>? _collectCategoryFormData() {
    final effectiveCategoryId = _selectedCategoryId ?? _selectedRootCategoryId;
    Category? effectiveCategory;
    if (effectiveCategoryId != null) {
      try {
        effectiveCategory = _categories.firstWhere(
          (c) => c.id == effectiveCategoryId,
        );
      } catch (_) {}
    }
    final formType = _getFormType(effectiveCategory);

    switch (formType) {
      case 'vehicule':
        return _vehiculeFormKey.currentState?.getData();
      case 'restaurant':
        return _restaurantFormKey.currentState?.getData();
      case 'phone':
        return _phoneTabletFormKey.currentState?.getData();
      case 'informatique':
        return _informatiqueFormKey.currentState?.getData();
      case 'gadget':
        return _gadgetFormKey.currentState?.getData();
      case 'style':
        return _styleFormKey.currentState?.getData();
      default:
        return null;
    }
  }

  bool _validateCategoryForm() {
    // Category form fields are OPTIONAL - not required
    // Users can create products without filling in category-specific details
    return true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateCategoryForm()) return;

    // Soft warning: recommend at least 1 image but don't block
    final hasAnyImage = _productImages.any((img) => !img.isEmpty);
    if (!hasAnyImage && mounted) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[600]),
              SizedBox(width: 8),
              Text('Aucune photo'),
            ],
          ),
          content: Text(
            'Les produits avec photos se vendent beaucoup mieux. Voulez-vous quand même continuer sans photo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Continuer sans photo'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    if (_isSaving) return;
    setState(() {
      _isUploading = true;
      _isSaving = true;
    });

    try {
      final apiService = context.read<ApiService>();
      List<String> finalUrls = [];

      for (int i = 0; i < _productImages.length; i++) {
        final img = _productImages[i];
        if (img.bytes != null) {
          // Upload new image
          final fileName =
              "prod_${DateTime.now().millisecondsSinceEpoch}_$i.png";
          final uploadedUrl = await apiService.uploadFile(
            img.bytes!,
            fileName,
            folder: 'produits',
          );
          if (uploadedUrl != null) finalUrls.add(uploadedUrl);
        } else if (img.url != null) {
          // Keep existing image
          finalUrls.add(img.url!);
        }
      }

      final encryptedImages = CryptoUtils.encrypt(finalUrls.join(','));

      // Use subcategory if selected, otherwise fall back to root category
      final effectiveCategoryId =
          _selectedCategoryId ?? _selectedRootCategoryId;

      final selectedCategory = effectiveCategoryId != null
          ? _categories.firstWhere(
              (c) => c.id == effectiveCategoryId,
              orElse: () => _categories.first,
            )
          : null;

      final categoryFormData = _collectCategoryFormData();
      final metadataJson = categoryFormData != null
          ? jsonEncode(categoryFormData)
          : null;

      final companion = ProductsCompanion(
        id: widget.product != null
            ? drift.Value(widget.product!.id)
            : const drift.Value.absent(),
        remoteId: widget.product != null
            ? drift.Value(widget.product!.remoteId)
            : const drift.Value.absent(),
        shopId: drift.Value(widget.shopId),
        name: drift.Value(_nameController.text),
        description: drift.Value(_descController.text),
        price: drift.Value(double.tryParse(_priceController.text) ?? 0.0),
        imageUrls: drift.Value(encryptedImages),
        categoryId: drift.Value(effectiveCategoryId),
        category: drift.Value(selectedCategory?.name),
        stockCount: drift.Value(int.tryParse(_stockController.text)),
        isArrival: widget.product != null
            ? drift.Value(widget.product!.isArrival)
            : const drift.Value(false),
        isPromotion: widget.product != null
            ? drift.Value(widget.product!.isPromotion)
            : const drift.Value(false),
        hidePrice: drift.Value(_hidePrice),
        showStock: drift.Value(_showStock),
        boostStatus: drift.Value(_boostStatus),
        isBoosted: drift.Value(_boostStatus == 2),
        promotionMessage: drift.Value(_promoMsgController.text),
        updatedAt: drift.Value(DateTime.now()),
        metadata: drift.Value(metadataJson),
      );

      if (!mounted) return;
      final productRepo = context.read<ProductRepository>();
      final syncService = context.read<SyncService>();
      final shopRepo = context.read<ShopRepository>();
      final navigator = Navigator.of(context);

      int productId;
      String action;
      if (widget.product != null) {
        await productRepo.updateProduct(companion);
        productId = widget.product!.id;
        action = 'UPDATE';
      } else {
        productId = await productRepo.addProduct(companion);
        action = 'CREATE';
      }

      // Resolve the shop's server-side (remote) ID so the server can find the shop
      final shop = await shopRepo.getShopById(widget.shopId);
      final remoteShopId =
          (shop?.remoteId != null && shop!.remoteId!.isNotEmpty)
          ? (int.tryParse(shop.remoteId!) ?? widget.shopId)
          : widget.shopId;

      // For UPDATE, use the product's remote ID; for CREATE let the server assign one
      final remoteProductId =
          action == 'UPDATE' && widget.product?.remoteId != null
          ? int.tryParse(widget.product!.remoteId!)
          : null;

      // Queue for background sync
      await syncService.addToQueue(action, 'products', {
        'id': ?remoteProductId,
        'local_id': productId, // kept for local remoteId mapping after push
        'shop_id': remoteShopId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'image_urls': finalUrls.join(','), // Send raw URLs to server
        'category_id': effectiveCategoryId,
        'category': selectedCategory?.name,
        'stock_count': int.tryParse(_stockController.text),
        'is_arrival': widget.product?.isArrival ?? false,
        'is_promotion': widget.product?.isPromotion ?? false,
        'hide_price': _hidePrice,
        'show_stock': _showStock,
        'boost_status': _boostStatus,
        'promotion_message': _promoMsgController.text.trim(),
        'metadata': metadataJson,
      });

      // Trigger immediate push so the product appears on the server
      syncService.forcePush();

      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage(int index) async {
    final bytes = await PickerUtils.pickImage(context);
    if (bytes != null) {
      setState(() {
        _productImages[index] = ProductImage(bytes: bytes);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _productImages[index] = ProductImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null
              ? '➕ Ajouter un Produit'
              : '✏️ Modifier le Produit',
        ),
        actions: [
          if (_isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          // Save button in appbar for quick access
          IconButton(
            icon: Icon(
              Icons.check_circle,
              size: 28,
              color: _isSaving ? Colors.grey : Colors.green,
            ),
            onPressed: _isSaving ? null : _save,
            tooltip: 'Enregistrer le produit',
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildForm(context),
        ),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildForm(context, isDesktop: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {bool isDesktop = false}) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeftFields()),
                const SizedBox(width: 32),
                Expanded(child: _buildRightFields()),
              ],
            )
          else ...[
            _buildLeftFields(),
            const SizedBox(height: 16),
            _buildRightFields(),
          ],
          const SizedBox(height: 32),
          // Large, visible save button for all users
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.check_circle, size: 24),
              label: Text(
                _isSaving ? 'Enregistrement...' : 'Créer le produit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: UzaColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ),
          if (!isDesktop) SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLeftFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du produit *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Prix (USD) *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Root category dropdown
                  DropdownButtonFormField<int>(
                    initialValue: _selectedRootCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Sélectionnez une catégorie'),
                    items: _rootCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: _onRootCategoryChanged,
                    validator: (v) =>
                        v == null ? 'Veuillez choisir une catégorie' : null,
                  ),
                  const SizedBox(height: 16),
                  // Subcategory dropdown (only show if root has children)
                  if (_subCategories.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Sous-catégorie (optionnel)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Sélectionnez une sous-catégorie'),
                      items: [
                        // Option to select the root category itself
                        DropdownMenuItem<int>(
                          value: _selectedRootCategoryId,
                          child: Text(
                            '${_rootCategories.firstWhere(
                              (c) => c.id == _selectedRootCategoryId,
                              orElse: () => Category(id: 0, name: 'Catégorie principale', updatedAt: DateTime.now(), level: 0, sortOrder: 0),
                            ).name} (racine)',
                          ),
                        ),
                        // All subcategories
                        ..._subCategories.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: _onSubCategoryChanged,
                    ),
                ],
              ),
        const SizedBox(height: 16),
        _buildCategoryForm(),
        const SizedBox(height: 16),
        _buildDisplayOptions(),
      ],
    );
  }

  Widget _buildDisplayOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options d\'affichage',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          title: const Text('Masquer le prix'),
          subtitle: const Text('Le prix sera affiché comme "Sur demande"'),
          value: _hidePrice,
          onChanged: (v) => setState(() => _hidePrice = v),
        ),
        SwitchListTile(
          title: const Text('Afficher le stock'),
          subtitle: const Text('Affiche le nombre d\'articles restants'),
          value: _showStock,
          onChanged: (v) => setState(() => _showStock = v),
        ),
        const Divider(),
        _buildStatusInfo(
          'Booster ce produit 🚀',
          _boostStatus,
          isBoostTitle: true,
          onAction: () {
            setState(() => _boostStatus = 1); // Request
          },
        ),
        if (_boostStatus == 2) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _promoMsgController,
            decoration: const InputDecoration(
              labelText: 'Message promotionnel (ex: -20% ce weekend !)',
              border: OutlineInputBorder(),
              hintText: 'Flash sale, Offre limitée, etc.',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusInfo(
    String title,
    int status, {
    bool isBoostTitle = false,
    required VoidCallback onAction,
  }) {
    Color statusColor = Colors.grey;
    String statusText = "Non actif";
    IconData statusIcon = Icons.info_outline;

    if (status == 1) {
      statusColor = Colors.orange;
      statusText = "En attente de validation (Bureau)";
      statusIcon = Icons.hourglass_empty;
    } else if (status == 2) {
      statusColor = Colors.green;
      statusText = "Actif";
      statusIcon = Icons.check_circle_outline;
    } else if (status == 3) {
      statusColor = Colors.red;
      statusText = "Refusé / Expiré";
      statusIcon = Icons.error_outline;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      color: statusColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isBoostTitle ? UzaColors.secondary : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status == 0 || status == 3)
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UzaColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text(
                      'Demander',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (status == 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Rendez-vous au bureau pour le paiement cash afin d'activer cette option.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section header with recommendation
        Row(
          children: [
            const Text(
              'Images du produit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.recommend, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    '1 image min.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ajoutez au moins une photo pour de meilleures ventes (max 3)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                child: _buildImageSlot(index),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _descController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSlot(int index) {
    final img = _productImages[index];

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: index == 0
                ? Colors.orange.withValues(alpha: 0.5)
                : Colors.grey[300]!,
            width: index == 0 ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (img.isEmpty)
              InkWell(
                onTap: () => _pickImage(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      color: index == 0 ? Colors.orange[600] : Colors.grey,
                      size: index == 0 ? 32 : 28,
                    ),
                    const SizedBox(height: 4),
                    if (index == 0)
                      Text(
                        'Recommandé',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[600],
                        ),
                      ),
                  ],
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(
                  child: img.bytes != null
                      ? Image.memory(img.bytes!, fit: BoxFit.cover)
                      : ImageUtils.buildCachedImage(img.url, fit: BoxFit.cover),
                ),
              ),
            if (!img.isEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
