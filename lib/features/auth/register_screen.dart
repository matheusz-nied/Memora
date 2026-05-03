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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _nameController.text,
          );
      if (!mounted) {
        return;
      }

      if (session == null) {
        setState(() {
          _successMessage = AuthText.checkEmail;
        });
      } else {
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

  String? _confirmPassword(String? value) {
    final passwordError = AuthValidators.password(value);
    if (passwordError != null) {
      return passwordError;
    }

    if (value != _passwordController.text) {
      return AuthText.passwordMismatch;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: AuthText.registerTitle,
      subtitle: AuthText.registerSubtitle,
      showBackButton: false,
      centerHeader: true,
      constrainForm: true,
      footer: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.xl),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              AuthText.alreadyHasAccount,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => context.go(RouteConstants.kRouteLogin),
              child: const Text(AuthText.signIn),
            ),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              AuthMessage(message: _errorMessage!, isError: true),
              const SizedBox(height: AppDimensions.lg),
            ],
            if (_successMessage != null) ...[
              AuthMessage(message: _successMessage!, isError: false),
              const SizedBox(height: AppDimensions.lg),
            ],
            AuthTextField(
              controller: _nameController,
              label: AuthText.nameLabel,
              hint: AuthText.nameHint,
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: AuthValidators.required,
            ),
            const SizedBox(height: AppDimensions.lg),
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
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: AuthValidators.password,
            ),
            const SizedBox(height: AppDimensions.lg),
            AuthTextField(
              controller: _confirmPasswordController,
              label: AuthText.confirmPasswordLabel,
              hint: AuthText.passwordHint,
              icon: Icons.verified_user_outlined,
              obscureText: true,
              enabled: !_isLoading,
              validator: _confirmPassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppDimensions.xxl),
            AuthPrimaryButton(
              label: AuthText.registerAction,
              icon: Icons.arrow_forward,
              onPressed: _submit,
              isLoading: _isLoading,
            ),
            if (_successMessage != null) ...[
              const SizedBox(height: AppDimensions.md),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.go(RouteConstants.kRouteLogin),
                child: const Text(AuthText.goToLogin),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
