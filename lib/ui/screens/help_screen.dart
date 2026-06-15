import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/services/contact_service.dart';
import 'package:provider/provider.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSupportCard(
            context,
            'Contactez-nous',
            'Besoin d\'aide ? Notre équipe est disponible sur WhatsApp.',
            FontAwesomeIcons.whatsapp,
            Colors.green,
            () {
              context.read<ContactService>().launchWhatsApp(
                phone: '+243975955375',
                entityType: 'support',
                entityId: 0,
                name: 'Support Uzaapp',
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Questions Fréquentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqItem('Comment créer une boutique ?', 'Allez sur votre profil et cliquez sur "Ouvrir ma boutique". Suivez ensuite les étapes du formulaire.'),
          _buildFaqItem('Comment booster un produit ?', 'Le boost est réservé aux comptes professionnels. Contactez le support pour plus d\'infos.'),
          _buildFaqItem('Est-ce que l\'application est gratuite ?', 'Oui, la création d\'un compte et la publication de produits standards sont gratuites.'),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Version 2.0.4 (Build 5)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(desc, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Démarrer la discussion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(color: Colors.grey[700], height: 1.5)),
        ),
      ],
    );
  }
}
