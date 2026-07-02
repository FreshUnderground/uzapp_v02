import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/tr.dart';
import '../../core/services/auth_service.dart';
import 'admin/widgets/admin_validation_tab.dart';

/// Legacy route wrapper — redirects to [AdminValidationTab] body.
class AdminValidationScreen extends StatelessWidget {
  const AdminValidationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(tr(context, 'access_denied'))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'admin_validation'))),
      body: const AdminValidationTab(),
    );
  }
}
