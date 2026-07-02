import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/phone_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/location_data.dart';
import '../../data/services/sync_service.dart';

/// Bottom sheet for clients to request a delivery with location + phone.
class RequestDeliverySheet extends StatefulWidget {
  final Shop shop;
  final Product? product;
  final List<Map<String, dynamic>> items;

  const RequestDeliverySheet({
    super.key,
    required this.shop,
    this.product,
    this.items = const [],
  });

  static Future<bool?> show(
    BuildContext context, {
    required Shop shop,
    Product? product,
    List<Map<String, dynamic>> items = const [],
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RequestDeliverySheet(
        shop: shop,
        product: product,
        items: items,
      ),
    );
  }

  @override
  State<RequestDeliverySheet> createState() => _RequestDeliverySheetState();
}

class _RequestDeliverySheetState extends State<RequestDeliverySheet> {
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  String _locationMode = 'gps';
  String? _selectedCommune;
  double? _latitude;
  double? _longitude;
  bool _loadingGps = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    _phoneController.text = PhoneUtils.formatForDisplay(
      user?.phoneNumber ?? '',
    );
    _selectedCommune = context.read<SettingsService>().userCommune;
    if (_selectedCommune != null && _selectedCommune!.isNotEmpty) {
      _locationMode = 'commune';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() => _loadingGps = true);
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _loadingGps = false;
      if (loc != null) {
        _latitude = loc['latitude'];
        _longitude = loc['longitude'];
        _locationMode = 'gps';
      }
    });
    if (loc == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'delivery_gps_failed'))),
      );
    }
  }

  Future<void> _submit() async {
    final rawPhone = _phoneController.text.trim();
    final normalized = PhoneUtils.normalizeDrc(rawPhone);
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'delivery_phone_required'))),
      );
      return;
    }

    if (_locationMode == 'gps' &&
        (_latitude == null || _longitude == null)) {
      await _captureGps();
      if (!mounted) return;
      if (_latitude == null || _longitude == null) return;
    }

    if (_locationMode == 'manual' &&
        _addressController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'delivery_address_required'))),
      );
      return;
    }

    if (_locationMode == 'commune' &&
        (_selectedCommune == null || _selectedCommune!.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'delivery_commune_required'))),
      );
      return;
    }

    setState(() => _submitting = true);
    final repo = context.read<DeliveryRepository>();
    final sync = context.read<SyncService>();
    final user = context.read<AuthService>().user;

    try {
      final items = widget.items.isNotEmpty
          ? widget.items
          : widget.product != null
              ? [
                  {
                    'product_id': widget.product!.id,
                    'name': widget.product!.name,
                    'quantity': 1,
                  },
                ]
              : <Map<String, dynamic>>[];

      await repo.createDelivery(
        buyerPhone: normalized,
        buyerName: user?.displayName,
        shopId: widget.shop.id,
        productId: widget.product?.id,
        items: items,
        deliveryAddress: _locationMode == 'manual'
            ? _addressController.text.trim()
            : null,
        deliveryCommune: _locationMode == 'commune' ? _selectedCommune : null,
        latitude: _locationMode == 'gps' ? _latitude : null,
        longitude: _locationMode == 'gps' ? _longitude : null,
        locationMode: _locationMode,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        syncService: sync,
      );
      unawaited(sync.forcePush());

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'delivery_request_sent'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trf(context, 'error_with_message', {'message': '$e'})),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final communes = LocationData.cities.values
        .expand((c) => c)
        .toSet()
        .toList()
      ..sort();

    return Container(
      margin: const EdgeInsets.only(top: 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UzaColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: UzaColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'request_delivery'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.shop.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                tr(context, 'delivery_phone_label'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined),
                  hintText: '+243 9XX XXX XXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr(context, 'delivery_location_label'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModeChip(
                    label: tr(context, 'delivery_mode_gps'),
                    icon: Icons.my_location,
                    selected: _locationMode == 'gps',
                    onTap: () async {
                      setState(() => _locationMode = 'gps');
                      if (_latitude == null) await _captureGps();
                    },
                  ),
                  _ModeChip(
                    label: tr(context, 'delivery_mode_address'),
                    icon: Icons.edit_location_alt_outlined,
                    selected: _locationMode == 'manual',
                    onTap: () => setState(() => _locationMode = 'manual'),
                  ),
                  _ModeChip(
                    label: tr(context, 'delivery_mode_commune'),
                    icon: Icons.location_city_outlined,
                    selected: _locationMode == 'commune',
                    onTap: () => setState(() => _locationMode = 'commune'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_locationMode == 'gps') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: UzaColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: UzaColors.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _latitude != null
                            ? Icons.check_circle
                            : Icons.gps_fixed,
                        color: UzaColors.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _latitude != null
                              ? tr(context, 'delivery_gps_captured')
                              : tr(context, 'delivery_gps_hint'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_loadingGps)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        TextButton(
                          onPressed: _captureGps,
                          child: Text(tr(context, 'refresh')),
                        ),
                    ],
                  ),
                ),
              ],
              if (_locationMode == 'manual') ...[
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: tr(context, 'delivery_address_hint'),
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
              ],
              if (_locationMode == 'commune') ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedCommune != null &&
                          communes.contains(_selectedCommune)
                      ? _selectedCommune
                      : null,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.map_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  hint: Text(tr(context, 'select_commune')),
                  items: communes
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCommune = v),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: tr(context, 'delivery_note_hint'),
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: UzaColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        tr(context, 'confirm_delivery_request'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? UzaColors.primary : null,
      ),
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: UzaColors.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
