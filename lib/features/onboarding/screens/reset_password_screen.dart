import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/services/app_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final s = KoolanAppStateScope.of(context).s;
    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.supabaseNotConfigured)));
      setState(() => _isSending = false);
      return;
    }

    try {
      await client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: AppSupabaseConfig.redirectUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(KoolanAppStateScope.of(context).s.resetPasswordEmailSent)),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    return Scaffold(
      appBar: AppBar(title: Text(s.resetPasswordTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: s.authEmail,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.resetPasswordEmailHint;
                  if (!v.contains('@')) return s.authEmailInvalid;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSending ? null : _sendReset,
                child: Text(_isSending ? s.resetPasswordSending : s.resetPasswordButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
