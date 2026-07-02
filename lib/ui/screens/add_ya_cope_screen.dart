import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/picker_utils.dart';
import '../../data/repositories/ya_cope_repository.dart';

class AddYaCopeScreen extends StatefulWidget {
  const AddYaCopeScreen({super.key});

  @override
  State<AddYaCopeScreen> createState() => _AddYaCopeScreenState();
}

class _AddYaCopeScreenState extends State<AddYaCopeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final List<Uint8List?> _images = [null, null, null];
  var _saving = false;
  int? _pickingIndex;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  int get _photoCount => _images.where((b) => b != null).length;

  Future<void> _pickImage(int index) async {
    setState(() => _pickingIndex = index);
    try {
      final bytes = await PickerUtils.pickImage(context);
      if (bytes != null && mounted) {
        setState(() => _images[index] = bytes);
      }
    } finally {
      if (mounted) setState(() => _pickingIndex = null);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final photos = _images.whereType<Uint8List>().toList();
    if (photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'ya_cope_photo_required'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<YaCopeRepository>().create(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            imageBytes: photos,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'ya_cope_add')),
        backgroundColor: UzaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              tr(context, 'ya_cope_photos_hint'),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              tr(context, 'ya_cope_ttl_hint'),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: InkWell(
                        onTap: _pickingIndex != null
                            ? null
                            : () => _pickImage(i),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _images[i] != null
                                  ? UzaColors.primary
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _pickingIndex == i
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _images[i] != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.memory(
                                            _images[i]!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: IconButton(
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.black54,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.all(4),
                                              minimumSize: const Size(28, 28),
                                            ),
                                            icon: const Icon(Icons.close,
                                                size: 16),
                                            onPressed: () => setState(
                                              () => _images[i] = null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          color: Colors.grey[500],
                                        ),
                                        if (i == 0)
                                          Text(
                                            '*',
                                            style: TextStyle(
                                              color: UzaColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '$_photoCount / 3',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr(context, 'ya_cope_designation'),
                border: const OutlineInputBorder(),
              ),
              maxLength: 150,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: tr(context, 'ya_cope_whatsapp'),
                hintText: '+243 9XX XXX XXX',
                prefixIcon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().length < 9) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: tr(context, 'ya_cope_address'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(tr(context, 'save')),
              style: FilledButton.styleFrom(
                backgroundColor: UzaColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
