import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
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
import 'dart:async';
import '../components/category_forms/vehicule_form.dart';
import '../components/category_forms/restaurant_form.dart';
import '../components/category_forms/phone_tablet_form.dart';
import '../components/category_forms/informatique_form.dart';
import '../components/category_forms/gadget_form.dart';
import '../components/category_forms/style_form.dart';
import '../components/category_forms/autre_form.dart';
import '../../core/utils/category_helper.dart';
import '../../core/utils/product_promo_utils.dart';
import '../../core/utils/b2b_pricing_utils.dart';
import '../../core/services/product_upload_service.dart';

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
  bool _isPickingImage = false;
  int? _pickingImageIndex;

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
  final GlobalKey<AutreFormState> _autreFormKey = GlobalKey<AutreFormState>();

  int? _selectedCustomCategoryId;
  final TextEditingController _newCustomCategoryController =
      TextEditingController();

  Map<String, dynamic>? _existingMetadata;
  bool _isFlashOffer = false;
  late TextEditingController _promoPriceController;
  DateTime? _promoEndsAt;

  final List<({TextEditingController minQty, TextEditingController unitPrice})>
      _b2bTierRows = [];

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
    _isFlashOffer = widget.product?.isPromotion ?? false;
    _promoPriceController = TextEditingController();
    if (widget.product != null) {
      final promo = ProductPromoUtils.parse(widget.product);
      if (promo.promoPrice != null) {
        _promoPriceController.text = promo.promoPrice!.toString();
      }
      _promoEndsAt = promo.endsAt;
    }

    if (widget.product != null) {
      for (final tier in B2bPricingUtils.parseTiers(widget.product!)) {
        _b2bTierRows.add((
          minQty: TextEditingController(text: tier.minQty.toString()),
          unitPrice: TextEditingController(text: tier.unitPrice.toString()),
        ));
      }
    }

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
    _promoPriceController.dispose();
    _newCustomCategoryController.dispose();
    for (final row in _b2bTierRows) {
      row.minQty.dispose();
      row.unitPrice.dispose();
    }
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
            final productCategoryId = widget.product!.categoryId!;
            final existingCategory = cats
                    .where((c) => c.id == productCategoryId)
                    .firstOrNull ??
                cats
                    .where(
                      (c) =>
                          int.tryParse(c.remoteId ?? '') == productCategoryId,
                    )
                    .firstOrNull;
            if (existingCategory != null) {
              final autreRoot = CategoryHelper.findAutreRoot(cats);
              if (autreRoot != null &&
                  CategoryHelper.isAutreChild(existingCategory, autreRoot)) {
                _selectedRootCategoryId = autreRoot.id;
                _selectedCategoryId = existingCategory.id;
                _selectedCustomCategoryId = existingCategory.id;
                _subCategories = [];
              } else if (existingCategory.level == 0) {
                _selectedRootCategoryId = existingCategory.id;
                _selectedCategoryId = existingCategory.id;
                _subCategories = cats
                    .where((c) => c.parentId == existingCategory.id)
                    .toList();
                debugPrint(
                  'Loaded ${_subCategories.length} subcategories for existing root category',
                );
              } else if (existingCategory.parentId != null) {
                final parent = cats
                    .where((c) => c.id == existingCategory.parentId)
                    .firstOrNull;
                final autreServerId = autreRoot != null
                    ? CategoryHelper.serverIdFor(autreRoot)
                    : null;
                if (parent != null) {
                  _selectedRootCategoryId = parent.id;
                } else if (autreRoot != null &&
                    existingCategory.parentId == autreServerId) {
                  _selectedRootCategoryId = autreRoot.id;
                } else {
                  _selectedRootCategoryId = existingCategory.parentId;
                }
                _selectedCategoryId = existingCategory.id;
                _subCategories = cats
                    .where(
                      (c) =>
                          c.parentId == existingCategory.parentId ||
                          c.parentId == _selectedRootCategoryId,
                    )
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
      _selectedCustomCategoryId = null;
      _newCustomCategoryController.clear();

      if (rootCategoryId != null) {
        final root = _categories
            .where((c) => c.id == rootCategoryId)
            .firstOrNull;
        if (root != null && CategoryHelper.isAutreRoot(root)) {
          _subCategories = [];
          _selectedCategoryId = null;
          return;
        }

        final serverParentId = root != null
            ? CategoryHelper.serverIdFor(root)
            : rootCategoryId;
        _subCategories = _categories
            .where(
              (c) =>
                  c.parentId == rootCategoryId || c.parentId == serverParentId,
            )
            .toList();
        debugPrint(
          'Found ${_subCategories.length} subcategories for root category $rootCategoryId',
        );
        _selectedCategoryId = _subCategories.isEmpty ? rootCategoryId : null;
      } else {
        _subCategories = [];
        _selectedCategoryId = null;
      }
    });
  }

  void _onCustomCategoryChanged(int? customCategoryId) {
    setState(() {
      _selectedCustomCategoryId = customCategoryId;
      if (customCategoryId == CategoryHelper.newCustomCategorySentinel) {
        _selectedCategoryId = null;
        _newCustomCategoryController.clear();
      } else if (customCategoryId != null) {
        _selectedCategoryId = customCategoryId;
        _newCustomCategoryController.clear();
      } else {
        _selectedCategoryId = null;
      }
    });
  }

  Category? get _autreRoot => CategoryHelper.findAutreRoot(_categories);

  bool get _isAutreSelected {
    final root = _selectedRootCategory;
    return root != null && CategoryHelper.isAutreRoot(root);
  }

  List<Category> get _autreCustomCategories {
    final autre = _autreRoot;
    if (autre == null) return [];
    final serverParentId = CategoryHelper.serverIdFor(autre);
    return _categories
        .where(
          (c) => c.parentId == autre.id || c.parentId == serverParentId,
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  int? get _autreRootServerId {
    final autre = _autreRoot;
    if (autre == null) return null;
    return CategoryHelper.serverIdFor(autre);
  }

  String? _resolveCustomCategoryName() {
    if (_selectedCustomCategoryId ==
        CategoryHelper.newCustomCategorySentinel) {
      final name = _newCustomCategoryController.text.trim();
      return name.isEmpty ? null : name;
    }
    if (_selectedCustomCategoryId != null) {
      return _categories
          .where((c) => c.id == _selectedCustomCategoryId)
          .map((c) => c.name)
          .firstOrNull;
    }
    return null;
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
    if (_isAutreSelected) return 'autre';

    final formType = CategoryHelper.getFormType(
      category,
      autreRoot: _autreRoot,
      allCategories: _categories,
    );
    if (formType != 'generic') return formType;

    if (_selectedRootCategory != null) {
      final rootFormType = CategoryHelper.getFormType(
        _selectedRootCategory,
        autreRoot: _autreRoot,
        allCategories: _categories,
      );
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
      case 'autre':
        return AutreForm(key: _autreFormKey, initialData: initialData);
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
      case 'autre':
        return _autreFormKey.currentState?.getData();
      default:
        return null;
    }
  }

  bool _validateCategoryForm() {
    if (_isAutreSelected) {
      final customName = _resolveCustomCategoryName();
      if (customName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'choose_category_required')),
          ),
        );
        return false;
      }
      return _autreFormKey.currentState?.validate() ?? false;
    }
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
              Text(tr(context, 'no_photo')),
            ],
          ),
          content: Text(tr(context, 'no_photo_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(tr(context, 'continue_without_photo')),
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
      final pendingUploads = <({int slot, Uint8List bytes})>[];
      final urlsBySlot = List<String>.filled(_productImages.length, '');

      for (int i = 0; i < _productImages.length; i++) {
        final img = _productImages[i];
        if (img.bytes != null) {
          pendingUploads.add((slot: i, bytes: img.bytes!));
        } else if (img.url != null) {
          final resolved = ImageUtils.resolveImageUrl(img.url);
          if (resolved != null && resolved.isNotEmpty) {
            urlsBySlot[i] = resolved;
          }
        }
      }

      Map<int, String>? pendingPaths;
      if (pendingUploads.isNotEmpty) {
        pendingPaths =
            await ProductUploadService.persistPendingImages(pendingUploads);
      }

      final finalUrls = List<String>.from(urlsBySlot);
      final hasAnyUrl = finalUrls.any((u) => u.isNotEmpty);
      final encryptedImages = !hasAnyUrl
          ? ''
          : CryptoUtils.encrypt(finalUrls.join(','));

      int? effectiveCategoryId =
          _selectedCategoryId ?? _selectedRootCategoryId;
      String? categoryName;

      if (_isAutreSelected) {
        final customName = _resolveCustomCategoryName();
        if (customName == null) {
          throw Exception('Catégorie personnalisée requise');
        }

        final isExistingCustom =
            _selectedCustomCategoryId != null &&
            _selectedCustomCategoryId !=
                CategoryHelper.newCustomCategorySentinel;

        if (isExistingCustom) {
          final existing = _categories
              .where((c) => c.id == _selectedCustomCategoryId)
              .firstOrNull;
          effectiveCategoryId = existing != null
              ? CategoryHelper.serverIdFor(existing)
              : _selectedCustomCategoryId;
          categoryName = existing?.name ?? customName;
        } else {
          final parentServerId = _autreRootServerId;
          if (parentServerId == null) {
            throw Exception('Catégorie Autre introuvable sur le serveur');
          }

          final syncService = context.read<SyncService>();
          final serverCategory = await apiService.findOrCreateCategory(
            name: customName,
            parentServerId: parentServerId,
          );

          if (serverCategory == null) {
            throw Exception(
              'Connexion requise pour créer une catégorie personnalisée',
            );
          }

          await syncService.upsertCategoryFromServer(serverCategory);
          effectiveCategoryId = serverCategory['id'] as int?;
          categoryName = serverCategory['name'] as String? ?? customName;
        }

        if (effectiveCategoryId == null) {
          throw Exception('Impossible de résoudre la catégorie personnalisée');
        }
      } else {
        final selectedCategory = effectiveCategoryId != null
            ? _categories
                .where((c) => c.id == effectiveCategoryId)
                .firstOrNull
            : null;
        categoryName = selectedCategory?.name;
      }

      final categoryFormData = _collectCategoryFormData();
      final withPromo = ProductPromoUtils.mergeFlashIntoMetadata(
        categoryFormData ?? _existingMetadata,
        isFlash: _isFlashOffer,
        promoPrice: double.tryParse(_promoPriceController.text),
        endsAt: _promoEndsAt,
      );
      var mergedMetadata = B2bPricingUtils.mergeTiersIntoMetadata(
        withPromo,
        _collectB2bTiers(),
      );
      if (pendingPaths != null && pendingPaths.isNotEmpty) {
        mergedMetadata = ProductUploadService.mergePendingPaths(
          mergedMetadata,
          pendingPaths,
        );
      }
      final metadataJson =
          mergedMetadata.isNotEmpty ? jsonEncode(mergedMetadata) : null;

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
        category: drift.Value(categoryName),
        stockCount: drift.Value(int.tryParse(_stockController.text)),
        isArrival: widget.product != null
            ? drift.Value(widget.product!.isArrival)
            : const drift.Value(false),
        isPromotion: drift.Value(_isFlashOffer),
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
      final messenger = ScaffoldMessenger.of(context);

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

      // Queue for background sync — skip incomplete image_urls when uploads pending.
      final syncImageUrls = finalUrls.where((u) => u.isNotEmpty).join(',');
      if (pendingUploads.isEmpty) {
        await syncService.addToQueue(action, 'products', {
          'id': ?remoteProductId,
          'local_id': productId,
          'shop_id': remoteShopId,
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'image_urls': syncImageUrls,
          'category_id': effectiveCategoryId,
          'category': categoryName,
          'stock_count': int.tryParse(_stockController.text),
          'is_arrival': widget.product?.isArrival ?? false,
          'is_promotion': _isFlashOffer,
          'hide_price': _hidePrice,
          'show_stock': _showStock,
          'boost_status': _boostStatus,
          'promotion_message': _promoMsgController.text.trim(),
          'metadata': metadataJson,
        });
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.product != null
                ? 'Produit enregistré'
                : 'Produit créé',
          ),
        ),
      );
      navigator.pop();

      if (pendingUploads.isNotEmpty) {
        unawaited(
          _finishPendingUploads(
            productId: productId,
            apiService: apiService,
            productRepo: productRepo,
            shopRepo: shopRepo,
            syncService: syncService,
            messenger: messenger,
          ),
        );
      } else {
        unawaited(syncService.forcePush());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
          ),
        );
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
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
      _pickingImageIndex = index;
    });
    try {
      final bytes = await PickerUtils.pickImage(context);
      if (bytes != null && mounted) {
        setState(() {
          _productImages[index] = ProductImage(bytes: bytes);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
          _pickingImageIndex = null;
        });
      }
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
    final mediaColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageSection(),
        const SizedBox(height: 24),
        _buildNameField(),
        const SizedBox(height: 16),
        _buildDescriptionField(),
      ],
    );

    final detailsColumn = Column(
      children: [
        _buildPriceField(),
        const SizedBox(height: 16),
        _buildCategorySection(),
        const SizedBox(height: 16),
        _buildCategoryForm(),
        const SizedBox(height: 16),
        _buildDisplayOptions(),
      ],
    );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mediaColumn),
                const SizedBox(width: 32),
                Expanded(child: detailsColumn),
              ],
            )
          else ...[
            mediaColumn,
            const SizedBox(height: 16),
            ...detailsColumn.children,
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
                _isSaving
                    ? 'Enregistrement...'
                    : (widget.product != null
                        ? 'Enregistrer'
                        : 'Créer le produit'),
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nom du produit *',
        border: OutlineInputBorder(),
      ),
      validator: (v) => v!.isEmpty ? 'Requis' : null,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Prix (USD) *',
        border: OutlineInputBorder(),
      ),
      validator: (v) => v!.isEmpty ? 'Requis' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descController,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCategorySection() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          hint: Text(tr(context, 'choose_category')),
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
        if (_isAutreSelected) ...[
          DropdownButtonFormField<int>(
            initialValue: _selectedCustomCategoryId,
            decoration: const InputDecoration(
              labelText: 'Votre catégorie *',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            hint: Text(tr(context, 'choose_or_create_category')),
            items: [
              ..._autreCustomCategories.map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                ),
              ),
              DropdownMenuItem(
                value: CategoryHelper.newCustomCategorySentinel,
                child: Text(tr(context, 'new_category')),
              ),
            ],
            onChanged: _onCustomCategoryChanged,
            validator: (v) => v == null &&
                    _newCustomCategoryController.text.trim().isEmpty
                ? 'Veuillez choisir ou créer une catégorie'
                : null,
          ),
          if (_selectedCustomCategoryId ==
              CategoryHelper.newCustomCategorySentinel) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _newCustomCategoryController,
              decoration: const InputDecoration(
                labelText: 'Nom de la nouvelle catégorie *',
                hintText: 'Ex: Matériel agricole',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _selectedCustomCategoryId ==
                      CategoryHelper.newCustomCategorySentinel &&
                  (v == null || v.trim().isEmpty)
                  ? 'Le nom de la catégorie est requis'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ] else if (_subCategories.isNotEmpty)
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
            hint: Text(tr(context, 'choose_subcategory')),
            items: [
              DropdownMenuItem<int>(
                value: _selectedRootCategoryId,
                child: Text(
                  '${_rootCategories.firstWhere(
                    (c) => c.id == _selectedRootCategoryId,
                    orElse: () => Category(id: 0, name: 'Catégorie principale', updatedAt: DateTime.now(), level: 0, sortOrder: 0),
                  ).name} (racine)',
                ),
              ),
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
    );
  }

  Widget _buildDisplayOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'display_options'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          title: Text(tr(context, 'hide_price')),
          subtitle: Text(tr(context, 'price_on_request_hint')),
          value: _hidePrice,
          onChanged: (v) => setState(() => _hidePrice = v),
        ),
        SwitchListTile(
          title: Text(tr(context, 'show_stock')),
          subtitle: Text(tr(context, 'show_stock_subtitle')),
          value: _showStock,
          onChanged: (v) => setState(() => _showStock = v),
        ),
        const Divider(),
        SwitchListTile(
          title: Text(tr(context, 'flash_offer')),
          subtitle: Text(tr(context, 'flash_offer_subtitle')),
          value: _isFlashOffer,
          onChanged: (v) => setState(() => _isFlashOffer = v),
        ),
        if (_isFlashOffer) ...[
          TextFormField(
            controller: _promoPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tr(context, 'promo_price_label'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr(context, 'flash_offer_end')),
            subtitle: Text(
              _promoEndsAt != null
                  ? '${_promoEndsAt!.day}/${_promoEndsAt!.month}/${_promoEndsAt!.year} '
                      '${_promoEndsAt!.hour.toString().padLeft(2, '0')}:'
                      '${_promoEndsAt!.minute.toString().padLeft(2, '0')}'
                  : 'Non définie',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _promoEndsAt ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null || !mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                    _promoEndsAt ?? DateTime.now().add(const Duration(hours: 2)),
                  ),
                );
                if (time == null || !mounted) return;
                setState(() {
                  _promoEndsAt = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              },
            ),
          ),
        ],
        const Divider(),
        _buildB2bPricingSection(),
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

  List<B2bPriceTier> _collectB2bTiers() {
    final tiers = <B2bPriceTier>[];
    for (final row in _b2bTierRows) {
      final minQty = int.tryParse(row.minQty.text.trim());
      final unitPrice = double.tryParse(row.unitPrice.text.trim());
      if (minQty != null && minQty > 1 && unitPrice != null && unitPrice > 0) {
        tiers.add(B2bPriceTier(minQty: minQty, unitPrice: unitPrice));
      }
    }
    tiers.sort((a, b) => a.minQty.compareTo(b.minQty));
    return tiers;
  }

  Widget _buildB2bPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tarifs de gros (B2B)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _b2bTierRows.add((
                    minQty: TextEditingController(text: '10'),
                    unitPrice: TextEditingController(),
                  ));
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr(context, 'tier_label')),
            ),
          ],
        ),
        const Text(
          'Prix unitaire selon la quantité commandée (ex: 10+ pièces).',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (_b2bTierRows.isEmpty)
          Text(
            'Aucun palier — prix catalogue uniquement.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        for (var i = 0; i < _b2bTierRows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _b2bTierRows[i].minQty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qté min.',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _b2bTierRows[i].unitPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire (CDF)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _b2bTierRows[i].minQty.dispose();
                      _b2bTierRows[i].unitPrice.dispose();
                      _b2bTierRows.removeAt(i);
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _finishPendingUploads({
    required int productId,
    required ApiService apiService,
    required ProductRepository productRepo,
    required ShopRepository shopRepo,
    required SyncService syncService,
    ScaffoldMessengerState? messenger,
  }) async {
    final product = await productRepo.getProductById(productId);
    if (product == null) return;
    final failed = await ProductUploadService.processPendingForProduct(
      product: product,
      api: apiService,
      productRepo: productRepo,
      shopRepo: shopRepo,
      syncService: syncService,
    );
    unawaited(syncService.forcePush());
    if (failed > 0) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Une photo n’a pas pu être envoyée. Utilisez Synchroniser.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
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

  Widget _buildImageSection() {
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
                onTap: _isPickingImage ? null : () => _pickImage(index),
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
                      ? Image.memory(
                          img.bytes!,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          cacheWidth: 720,
                        )
                      : ImageUtils.buildCachedImage(img.url, fit: BoxFit.cover),
                ),
              ),
            if (_isPickingImage && _pickingImageIndex == index)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chargement...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
