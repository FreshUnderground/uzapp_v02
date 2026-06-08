import 'package:flutter/material.dart';

class AutreForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AutreForm({super.key, this.initialData});

  @override
  State<AutreForm> createState() => AutreFormState();
}

class AutreFormState extends State<AutreForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _motCleController;
  late final TextEditingController _specificationsController;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _motCleController = TextEditingController(
      text: d['mot_cle']?.toString() ?? '',
    );
    _specificationsController = TextEditingController(
      text: d['specifications']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _motCleController.dispose();
    _specificationsController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getData() {
    return {
      'mot_cle': _motCleController.text.trim(),
      'specifications': _specificationsController.text.trim(),
    };
  }

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
          const Text(
            'Informations de la catégorie',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motCleController,
            decoration: const InputDecoration(
              labelText: 'Mot clé *',
              hintText: 'Ex: tracteur, semence, irrigation',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Le mot clé est requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _specificationsController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Spécifications *',
              hintText: 'Décrivez les caractéristiques principales',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Les spécifications sont requises'
                : null,
          ),
        ],
      ),
    );
  }
}
