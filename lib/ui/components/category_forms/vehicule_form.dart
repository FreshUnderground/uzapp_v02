import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/res/uza_colors.dart';

class VehiculeForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isRental;

  const VehiculeForm({super.key, this.initialData, this.isRental = false});

  @override
  State<VehiculeForm> createState() => VehiculeFormState();
}

class VehiculeFormState extends State<VehiculeForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _mileageController;
  late final TextEditingController _colorController;
  late final TextEditingController _seatsController;
  late final TextEditingController _rentalPriceController;

  String? _fuelType;
  String? _transmission;
  bool _withDriver = false;

  final List<String> _fuelTypes = [
    'Essence',
    'Diesel',
    'Electrique',
    'Hybride',
  ];
  final List<String> _transmissions = ['Manuelle', 'Automatique'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _makeController = TextEditingController(text: d['make']?.toString() ?? '');
    _modelController = TextEditingController(
      text: d['model']?.toString() ?? '',
    );
    _yearController = TextEditingController(text: d['year']?.toString() ?? '');
    _mileageController = TextEditingController(
      text: d['mileage']?.toString() ?? '',
    );
    _colorController = TextEditingController(
      text: d['color']?.toString() ?? '',
    );
    _seatsController = TextEditingController(
      text: d['seats']?.toString() ?? '',
    );
    _rentalPriceController = TextEditingController(
      text: d['rental_price']?.toString() ?? '',
    );
    _fuelType = _fuelTypes.contains(d['fuel_type'])
        ? d['fuel_type'] as String
        : null;
    _transmission = _transmissions.contains(d['transmission'])
        ? d['transmission'] as String
        : null;
    _withDriver =
        d['with_driver'] == true ||
        d['with_driver'] == 'true' ||
        d['with_driver'] == 1;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _colorController.dispose();
    _seatsController.dispose();
    _rentalPriceController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getData() {
    return {
      'make': _makeController.text.trim(),
      'model': _modelController.text.trim(),
      'year': int.tryParse(_yearController.text.trim()),
      'mileage': int.tryParse(_mileageController.text.trim()),
      'fuel_type': _fuelType,
      'transmission': _transmission,
      'color': _colorController.text.trim(),
      'seats': int.tryParse(_seatsController.text.trim()),
      if (widget.isRental) ...{
        'rental_price': double.tryParse(_rentalPriceController.text.trim()),
        'with_driver': _withDriver,
      },
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
        initialValue: value,
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
            'Informations du vehicule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildTextField(_makeController, 'Marque *'),
          _buildTextField(_modelController, 'Modele *'),
          _buildTextField(
            _yearController,
            'Annee *',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _buildTextField(
            _mileageController,
            'Kilometrage (km) *',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _buildDropdown(
            'Type de carburant *',
            _fuelType,
            _fuelTypes,
            (v) => setState(() => _fuelType = v),
          ),
          _buildDropdown(
            'Transmission *',
            _transmission,
            _transmissions,
            (v) => setState(() => _transmission = v),
          ),
          _buildTextField(_colorController, 'Couleur *'),
          _buildTextField(
            _seatsController,
            'Nombre de places *',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          if (widget.isRental) ...[
            _buildTextField(
              _rentalPriceController,
              'Prix de location / jour (\$) *',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            CheckboxListTile(
              title: const Text('Avec chauffeur'),
              value: _withDriver,
              onChanged: (v) => setState(() => _withDriver = v ?? false),
              activeColor: UzaColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
