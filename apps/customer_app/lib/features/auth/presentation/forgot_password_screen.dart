import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!Validators.isIdentifier(_identifierController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email or phone number')),
      );
      return;
    }
    final bool sent = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(_identifierController.text.trim());
    if (sent) setState(() => _codeSent = true);
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final bool success = await ref.read(authControllerProvider.notifier).resetPassword(
          identifier: _identifierController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _newPasswordController.text,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset. Please log in again.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _identifierController,
                  label: 'Email or phone',
                  prefixIcon: Icons.alternate_email_rounded,
                  enabled: !_codeSent,
                ),
                const SizedBox(height: 16),
                if (!_codeSent)
                  PrimaryButton(
                    label: 'Send reset code',
                    isLoading: authState.isLoading,
                    onPressed: _requestCode,
                  )
                else ...[
                  AppTextField(
                    controller: _codeController,
                    label: '6-digit code',
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    validator: Validators.otp,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _newPasswordController,
                    label: 'New password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Reset password',
                    isLoading: authState.isLoading,
                    onPressed: _resetPassword,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
