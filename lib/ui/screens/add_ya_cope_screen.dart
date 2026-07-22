import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/phone_utils.dart';
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
  String? _progress;
  int? _pickingIndex;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  int get _photoCount => _images.where((b) => b != null).length;

  String _friendlyError(Object e) =>
      e.toString().replaceAll('Exception: ', '').trim();

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

    final phone = PhoneUtils.normalizeDrc(_phoneController.text);
    if (!PhoneUtils.isValidDrc(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Numéro WhatsApp invalide. Ex. 099XXXXXXX ou +2439XXXXXXXX',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _progress = 'Envoi des photos…';
    });
    try {
      final listing = await context.read<YaCopeRepository>().create(
            name: _nameController.text.trim(),
            phone: phone,
            address: _addressController.text.trim(),
            imageBytes: photos,
            onProgress: (msg) {
              if (mounted) setState(() => _progress = msg);
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'ya_cope_published'))),
      );
      Navigator.pop(context, listing);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
      setState(() {
        _saving = false;
        _progress = null;
      });
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
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _images[i] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _images[i]!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_pickingIndex == i)
                                      const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: UzaColors.primary,
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      i == 0 ? '*' : '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                if (!PhoneUtils.isValidDrc(v)) {
                  return 'Numéro WhatsApp invalide';
                }
                return null;
              },
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
              label: Text(_progress ?? tr(context, 'save')),
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
