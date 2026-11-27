import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/responsive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _passwordErrorText;
  String _passwordDraft = '';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Strict Password Validation Rule Checker
  List<String> _getUnmetPasswordRules(String password) {
    final List<String> unmet = [];
    if (password.length < 8 || password.length > 12) {
      unmet.add('Length must be between 8 and 12 characters.');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      unmet.add('Must contain at least 1 Uppercase letter (A-Z).');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      unmet.add('Must contain at least 1 Number (0-9).');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      unmet.add('Must contain at least 1 Special character (!@#\$%^&*...).');
    }
    return unmet;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required.';
    }
    final unmet = _getUnmetPasswordRules(password);
    if (unmet.isNotEmpty) {
      return unmet.first;
    }
    return null;
  }

  void _showPasswordGuideDialog(List<String> unmetRules) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: LettuceGuardColors.statusError,
              size: 26,
            ),
            SizedBox(width: 10),
            Expanded(child: Text('Password Guide')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your password must satisfy all requirements:',
                style: TextStyle(
                  fontSize: 13,
                  color: LettuceGuardColors.textPrimary(ctx),
                ),
              ),
              const SizedBox(height: 12),
              ...unmetRules.map(
                (rule) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cancel_rounded,
                        color: LettuceGuardColors.statusError,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rule,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: LettuceGuardColors.textPrimary(ctx),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegistration() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in your name and email address.'),
          backgroundColor: LettuceGuardColors.statusError,
        ),
      );
      return;
    }

    final unmetRules = _getUnmetPasswordRules(password);
    if (unmetRules.isNotEmpty) {
      setState(() {
        _passwordErrorText = unmetRules.first;
      });
      _showPasswordGuideDialog(unmetRules);
      return;
    }

    setState(() {
      _passwordErrorText = null;
      _isLoading = true;
    });

    try {
      await _authService.registerWithEmail(name, email, password);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account for $name created successfully! Log in to continue.',
          ),
          backgroundColor: LettuceGuardColors.primaryGreen,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      String errorMessage =
          'Registration failed. Please check your connection and try again.';
      final errStr = e.toString().toLowerCase();

      if (errStr.contains('email-already-in-use')) {
        errorMessage = 'This email address is already registered.';
      } else if (errStr.contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (errStr.contains('weak-password')) {
        errorMessage = 'The password provided is too weak.';
      } else if (errStr.contains('permission-denied')) {
        errorMessage =
            'Database permission denied. Check Firebase security rules.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: LettuceGuardColors.statusError,
        ),
      );
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
    final isDesktop = LettuceGuardResponsive.isDesktopAuth(context);

    return Scaffold(
      backgroundColor: LettuceGuardColors.canvas(context),
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Create Account'),
              backgroundColor: LettuceGuardColors.primaryGreenDark,
              foregroundColor: Colors.white,
            ),
      body: isDesktop
          ? Row(
              children: [
                Expanded(flex: 10, child: _buildLeftHero(context)),
                Expanded(
                  flex: 11,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _buildRegisterForm(context),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _buildRegisterForm(context),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLeftHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LettuceGuardColors.heroGradient(context),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -90,
            left: -70,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LettuceGuardColors.accentLightGreen.withValues(
                  alpha: 0.14,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'LettuceGuard',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set up your operator workspace.',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Create an authenticated operator profile to synchronize greenhouse alerts, inspect real-time telemetry, and manage hardware nodes securely.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Protected with Firebase Auth & Realtime Telemetry',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    final lenOk = _passwordDraft.length >= 8 && _passwordDraft.length <= 12;
    final upperOk = RegExp(r'[A-Z]').hasMatch(_passwordDraft);
    final numOk = RegExp(r'[0-9]').hasMatch(_passwordDraft);
    final symOk = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordDraft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: LettuceGuardColors.surface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LettuceGuardColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: LettuceGuardColors.shadow(context),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LettuceGuardColors.primary(
                        context,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: LettuceGuardColors.primary(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join LettuceGuard',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: LettuceGuardColors.textPrimary(context),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Set up your greenhouse operator profile',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: LettuceGuardColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onChanged: (val) {
                  setState(() {
                    _passwordDraft = val;
                    if (_passwordErrorText != null) {
                      _passwordErrorText = _validatePassword(val);
                    }
                  });
                },
                onSubmitted: (_) {
                  if (!_isLoading) _handleRegistration();
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: '8-12 chars, A-Z, 0-9, symbol',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _PasswordRuleChip(label: '8-12 chars', met: lenOk),
                  _PasswordRuleChip(label: 'A-Z', met: upperOk),
                  _PasswordRuleChip(label: '0-9', met: numOk),
                  _PasswordRuleChip(label: 'Symbol', met: symOk),
                ],
              ),
              if (_passwordErrorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _passwordErrorText!,
                  style: const TextStyle(
                    color: LettuceGuardColors.statusError,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('CREATE ACCOUNT'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'Already have an account? Sign In',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordRuleChip extends StatelessWidget {
  final String label;
  final bool met;

  const _PasswordRuleChip({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met
        ? LettuceGuardColors.statusOk
        : LettuceGuardColors.textSecondary(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: met
            ? LettuceGuardColors.statusOk.withValues(alpha: 0.12)
            : LettuceGuardColors.surfaceElevated(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: met
              ? LettuceGuardColors.statusOk.withValues(alpha: 0.4)
              : LettuceGuardColors.border(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
