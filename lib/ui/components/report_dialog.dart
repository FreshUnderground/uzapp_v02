import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';

/// Predefined report reasons for the DRC marketplace.
const _reportReasons = [
  'Faux produit',
  'Prix incorrect',
  'Photo trompeuse',
  'Arnaque possible',
  'Autre',
];

/// A dialog allowing users to report a product.
///
/// Shows radio-button choices for common report reasons and an optional
/// free-text details field. Calls [onReport] with the selected reason and
/// optional details when the user confirms.
class ReportDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final Function(String reason, String? details) onReport;

  const ReportDialog({
    super.key,
    required this.productId,
    required this.productName,
    required this.onReport,
  });

  /// Convenience method to show this dialog.
  static Future<void> show(
    BuildContext context, {
    required String productId,
    required String productName,
    required Function(String reason, String? details) onReport,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ReportDialog(
        productId: productId,
        productName: productName,
        onReport: onReport,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    setState(() => _submitting = true);

    try {
      widget.onReport(
        _selectedReason!,
        _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
      );

      if (mounted) {
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(tr(context, 'report_sent')),
            backgroundColor: Color(0xFF019C94),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'report_error')),
            backgroundColor: Colors.red,
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

    return AlertDialog(
      title: Text(tr(context, 'report_product')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Text(tr(context, 'report_reason'), style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() => _selectedReason = value);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _reportReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: const Color(0xFF019C94),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Détails (optionnel)',
                labelStyle: theme.textTheme.bodySmall,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(tr(context, 'cancel')),
        ),
        FilledButton(
          onPressed: _selectedReason == null || _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF019C94),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(tr(context, 'send')),
        ),
      ],
    );
  }
}
