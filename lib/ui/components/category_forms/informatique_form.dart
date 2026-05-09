import 'package:flutter/material.dart';

class InformatiqueForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const InformatiqueForm({super.key, this.initialData});

  @override
  State<InformatiqueForm> createState() => InformatiqueFormState();
}

class InformatiqueFormState extends State<InformatiqueForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _modelController;
  late final TextEditingController _processorController;
  late final TextEditingController _storageController;
  late final TextEditingController _screenSizeController;

  String? _brand;
  String? _ram;
  String? _os;

  final List<String> _brands = [
    'HP',
    'Dell',
    'Lenovo',
    'Asus',
    'Acer',
    'Apple',
    'MSI',
    'Toshiba',
    'Autre',
  ];

  final List<String> _rams = ['2', '4', '8', '16', '32', '64'];
  final List<String> _oses = ['Windows', 'macOS', 'Linux', 'ChromeOS', 'Autre'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _modelController = TextEditingController(
      text: d['model']?.toString() ?? '',
    );
    _processorController = TextEditingController(
      text: d['processor']?.toString() ?? '',
    );
    _storageController = TextEditingController(
      text: d['storage']?.toString() ?? '',
    );
    _screenSizeController = TextEditingController(
      text: d['screen_size']?.toString() ?? '',
    );
    _brand = _brands.contains(d['brand']) ? d['brand'] as String : null;
    _ram = _rams.contains(d['ram']?.toString()) ? d['ram'].toString() : null;
    _os = _oses.contains(d['os']) ? d['os'] as String : null;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _processorController.dispose();
    _storageController.dispose();
    _screenSizeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getData() {
    return {
      'brand': _brand,
      'model': _modelController.text.trim(),
      'processor': _processorController.text.trim(),
      'ram': _ram != null ? int.tryParse(_ram!) : null,
      'storage': _storageController.text.trim(),
      'screen_size': _screenSizeController.text.trim(),
      'os': _os,
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
            'Informations informatique',
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
          _buildTextField(_processorController, 'Processeur *'),
          _buildDropdown(
            'RAM (GB) *',
            _ram,
            _rams,
            (v) => setState(() => _ram = v),
          ),
          _buildTextField(_storageController, 'Stockage * (ex: 256GB SSD)'),
          _buildTextField(_screenSizeController, 'Taille d\'ecran *'),
          _buildDropdown(
            'Systeme d\'exploitation *',
            _os,
            _oses,
            (v) => setState(() => _os = v),
          ),
        ],
      ),
    );
  }
}
