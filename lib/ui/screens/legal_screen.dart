import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';

enum LegalDocumentType { terms, privacy }

class LegalScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isTerms = type == LegalDocumentType.terms;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, isTerms ? 'terms' : 'privacy')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr(context, isTerms ? 'terms_title' : 'privacy_title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, isTerms ? 'terms_body' : 'privacy_body'),
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }
}
