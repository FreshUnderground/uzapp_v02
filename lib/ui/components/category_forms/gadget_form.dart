import 'package:flutter/material.dart';
import '../../../core/res/uza_colors.dart';

class GadgetForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const GadgetForm({super.key, this.initialData});

  @override
  State<GadgetForm> createState() => GadgetFormState();
}

class GadgetFormState extends State<GadgetForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _batteryLifeController;
  late final TextEditingController _warrantyController;

  final List<String> _connectivityOptions = [
    'Bluetooth',
    'WiFi',
    'USB-C',
    'NFC',
    'GPS',
  ];
  late List<String> _selectedConnectivity;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _brandController = TextEditingController(
      text: d['brand']?.toString() ?? '',
    );
    _modelController = TextEditingController(
      text: d['model']?.toString() ?? '',
    );
    _batteryLifeController = TextEditingController(
      text: d['battery_life']?.toString() ?? '',
    );
    _warrantyController = TextEditingController(
      text: d['warranty']?.toString() ?? '',
    );

    final initialConn = d['connectivity'];
    if (initialConn is List) {
      _selectedConnectivity = initialConn
          .map((e) => e.toString())
          .where((e) => _connectivityOptions.contains(e))
          .toList();
    } else if (initialConn is String) {
      _selectedConnectivity = initialConn
          .split(',')
          .map((e) => e.trim())
          .where((e) => _connectivityOptions.contains(e))
          .toList();
    } else {
      _selectedConnectivity = [];
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _batteryLifeController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getData() {
    return {
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'battery_life': _batteryLifeController.text.trim(),
      'connectivity': _selectedConnectivity,
      'warranty': _warrantyController.text.trim(),
    };
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du gadget',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildTextField(_brandController, 'Marque *'),
          _buildTextField(_modelController, 'Modele *'),
          _buildTextField(
            _batteryLifeController,
            'Autonomie de la batterie * (ex: 8 heures)',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Connectivite',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _connectivityOptions.map((option) {
              final isSelected = _selectedConnectivity.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedConnectivity.add(option);
                    } else {
                      _selectedConnectivity.remove(option);
                    }
                  });
                },
                selectedColor: UzaColors.primary.withValues(alpha: 0.15),
                checkmarkColor: UzaColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? UzaColors.primary : UzaColors.onSurface(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? UzaColors.primary : Colors.grey[300]!,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildTextField(_warrantyController, 'Garantie * (ex: 1 an)'),
        ],
      ),
    );
  }
}
