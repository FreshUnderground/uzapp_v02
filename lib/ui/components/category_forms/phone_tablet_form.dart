import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneTabletForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const PhoneTabletForm({super.key, this.initialData});

  @override
  State<PhoneTabletForm> createState() => PhoneTabletFormState();
}

class PhoneTabletFormState extends State<PhoneTabletForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _modelController;
  late final TextEditingController _screenSizeController;
  late final TextEditingController _batteryController;
  late final TextEditingController _colorController;

  String? _brand;
  String? _storage;
  String? _ram;
  String? _condition;

  final List<String> _brands = [
    'iPhone',
    'Samsung',
    'Tecno',
    'Itel',
    'Infinix',
    'Xiaomi',
    'Oppo',
    'Huawei',
    'Nokia',
    'Motorola',
    'Google Pixel',
    'OnePlus',
    'Realme',
    'Vivo',
    'Docomo',
    'Autre',
  ];

  final List<String> _storages = [
    '16',
    '32',
    '64',
    '128',
    '256',
    '512',
    '1024',
  ];
  final List<String> _rams = ['1', '2', '3', '4', '6', '8', '12', '16'];
  final List<String> _conditions = ['Neuf', 'Occasion', 'Reconditionne'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _modelController = TextEditingController(
      text: d['model']?.toString() ?? '',
    );
    _screenSizeController = TextEditingController(
      text: d['screen_size']?.toString() ?? '',
    );
    _batteryController = TextEditingController(
      text: d['battery']?.toString() ?? '',
    );
    _colorController = TextEditingController(
      text: d['color']?.toString() ?? '',
    );
    _brand = _brands.contains(d['brand']) ? d['brand'] as String : null;
    _storage = _storages.contains(d['storage']?.toString())
        ? d['storage'].toString()
        : null;
    _ram = _rams.contains(d['ram']?.toString()) ? d['ram'].toString() : null;
    _condition = _conditions.contains(d['condition'])
        ? d['condition'] as String
        : null;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _screenSizeController.dispose();
    _batteryController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getData() {
    return {
      'brand': _brand,
      'model': _modelController.text.trim(),
      'storage': _storage != null ? int.tryParse(_storage!) : null,
      'ram': _ram != null ? int.tryParse(_ram!) : null,
      'screen_size': _screenSizeController.text.trim(),
      'battery': int.tryParse(_batteryController.text.trim()),
      'color': _colorController.text.trim(),
      'condition': _condition,
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
            'Informations du telephone / tablette',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Marque *',
            _brand,
            _brands,
            (v) => setState(() => _brand = v),
          ),
          _buildTextField(_modelController, 'Modele *'),
          _buildDropdown(
            'Stockage (GB) *',
            _storage,
            _storages,
            (v) => setState(() => _storage = v),
          ),
          _buildDropdown(
            'RAM (GB) *',
            _ram,
            _rams,
            (v) => setState(() => _ram = v),
          ),
          _buildTextField(_screenSizeController, 'Taille d\'ecran *'),
          _buildTextField(
            _batteryController,
            'Batterie (mAh) *',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _buildTextField(_colorController, 'Couleur *'),
          _buildDropdown(
            'Etat *',
            _condition,
            _conditions,
            (v) => setState(() => _condition = v),
          ),
        ],
      ),
    );
  }
}
