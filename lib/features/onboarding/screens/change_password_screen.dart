import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/services/app_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final s = KoolanAppStateScope.of(context).s;
    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.supabaseNotConfigured)));
      setState(() => _isSaving = false);
      return;
    }

    try {
      await client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(KoolanAppStateScope.of(context).s.changePasswordSuccess)));
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    return Scaffold(
      appBar: AppBar(title: Text(s.changePasswordTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.changePasswordLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return s.changePasswordMin;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _updatePassword,
                child: Text(_isSaving ? s.changePasswordSaving : s.changePasswordButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
