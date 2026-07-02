import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import 'package:provider/provider.dart';

import '../../core/services/client_reengagement_service.dart';
import '../../data/local/uza_database.dart';

class ClientReengagementScreen extends StatefulWidget {
  final Shop shop;

  const ClientReengagementScreen({super.key, required this.shop});

  @override
  State<ClientReengagementScreen> createState() =>
      _ClientReengagementScreenState();
}

class _ClientReengagementScreenState extends State<ClientReengagementScreen> {
  final _messageController = TextEditingController();
  final _selectedPhones = <String>{};
  List<ReengagementClient> _clients = [];
  bool _loading = true;
  bool _consent = false;
  bool _sending = false;
  int _sendIndex = 0;
  ({bool allowed, int daysRemaining}) _campaignGate = (
    allowed: true,
    daysRemaining: 0,
  );
  ReengagementTemplate _template = ReengagementTemplate.standard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = ClientReengagementService(context.read<UzaDatabase>());
    final clients = await service.getEligibleClients(widget.shop.id);
    final gate = await service.canStartCampaign(widget.shop.id);
    final message = service.buildMessage(shop: widget.shop, template: _template);
    if (!mounted) return;
    _messageController.text = message;
    setState(() {
      _clients = clients;
      _campaignGate = gate;
      _selectedPhones
        ..clear()
        ..addAll(
          clients
              .take(kReengagementMaxContactsPerSession)
              .map((c) => c.phone),
        );
      _loading = false;
    });
  }

  Future<void> _sendBatch() async {
    if (!_consent || _selectedPhones.isEmpty || _sending) return;
    if (!_campaignGate.allowed) return;

    final service = ClientReengagementService(context.read<UzaDatabase>());
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final phones = _selectedPhones.toList();
    setState(() {
      _sending = true;
      _sendIndex = 0;
    });

    for (var i = 0; i < phones.length; i++) {
      if (!mounted) return;
      setState(() => _sendIndex = i + 1);

      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(
            trf(ctx, 'reengage_client_title', {
              'current': '${i + 1}',
              'total': '${phones.length}',
            }),
          ),
          content: Text(
            trf(ctx, 'reengage_client_dialog', {'phone': phones[i]}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(ctx, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(ctx, 'reengage_open_whatsapp')),
            ),
          ],
        ),
      );

      if (ok != true) break;

      final launched = await service.openWhatsAppForClient(
        phone: phones[i],
        message: message,
      );
      if (launched) {
        await service.recordContactSent(widget.shop.id, phones[i]);
      }
    }

    await service.recordCampaignCompleted(widget.shop.id);
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, 'reengage_campaign_done'))),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'reengage_title')),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_campaignGate.allowed)
                  Card(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.timer, color: Colors.orange),
                      title: Text(tr(context, 'reengage_antispam_limit')),
                      subtitle: Text(
                        trf(context, 'reengage_next_campaign_in', {
                          'days': '${_campaignGate.daysRemaining}',
                        }),
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'reengage_message_label'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ClientReengagementService.messageTemplates
                              .map((entry) {
                            final (template, label) = entry;
                            return ChoiceChip(
                              label: Text(
                                label,
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: _template == template,
                              onSelected: (_) {
                                setState(() => _template = template);
                                _messageController.text =
                                    ClientReengagementService(
                                  context.read<UzaDatabase>(),
                                ).buildMessage(
                                  shop: widget.shop,
                                  template: template,
                                );
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: tr(context, 'reengage_message_hint'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trf(context, 'reengage_limits_info', {
                            'max': '$kReengagementMaxContactsPerSession',
                            'days': '$kReengagementMinDaysBetweenCampaigns',
                          }),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _consent,
                  onChanged: (v) => setState(() => _consent = v ?? false),
                  title: Text(tr(context, 'reengage_consent_title')),
                  subtitle: Text(tr(context, 'reengage_consent_subtitle')),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                Text(
                  trf(context, 'reengage_eligible_clients', {
                    'count': '${_clients.length}',
                  }),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_clients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      tr(context, 'reengage_no_clients'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ..._clients.map((client) {
                  final selected = _selectedPhones.contains(client.phone);
                  final canSelect = selected ||
                      _selectedPhones.length <
                          kReengagementMaxContactsPerSession;
                  return CheckboxListTile(
                    value: selected,
                    onChanged: canSelect || selected
                        ? (v) {
                            setState(() {
                              if (v == true) {
                                if (_selectedPhones.length <
                                    kReengagementMaxContactsPerSession) {
                                  _selectedPhones.add(client.phone);
                                }
                              } else {
                                _selectedPhones.remove(client.phone);
                              }
                            });
                          }
                        : null,
                    title: Text('+${client.phone}'),
                    subtitle: Text(
                      '${client.source} · ${trf(context, 'interactions_count', {'count': '${client.contactCount}'})}',
                    ),
                    secondary:
                        const Icon(Icons.chat, color: Color(0xFF25D366)),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _sending ||
                    !_consent ||
                    _selectedPhones.isEmpty ||
                    !_campaignGate.allowed
                ? null
                : _sendBatch,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(
              _sending
                  ? trf(context, 'reengage_send_progress', {
                      'current': '$_sendIndex',
                      'total': '${_selectedPhones.length}',
                    })
                  : trf(context, 'reengage_launch', {
                      'count': '${_selectedPhones.length}',
                    }),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}
