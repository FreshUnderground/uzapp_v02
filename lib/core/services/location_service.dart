import 'package:flutter/material.dart';
import '../l10n/tr.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import '../res/uza_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// Service for handling location-related operations
class LocationService {
  static bool _hasValidCoordinates(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static Future<bool> _safeLaunch(Uri uri, {bool preferExternal = true}) async {
    try {
      if (preferExternal && await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
      if (await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Maps launch failed for $uri: $e');
      return false;
    }
  }

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

  /// Opens GPS/navigation when coordinates exist, otherwise searches by address text.
  static Future<void> openShopLocation({
    required double? latitude,
    required double? longitude,
    String? destinationName,
    String? addressQuery,
  }) async {
    if (latitude != null &&
        longitude != null &&
        _hasValidCoordinates(latitude, longitude)) {
      await getDirections(
        latitude: latitude,
        longitude: longitude,
        destinationName: destinationName,
      );
      return;
    }

    final query = addressQuery?.trim();
    if (query != null && query.isNotEmpty) {
      await openMapsSearch(query);
    }
  }

  /// Open a maps search for a free-text address or place name.
  static Future<void> openMapsSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    if (!kIsWeb && Platform.isAndroid) {
      final geoUri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(trimmed)}');
      if (await _safeLaunch(geoUri)) return;
    }

    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': trimmed,
    });
    if (!await _safeLaunch(uri, preferExternal: !kIsWeb)) {
      debugPrint('Could not launch Maps search for: $trimmed');
    }
  }

  /// Open location in Google Maps (native app or fallback to web)
  static Future<void> openInMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    if (!_hasValidCoordinates(latitude, longitude)) {
      debugPrint('Invalid coordinates for maps: $latitude, $longitude');
      return;
    }

    Uri uri;

    if (kIsWeb) {
      uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query':
            '${label != null ? '${Uri.encodeComponent(label)} ' : ''}$latitude,$longitude',
      });
      await _safeLaunch(uri, preferExternal: false);
      return;
    }

    if (Platform.isAndroid) {
      // Try Google Maps app first
      uri = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude${label != null ? '(${Uri.encodeComponent(label)})' : ''}',
      );
      if (await _safeLaunch(uri)) {
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
      if (await _safeLaunch(uri)) {
        return;
      }
      // Try Google Maps app if installed
      uri = Uri.parse(
        'comgooglemaps://?center=$latitude,$longitude&q=${label != null ? Uri.encodeComponent(label) : ''}',
      );
      if (await _safeLaunch(uri)) {
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

    if (!await _safeLaunch(uri)) {
      debugPrint('Could not launch Maps');
    }
  }

  /// Open location in Waze (falls back to Google Maps directions).
  static Future<void> openInWaze({
    required double latitude,
    required double longitude,
  }) async {
    if (!_hasValidCoordinates(latitude, longitude)) return;

    if (kIsWeb) {
      await getDirections(latitude: latitude, longitude: longitude);
      return;
    }

    final wazeUri = Uri.parse(
      'waze://?ll=$latitude,$longitude&navigate=yes',
    );
    if (await _safeLaunch(wazeUri)) return;

    await getDirections(latitude: latitude, longitude: longitude);
  }

  /// Open directions to location in Google Maps (native app or fallback to web)
  static Future<void> getDirections({
    required double latitude,
    required double longitude,
    String? destinationName,
  }) async {
    if (!_hasValidCoordinates(latitude, longitude)) {
      debugPrint('Invalid coordinates for directions: $latitude, $longitude');
      return;
    }

    Uri uri;

    if (kIsWeb) {
      uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$latitude,$longitude',
      });
      if (!await _safeLaunch(uri, preferExternal: false)) {
        debugPrint('Could not launch Maps Directions (web)');
      }
      return;
    }

    if (Platform.isAndroid) {
      // Try Google Maps navigation first
      uri = Uri.parse(
        'google.navigation:q=$latitude,$longitude',
      );
      if (await _safeLaunch(uri)) {
        return;
      }
      // Fallback to geo URI
      uri = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude${destinationName != null ? '(${Uri.encodeComponent(destinationName)})' : ''}',
      );
      if (await _safeLaunch(uri)) {
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
      if (await _safeLaunch(uri)) {
        return;
      }
      // Try Google Maps app if installed
      uri = Uri.parse(
        'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving',
      );
      if (await _safeLaunch(uri)) {
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

    if (!await _safeLaunch(uri)) {
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
            Icon(Icons.security, color: UzaColors.secondary),
            const SizedBox(width: 8),
            Text(tr(context, 'security_privacy')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(context, 'location_security_body'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, 'location_security_footer'),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'understood')),
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
            title: Row(
              children: [
                Icon(Icons.location_on, color: UzaColors.secondary),
                SizedBox(width: 8),
                Text(tr(context, 'locate_shop')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'location_capture_question'),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr(context, 'location_business_hint'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr(context, 'later')),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.my_location),
                label: Text(tr(context, 'capture')),
                style: ElevatedButton.styleFrom(backgroundColor: UzaColors.secondary),
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
            const CircularProgressIndicator(color: UzaColors.secondary),
            const SizedBox(height: 24),
            Text(
              tr(context, 'location_capturing'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'location_please_wait'),
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
            Text(tr(context, 'position_captured')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(context, 'delivery_gps_captured')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trf(context, 'location_coords', {
                  'lat': latitude.toStringAsFixed(6),
                  'lng': longitude.toStringAsFixed(6),
                }),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'ok')),
          ),
        ],
      ),
    );
  }
}
