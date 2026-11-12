import 'package:flutter/material.dart';

import 'home_page.dart';
import 'services/app_preferences.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final ThemeData _authTheme = AppTokens.buildTheme(Brightness.light);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final TextEditingController _idController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSignup = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rememberMe = widget.preferences.rememberMe;
    _idController = TextEditingController(text: widget.preferences.savedUserId);
    _passwordController.text = widget.preferences.savedPassword;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode(bool signup) {
    setState(() {
      _isSignup = signup;
      _formKey.currentState?.reset();
      // Keep credentials in their own fields when the form changes mode.
      // Refill the login password only when returning to the login form.
      _passwordController.text = signup
          ? ''
          : (_rememberMe ? widget.preferences.savedPassword : '');
      _confirmController.clear();
      if (!signup && widget.preferences.rememberMe &&
          (_idController.text.isEmpty ||
              _idController.text == widget.preferences.savedPassword)) {
        _idController.text = widget.preferences.savedUserId;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (!_isSignup) {
        await widget.preferences.setRememberMe(
          _rememberMe,
          _rememberMe ? _idController.text.trim() : '',
          _rememberMe ? _passwordController.text : '',
        );
      }
      await StorageService.recordActivity(
        _isSignup ? 'Account created' : 'Signed in',
        _idController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(preferences: widget.preferences),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not continue: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _requiredLabel(String label) => RichText(
    text: TextSpan(
      style: _authTheme.textTheme.labelLarge,
      children: [
        TextSpan(text: label),
        const TextSpan(
          text: ' *',
          style: TextStyle(color: Color(0xFFD32F2F)),
        ),
      ],
    ),
  );

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _authTheme,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/img/lpu-logo.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_outlined,
                        size: 56,
                        color: AppTokens.maroonPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _isSignup ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignup
                          ? 'Sign up to access the LPU-Cavite Student Portal.'
                          : 'Log in to continue to your student portal.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 28),
                    if (_isSignup) ...[
                      _requiredLabel('Full name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => _required(value, 'Full name'),
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _requiredLabel('Student ID or email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _idController,
                      keyboardType: TextInputType.emailAddress,
                        enableSuggestions: false,
                        autocorrect: false,
                      validator: (value) => _required(value, 'Student ID or email'),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 2024-2-02204',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _requiredLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      validator: (value) {
                        final requiredError = _required(value, 'Password');
                        if (requiredError != null) return requiredError;
                        if (_isSignup && value!.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
                      const SizedBox(height: 16),
                      _requiredLabel('Confirm password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          final requiredError =
                              _required(value, 'Confirm password');
                          if (requiredError != null) return requiredError;
                          return value == _passwordController.text
                              ? null
                              : 'Passwords do not match';
                        },
                        decoration: const InputDecoration(
                          hintText: 'Re-enter your password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _rememberMe,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Remember me'),
                        subtitle: const Text(
                          'Save your student ID/email and password on this device.',
                        ),
                        onChanged: (value) =>
                            setState(() => _rememberMe = value ?? false),
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
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(_isSignup
                            ? 'Already have an account? '
                            : 'Don’t have an account? '),
                        TextButton(
                          onPressed: () => _switchMode(!_isSignup),
                          child: Text(_isSignup ? 'Log in' : 'Sign up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '* Required field',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
          );
        },
      ),
    );
  }
}
