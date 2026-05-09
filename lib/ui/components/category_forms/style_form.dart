import 'package:flutter/material.dart';
import '../../../core/res/uza_colors.dart';
import '../../../core/l10n/tr.dart';

class StyleForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const StyleForm({super.key, this.initialData});

  @override
  State<StyleForm> createState() => StyleFormState();
}

class StyleFormState extends State<StyleForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _sizeController;
  late final TextEditingController _colorController;
  late final TextEditingController _materialController;
  late final TextEditingController _clothingTypeController;

  String? _gender;
  String? _season;

  final List<String> _genders = ['man', 'woman', 'child', 'unisex'];
  final List<String> _seasons = [
    'summer',
    'winter',
    'spring',
    'autumn',
    'all_season',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _brandController = TextEditingController(
      text: d['brand']?.toString() ?? '',
    );
    _sizeController = TextEditingController(text: d['size']?.toString() ?? '');
    _colorController = TextEditingController(
      text: d['color']?.toString() ?? '',
    );
    _materialController = TextEditingController(
      text: d['material']?.toString() ?? '',
    );
    _clothingTypeController = TextEditingController(
      text: d['clothing_type']?.toString() ?? '',
    );
    _gender = _genders.contains(d['gender']) ? d['gender'] as String : null;
    _season = _seasons.contains(d['season']) ? d['season'] as String : null;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _clothingTypeController.dispose();
    super.dispose();
  }

  /// Returns the collected form data as a Map
  Map<String, dynamic> getData() {
    return {
      'gender': _gender,
      'size': _sizeController.text.trim(),
      'brand': _brandController.text.trim(),
      'color': _colorController.text.trim(),
      'material': _materialController.text.trim(),
      'clothing_type': _clothingTypeController.text.trim(),
      'season': _season,
    };
  }

  /// Validates the form
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'clothing_details'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Gender dropdown
          _buildDropdown(
            context,
            label: tr(context, 'gender'),
            value: _gender,
            items: _genders,
            onChanged: (value) {
              setState(() {
                _gender = value;
              });
            },
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),

          // Clothing type
          _buildTextField(
            context,
            controller: _clothingTypeController,
            label: tr(context, 'clothing_type'),
            hint: tr(context, 'clothing_type_hint'),
            icon: Icons.checkroom,
          ),
          const SizedBox(height: 12),

          // Size
          _buildTextField(
            context,
            controller: _sizeController,
            label: tr(context, 'size'),
            hint: tr(context, 'size_hint'),
            icon: Icons.straighten,
          ),
          const SizedBox(height: 12),

          // Brand
          _buildTextField(
            context,
            controller: _brandController,
            label: tr(context, 'brand'),
            hint: tr(context, 'brand_hint'),
            icon: Icons.label_important_outline,
          ),
          const SizedBox(height: 12),

          // Color
          _buildTextField(
            context,
            controller: _colorController,
            label: tr(context, 'color'),
            hint: tr(context, 'color_hint'),
            icon: Icons.color_lens_outlined,
          ),
          const SizedBox(height: 12),

          // Material
          _buildTextField(
            context,
            controller: _materialController,
            label: tr(context, 'material'),
            hint: tr(context, 'material_hint'),
            icon: Icons.texture,
          ),
          const SizedBox(height: 12),

          // Season dropdown
          _buildDropdown(
            context,
            label: tr(context, 'season_collection'),
            value: _season,
            items: _seasons,
            onChanged: (value) {
              setState(() {
                _season = value;
              });
            },
            icon: Icons.wb_sunny_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: UzaColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: UzaColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: UzaColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('${tr(context, 'select')} $label'),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(tr(context, item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
