import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// Service for handling location-related operations
class LocationService {
  /// Request and capture current location
  static Future<Map<String, double>?> getCurrentLocation({
    bool highAccuracy = true,
  }) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: highAccuracy
              ? LocationAccuracy.high
              : LocationAccuracy.medium,
        ),
      );

      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Open location in Google Maps (native app or fallback to web)
  static Future<void> openInMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    Uri uri;

    if (Platform.isAndroid) {
      // Try Google Maps app first
      uri = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude${label != null ? '(${Uri.encodeComponent(label)})' : ''}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback to web URL
      uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query':
            '${label != null ? '${Uri.encodeComponent(label)} ' : ''}$latitude,$longitude',
      });
    } else if (Platform.isIOS) {
      // Try Apple Maps first (native)
      uri = Uri.parse(
        'http://maps.apple.com/?ll=$latitude,$longitude&q=${label != null ? Uri.encodeComponent(label) : ''}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Try Google Maps app if installed
      uri = Uri.parse(
        'comgooglemaps://?center=$latitude,$longitude&q=${label != null ? Uri.encodeComponent(label) : ''}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback to web URL
      uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query':
            '${label != null ? '${Uri.encodeComponent(label)} ' : ''}$latitude,$longitude',
      });
    } else {
      // Web/other platforms
      uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query':
            '${label != null ? '${Uri.encodeComponent(label)} ' : ''}$latitude,$longitude',
      });
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch Maps');
    }
  }

  /// Open directions to location in Google Maps (native app or fallback to web)
  static Future<void> getDirections({
    required double latitude,
    required double longitude,
    String? destinationName,
  }) async {
    Uri uri;

    if (Platform.isAndroid) {
      // Try Google Maps navigation first
      uri = Uri.parse(
        'google.navigation:q=$latitude,$longitude${destinationName != null ? '&daddr=${Uri.encodeComponent(destinationName)}' : ''}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback to geo URI
      uri = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude${destinationName != null ? '(${Uri.encodeComponent(destinationName)})' : ''}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback to web URL
      uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$latitude,$longitude',
      });
    } else if (Platform.isIOS) {
      // Try Apple Maps directions first (native)
      uri = Uri.parse(
        'http://maps.apple.com/?daddr=$latitude,$longitude&saddr=&dirflg=d',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Try Google Maps app if installed
      uri = Uri.parse(
        'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback to web URL
      uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$latitude,$longitude',
      });
    } else {
      // Web/other platforms
      uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$latitude,$longitude',
      });
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch Maps Directions');
    }
  }

  /// Show location permission dialog with security notice
  static void showSecurityNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.teal[700]),
            const SizedBox(width: 8),
            const Text('Sécurité & Confidentialité'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour des raisons de sécurité, nous vous recommandons de prendre la localisation de votre entreprise et non de votre domicile.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Cette localisation sera visible par les clients potentiels pour les aider à trouver votre boutique.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to confirm location capture
  static Future<bool> showCaptureLocationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal),
                SizedBox(width: 8),
                Text('Localiser la boutique'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voulez-vous capturer votre position actuelle pour aider les clients à trouver votre boutique?',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Utilisez la localisation de votre entreprise, pas votre domicile.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Plus tard'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.my_location),
                label: const Text('Capturer'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show loading dialog while capturing location
  static void showLocationLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.teal),
            const SizedBox(height: 24),
            const Text(
              'Capturer la position...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez patienter quelques secondes',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Show success message after location capture
  static void showLocationSuccess(
    BuildContext context, {
    required double latitude,
    required double longitude,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Position capturée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La localisation de votre boutique a été enregistrée avec succès.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lat: ${latitude.toStringAsFixed(6)}\nLng: ${longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
