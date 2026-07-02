import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import 'package:flutter/services.dart';

import '../../core/res/uza_colors.dart';

/// Bottom-sheet layout: scrollable preview on top, action buttons always visible.
class SharePreviewLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Widget? image;
  final String message;
  final String messageLabel;
  final Color messageAccent;
  final List<Widget> actions;
  final double imageAspectRatio;

  const SharePreviewLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.image,
    required this.message,
    this.messageLabel = 'Aperçu du message',
    this.messageAccent = UzaColors.primary,
    required this.actions,
    this.imageAspectRatio = 4 / 3,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: imageAspectRatio,
                            child: image,
                          ),
                        )
                      else if (imageUrl != null)
                        const SizedBox.shrink(),
                      if (image != null || imageUrl != null)
                        const SizedBox(height: 12),
                      _MessagePreviewBox(
                        message: message,
                        label: messageLabel,
                        accent: messageAccent,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagePreviewBox extends StatefulWidget {
  final String message;
  final String label;
  final Color accent;

  const _MessagePreviewBox({
    required this.message,
    required this.label,
    required this.accent,
  });

  @override
  State<_MessagePreviewBox> createState() => _MessagePreviewBoxState();
}

class _MessagePreviewBoxState extends State<_MessagePreviewBox> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(context, 'message_copied'))),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(tr(context, 'copy')),
                style: TextButton.styleFrom(
                  foregroundColor: widget.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              widget.message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            secondChild: Text(
              widget.message,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          if (widget.message.length > 160)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: widget.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_expanded ? 'Réduire' : 'Voir tout le message'),
              ),
            ),
        ],
      ),
    );
  }
}
