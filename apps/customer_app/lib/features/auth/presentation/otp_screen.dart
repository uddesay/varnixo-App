import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_controller.dart';

/// OTP verification for the passwordless login flow. Unknown identifiers
/// are auto-registered by the backend on successful verification.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({required this.identifier, required this.purpose, super.key});

  final String identifier;
  final String purpose;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _secondsRemaining = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.length != 6) return;
    final bool success = await ref.read(authControllerProvider.notifier).verifyOtp(
          identifier: widget.identifier,
          code: _codeController.text,
        );
    if (success && mounted) context.go(RoutePaths.home);
  }

  Future<void> _resend() async {
    final bool sent =
        await ref.read(authControllerProvider.notifier).requestOtp(widget.identifier);
    if (sent) _startResendTimer();
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
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter verification code', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to ${widget.identifier}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _codeController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 52,
                  fieldWidth: 44,
                  activeColor: Theme.of(context).colorScheme.primary,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Theme.of(context).colorScheme.outline,
                ),
                onChanged: (_) {},
                onCompleted: (_) => _verify(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Verify & continue',
                isLoading: authState.isLoading,
                onPressed: _verify,
              ),
              const SizedBox(height: 16),
              Center(
                child: _secondsRemaining > 0
                    ? Text('Resend code in $_secondsRemaining s')
                    : TextButton(onPressed: _resend, child: const Text('Resend code')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
