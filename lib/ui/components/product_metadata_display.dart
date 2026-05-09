import 'package:flutter/material.dart';
import '../../core/res/uza_colors.dart';

/// Widget that displays category-specific product metadata
class ProductMetadataDisplay extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final String categoryType;

  const ProductMetadataDisplay({
    super.key,
    required this.metadata,
    required this.categoryType,
  });

  @override
  Widget build(BuildContext context) {
    switch (categoryType) {
      case 'vehicule':
        return _buildVehiculeMetadata();
      case 'style':
        return _buildStyleMetadata();
      case 'restaurant':
        return _buildRestaurantMetadata();
      case 'phone':
        return _buildPhoneMetadata();
      case 'informatique':
        return _buildInformatiqueMetadata();
      case 'gadget':
        return _buildGadgetMetadata();
      default:
        return _buildGenericMetadata();
    }
  }

  Widget _buildVehiculeMetadata() {
    final items = <_MetadataItem>[];

    if (metadata['make'] != null && metadata['make'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.directions_car,
          label: 'Marque',
          value: metadata['make'].toString(),
        ),
      );
    }

    if (metadata['model'] != null && metadata['model'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.model_training,
          label: 'Modèle',
          value: metadata['model'].toString(),
        ),
      );
    }

    if (metadata['year'] != null && metadata['year'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.calendar_today,
          label: 'Année',
          value: metadata['year'].toString(),
        ),
      );
    }

    if (metadata['mileage'] != null &&
        metadata['mileage'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.speed,
          label: 'Kilométrage',
          value: '${metadata['mileage']} km',
        ),
      );
    }

    if (metadata['fuel_type'] != null &&
        metadata['fuel_type'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.local_gas_station,
          label: 'Carburant',
          value: metadata['fuel_type'].toString(),
        ),
      );
    }

    if (metadata['transmission'] != null &&
        metadata['transmission'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.settings,
          label: 'Transmission',
          value: metadata['transmission'].toString(),
        ),
      );
    }

    if (metadata['color'] != null && metadata['color'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.color_lens,
          label: 'Couleur',
          value: metadata['color'].toString(),
        ),
      );
    }

    if (metadata['seats'] != null && metadata['seats'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.event_seat,
          label: 'Places',
          value: metadata['seats'].toString(),
        ),
      );
    }

    if (metadata['with_driver'] != null) {
      final withDriver =
          metadata['with_driver'] == true ||
          metadata['with_driver'] == 'true' ||
          metadata['with_driver'] == 1;
      items.add(
        _MetadataItem(
          icon: Icons.person,
          label: 'Avec chauffeur',
          value: withDriver ? 'Oui' : 'Non',
        ),
      );
    }

    return _buildMetadataGrid(items);
  }

  Widget _buildStyleMetadata() {
    final items = <_MetadataItem>[];

    if (metadata['gender'] != null &&
        metadata['gender'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.person_outline,
          label: 'Genre',
          value: metadata['gender'].toString(),
        ),
      );
    }

    if (metadata['clothing_type'] != null &&
        metadata['clothing_type'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.checkroom,
          label: 'Type',
          value: metadata['clothing_type'].toString(),
        ),
      );
    }

    if (metadata['size'] != null && metadata['size'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.straighten,
          label: 'Taille',
          value: metadata['size'].toString(),
        ),
      );
    }

    if (metadata['brand'] != null && metadata['brand'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.label_important,
          label: 'Marque',
          value: metadata['brand'].toString(),
        ),
      );
    }

    if (metadata['color'] != null && metadata['color'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.color_lens,
          label: 'Couleur',
          value: metadata['color'].toString(),
        ),
      );
    }

    if (metadata['material'] != null &&
        metadata['material'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.texture,
          label: 'Matière',
          value: metadata['material'].toString(),
        ),
      );
    }

    if (metadata['season'] != null &&
        metadata['season'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.wb_sunny,
          label: 'Saison',
          value: metadata['season'].toString(),
        ),
      );
    }

    return _buildMetadataGrid(items);
  }

  Widget _buildRestaurantMetadata() {
    final items = <_MetadataItem>[];

    if (metadata['menu_name'] != null &&
        metadata['menu_name'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.menu_book,
          label: 'Nom du plat',
          value: metadata['menu_name'].toString(),
        ),
      );
    }

    if (metadata['cuisine_type'] != null &&
        metadata['cuisine_type'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.restaurant,
          label: 'Type de cuisine',
          value: metadata['cuisine_type'].toString(),
        ),
      );
    }

    // Form key: prep_time (legacy: preparation_time)
    final prepTime = metadata['prep_time'] ?? metadata['preparation_time'];
    if (prepTime != null && prepTime.toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.timer,
          label: 'Temps de préparation',
          value: '${prepTime} min',
        ),
      );
    }

    // delivery_available (boolean) replaces legacy service_type
    if (metadata['delivery_available'] != null) {
      final delivery =
          metadata['delivery_available'] == true ||
          metadata['delivery_available'] == 'true' ||
          metadata['delivery_available'] == 1;
      items.add(
        _MetadataItem(
          icon: Icons.delivery_dining,
          label: 'Livraison',
          value: delivery ? 'Disponible' : 'Non disponible',
        ),
      );
    } else if (metadata['service_type'] != null &&
        metadata['service_type'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.room_service,
          label: 'Service',
          value: metadata['service_type'].toString(),
        ),
      );
    }

    if (metadata['min_order'] != null &&
        metadata['min_order'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.attach_money,
          label: 'Commande min.',
          value: '${metadata['min_order']} \$',
        ),
      );
    }

    if (metadata['halal_option'] != null) {
      final halal =
          metadata['halal_option'] == true ||
          metadata['halal_option'] == 'true' ||
          metadata['halal_option'] == 1;
      items.add(
        _MetadataItem(
          icon: Icons.verified,
          label: 'Option Halal',
          value: halal ? 'Oui' : 'Non',
        ),
      );
    }

    return _buildMetadataGrid(items);
  }

  Widget _buildPhoneMetadata() {
    final items = <_MetadataItem>[];

    if (metadata['brand'] != null && metadata['brand'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.phone,
          label: 'Marque',
          value: metadata['brand'].toString(),
        ),
      );
    }

    if (metadata['model'] != null && metadata['model'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.model_training,
          label: 'Modèle',
          value: metadata['model'].toString(),
        ),
      );
    }

    if (metadata['storage'] != null &&
        metadata['storage'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.storage,
          label: 'Stockage',
          value: metadata['storage'].toString(),
        ),
      );
    }

    if (metadata['ram'] != null && metadata['ram'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.memory,
          label: 'RAM',
          value: metadata['ram'].toString(),
        ),
      );
    }

    if (metadata['screen_size'] != null &&
        metadata['screen_size'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.tablet_mac,
          label: 'Écran',
          value: metadata['screen_size'].toString(),
        ),
      );
    }

    if (metadata['battery'] != null &&
        metadata['battery'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.battery_full,
          label: 'Batterie',
          value: '${metadata['battery']} mAh',
        ),
      );
    }

    if (metadata['color'] != null && metadata['color'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.color_lens,
          label: 'Couleur',
          value: metadata['color'].toString(),
        ),
      );
    }

    if (metadata['condition'] != null &&
        metadata['condition'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.info_outline,
          label: 'État',
          value: metadata['condition'].toString(),
        ),
      );
    }

    return _buildMetadataGrid(items);
  }

  Widget _buildInformatiqueMetadata() {
    final items = <_MetadataItem>[];

    if (metadata['type'] != null && metadata['type'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.computer,
          label: 'Type',
          value: metadata['type'].toString(),
        ),
      );
    }

    if (metadata['brand'] != null && metadata['brand'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.branding_watermark,
          label: 'Marque',
          value: metadata['brand'].toString(),
        ),
      );
    }

    if (metadata['model'] != null && metadata['model'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.model_training,
          label: 'Modèle',
          value: metadata['model'].toString(),
        ),
      );
    }

    if (metadata['processor'] != null &&
        metadata['processor'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.memory,
          label: 'Processeur',
          value: metadata['processor'].toString(),
        ),
      );
    }

    if (metadata['ram'] != null && metadata['ram'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.storage,
          label: 'RAM',
          value: metadata['ram'].toString(),
        ),
      );
    }

    if (metadata['storage'] != null &&
        metadata['storage'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.hd,
          label: 'Stockage',
          value: metadata['storage'].toString(),
        ),
      );
    }

    if (metadata['screen_size'] != null &&
        metadata['screen_size'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.display_settings,
          label: 'Écran',
          value: metadata['screen_size'].toString(),
        ),
      );
    }

    if (metadata['os'] != null && metadata['os'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.desktop_windows,
          label: 'Système d\'exploitation',
          value: metadata['os'].toString(),
        ),
      );
    }

    return _buildMetadataGrid(items);
  }

  Widget _buildGadgetMetadata() {
    final items = <_MetadataItem>[];

    if (metadata['type'] != null && metadata['type'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.devices_other,
          label: 'Type',
          value: metadata['type'].toString(),
        ),
      );
    }

    if (metadata['brand'] != null && metadata['brand'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.branding_watermark,
          label: 'Marque',
          value: metadata['brand'].toString(),
        ),
      );
    }

    if (metadata['model'] != null && metadata['model'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.model_training,
          label: 'Modèle',
          value: metadata['model'].toString(),
        ),
      );
    }

    // connectivity is a List of selected options
    final connectivity = metadata['connectivity'];
    if (connectivity != null) {
      String connValue = '';
      if (connectivity is List && connectivity.isNotEmpty) {
        connValue = connectivity.join(', ');
      } else if (connectivity is String && connectivity.isNotEmpty) {
        connValue = connectivity;
      }
      if (connValue.isNotEmpty) {
        items.add(
          _MetadataItem(
            icon: Icons.wifi,
            label: 'Connectivité',
            value: connValue,
          ),
        );
      }
    }

    // Legacy key: features
    if (metadata['features'] != null &&
        metadata['features'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.featured_play_list,
          label: 'Caractéristiques',
          value: metadata['features'].toString(),
        ),
      );
    }

    if (metadata['battery_life'] != null &&
        metadata['battery_life'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.battery_full,
          label: 'Autonomie',
          value: metadata['battery_life'].toString(),
        ),
      );
    }

    if (metadata['warranty'] != null &&
        metadata['warranty'].toString().isNotEmpty) {
      items.add(
        _MetadataItem(
          icon: Icons.verified_outlined,
          label: 'Garantie',
          value: metadata['warranty'].toString(),
        ),
      );
    }

    return _buildMetadataGrid(items);
  }

  /// Fallback: display all non-null metadata fields for unknown category types
  Widget _buildGenericMetadata() {
    final items = <_MetadataItem>[];
    metadata.forEach((key, value) {
      if (value == null) return;
      // Skip empty strings
      if (value is String && value.isEmpty) return;
      // Skip empty lists
      if (value is List && value.isEmpty) return;

      String displayValue;
      if (value is bool) {
        displayValue = value ? 'Oui' : 'Non';
      } else if (value is List) {
        displayValue = value.map((e) => e.toString()).join(', ');
      } else {
        displayValue = value.toString();
        if (displayValue.isEmpty) return;
      }

      final label = key
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
          .join(' ');
      items.add(
        _MetadataItem(
          icon: Icons.info_outline,
          label: label,
          value: displayValue,
        ),
      );
    });
    return _buildMetadataGrid(items);
  }

  Widget _buildMetadataGrid(List<_MetadataItem> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UzaColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UzaColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caractéristiques',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) => _buildMetadataChip(item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(_MetadataItem item) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: UzaColors.primary),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetadataItem {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
