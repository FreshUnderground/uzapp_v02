import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/res/uza_colors.dart';

class RestaurantForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const RestaurantForm({super.key, this.initialData});

  @override
  State<RestaurantForm> createState() => RestaurantFormState();
}

class RestaurantFormState extends State<RestaurantForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _menuNameController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _minOrderController;

  String? _cuisineType;
  bool _deliveryAvailable = false;

  final List<String> _cuisineTypes = [
    'Congolaise',
    'Africaine',
    'Fast Food',
    'Internationale',
    'Patisserie',
    'Boissons',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _menuNameController = TextEditingController(
      text: d['menu_name']?.toString() ?? '',
    );
    _prepTimeController = TextEditingController(
      text: d['prep_time']?.toString() ?? '',
    );
    _minOrderController = TextEditingController(
      text: d['min_order']?.toString() ?? '',
    );
    _cuisineType = _cuisineTypes.contains(d['cuisine_type'])
        ? d['cuisine_type'] as String
        : null;
    _deliveryAvailable =
        d['delivery_available'] == true ||
        d['delivery_available'] == 'true' ||
        d['delivery_available'] == 1;
  }

  @override
  void dispose() {
    _menuNameController.dispose();
    _prepTimeController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getData() {
    return {
      'menu_name': _menuNameController.text.trim(),
      'cuisine_type': _cuisineType,
      'prep_time': _prepTimeController.text.trim(),
      'delivery_available': _deliveryAvailable,
      'min_order': double.tryParse(_minOrderController.text.trim()),
    };
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator:
            validator ?? (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        // Optional field - no validator
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du restaurant',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildTextField(_menuNameController, 'Nom du menu *'),
          _buildDropdown(
            'Type de cuisine *',
            _cuisineType,
            _cuisineTypes,
            (v) => setState(() => _cuisineType = v),
          ),
          _buildTextField(
            _prepTimeController,
            'Temps de preparation',
            // Optional field - no validator
          ),
          SwitchListTile(
            title: const Text('Livraison disponible'),
            value: _deliveryAvailable,
            onChanged: (v) => setState(() => _deliveryAvailable = v),
            activeColor: UzaColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            _minOrderController,
            'Montant minimum de commande (\$)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => null,
          ),
        ],
      ),
    );
  }
}
