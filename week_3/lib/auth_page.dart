import 'package:flutter/material.dart';

import 'services/app_preferences.dart';
import 'theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSignup = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode(bool signup) {
    setState(() {
      _isSignup = signup;
      _formKey.currentState?.reset();
      _nameController.clear();
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Institutional email is required.';
    if (!RegExp(
      r'^[^\s@]+@lpunetwork\.edu\.ph$',
      caseSensitive: false,
    ).hasMatch(email)) {
      return 'Use your @lpunetwork.edu.ph email.';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (_isSignup && value.length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isSignup) {
        await widget.preferences.createLocalAccount(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await widget.preferences.authenticateLocalAccount(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = error
          .toString()
          .replaceFirst('StateError: ', '')
          .replaceFirst('FormatException: ', '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _requiredLabel(String label) => RichText(
    text: TextSpan(
      style: Theme.of(context).textTheme.labelLarge,
      children: [
        TextSpan(text: label),
        const TextSpan(
          text: ' *',
          style: TextStyle(color: Color(0xFFD32F2F)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 364),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/img/lpu-logo.png',
                      width: 60,
                      height: 60,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.school_outlined,
                        size: 54,
                        color: AppTokens.maroonPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSignup ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignup
                          ? 'Sign up with your LPU-Cavite student email.'
                          : 'Log in to continue to your student portal.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    if (_isSignup) ...[
                      _requiredLabel('Full name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: _validateName,
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                    _requiredLabel('Institutional email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        hintText: 'name@lpunetwork.edu.ph',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _requiredLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: _isSignup
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: [
                        _isSignup
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (_isSignup) ...[
                      const SizedBox(height: 15),
                      _requiredLabel('Confirm password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm password is required.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Re-enter your password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Local account sign-in',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isSignup ? 'Sign Up' : 'Log In'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _isSignup
                              ? 'Already have an account? '
                              : 'Don’t have an account? ',
                        ),
                        TextButton(
                          onPressed: () => _switchMode(!_isSignup),
                          child: Text(_isSignup ? 'Log in' : 'Sign up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '* Required field',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
