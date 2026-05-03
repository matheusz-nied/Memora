import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input.dart';
import 'auth_repository.dart';
import 'auth_text.dart';
import 'auth_validators.dart';
import 'widgets/auth_message.dart';
import 'widgets/auth_shell.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _wasSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _wasSent = false;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(_emailController.text);
      if (mounted) {
        setState(() {
          _wasSent = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = readableAuthError(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: AuthText.forgotTitle,
      subtitle: AuthText.forgotSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              AuthMessage(message: _errorMessage!, isError: true),
              const SizedBox(height: AppDimensions.lg),
            ],
            if (_wasSent) ...[
              const AuthMessage(message: AuthText.resetSent, isError: false),
              const SizedBox(height: AppDimensions.lg),
            ],
            AppInput(
              controller: _emailController,
              label: AuthText.emailLabel,
              hint: AuthText.emailHint,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              validator: AuthValidators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppDimensions.xxl),
            AppButton(
              label: AuthText.sendReset,
              onPressed: _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: AppDimensions.lg),
            AppButton(
              label: AuthText.signIn,
              onPressed: _isLoading
                  ? null
                  : () => context.go(RouteConstants.kRouteLogin),
              variant: AppButtonVariant.text,
            ),
          ],
        ),
      ),
    );
  }
}
