import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/phone_utils.dart';
import '../../data/models/ya_cope_listing.dart';

class YaCopeDetailScreen extends StatefulWidget {
  final YaCopeListing listing;

  const YaCopeDetailScreen({super.key, required this.listing});

  @override
  State<YaCopeDetailScreen> createState() => _YaCopeDetailScreenState();
}

class _YaCopeDetailScreenState extends State<YaCopeDetailScreen> {
  late final PageController _pageController;
  var _imageIndex = 0;

  YaCopeListing get listing => widget.listing;
  List<String> get images => listing.images;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _contactMessage() {
    final url = listing.shareUrl;
    return 'Bonjour, je vous contacte depuis UzaApp (Ya Cope).\n'
        'Je suis intéressé(e) par : ${listing.name}\n\n'
        '>> Voir l\'annonce :\n$url\n\n'
        'Est-ce que l\'article est toujours disponible ?';
  }

  Future<void> _contactWhatsApp() async {
    final phone = PhoneUtils.forWhatsApp(listing.phone);
    if (!PhoneUtils.isValidDrc(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro WhatsApp invalide')),
      );
      return;
    }
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(_contactMessage())}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _share() async {
    final text = '${listing.name}\n${listing.shareUrl}\n\n#UzaApp #YaCope #RDC';
    await Share.share(text, subject: listing.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'ya_cope')),
        backgroundColor: UzaColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (i) =>
                                setState(() => _imageIndex = i),
                            itemBuilder: (_, i) => ImageUtils.buildCachedImage(
                              images[i],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              fromResolvedUrl: true,
                            ),
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  images.length,
                                  (i) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _imageIndex == i
                                          ? UzaColors.primary
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Occasion',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(context, 'price_on_request'),
                          style: TextStyle(
                            color: UzaColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (listing.address != null &&
                            listing.address!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.place_outlined,
                                  size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(child: Text(listing.address!.trim())),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (listing.daysRemaining != null &&
                            listing.daysRemaining! > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              trf(context, 'ya_cope_expires_in', {
                                'days': '${listing.daysRemaining}',
                              }),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        Text(
                          tr(context, 'ya_cope_badge'),
                          style: TextStyle(
                            color: const Color(0xFF019C94),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _contactWhatsApp,
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                      label: Text(tr(context, 'contact_seller')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _share,
                      child: const Icon(Icons.share_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
