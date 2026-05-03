import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_dimensions.dart';
import 'auth_repository.dart';
import 'auth_text.dart';
import 'auth_validators.dart';
import 'widgets/auth_message.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_shell.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        context.go(RouteConstants.kRouteHome);
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
      title: AuthText.loginTitle,
      subtitle: AuthText.loginSubtitle,
      showBackButton: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              AuthMessage(message: _errorMessage!, isError: true),
              const SizedBox(height: AppDimensions.lg),
            ],
            AuthTextField(
              controller: _emailController,
              label: AuthText.emailLabel,
              hint: AuthText.emailHint,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: AuthValidators.email,
            ),
            const SizedBox(height: AppDimensions.lg),
            AuthTextField(
              controller: _passwordController,
              label: AuthText.passwordLabel,
              hint: AuthText.passwordHint,
              icon: Icons.lock_outline,
              obscureText: true,
              enabled: !_isLoading,
              validator: AuthValidators.password,
              onFieldSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.go(RouteConstants.kRouteForgotPass),
                child: const Text(AuthText.forgotPassword),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            AuthPrimaryButton(
              label: AuthText.loginAction,
              onPressed: _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: AppDimensions.huge),
            const SocialAuthButtons(),
            const SizedBox(height: AppDimensions.huge),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  AuthText.noAccount,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(RouteConstants.kRouteRegister),
                  child: const Text(AuthText.createAccount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
