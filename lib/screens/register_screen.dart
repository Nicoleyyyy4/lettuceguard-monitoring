import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../widgets/neumorphic_card.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: LettuceGuardColors.neuBackground,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: LettuceGuardColors.statusError, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Password Guide',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LettuceGuardColors.textDark),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your password must satisfy all requirements:',
              style: TextStyle(fontSize: 13, color: LettuceGuardColors.textDark),
            ),
            const SizedBox(height: 12),
            ...unmetRules.map(
              (rule) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel, color: LettuceGuardColors.statusError, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LettuceGuardColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LettuceGuardColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
      // Register in Firebase Auth & write profile to Firebase Realtime DB
      await _authService.registerWithEmail(name, email, password);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account for $name created successfully! Log in to continue.'),
          backgroundColor: LettuceGuardColors.primaryGreen,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Registration failed. Please check your connection and try again.';
      final errStr = e.toString().toLowerCase();

      if (errStr.contains('email-already-in-use')) {
        errorMessage = 'This email address is already registered.';
      } else if (errStr.contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (errStr.contains('weak-password')) {
        errorMessage = 'The password provided is too weak.';
      } else if (errStr.contains('permission-denied')) {
        errorMessage = 'Database permission denied. Check Firebase security rules.';
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
    return Scaffold(
      backgroundColor: LettuceGuardColors.neuBackground,
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: LettuceGuardColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Hydroponics Background Image Design with Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=1200&q=80',
                  ),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      LettuceGuardColors.neuBackground.withValues(alpha: 0.92),
                      LettuceGuardColors.neuBackground.withValues(alpha: 0.82),
                      LettuceGuardColors.primaryGreen.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Decorative Neumorphic Circle Accent
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LettuceGuardColors.accentLightGreen.withValues(alpha: 0.25),
              ),
            ),
          ),

          // 2. Main Scrollable Neumorphic Form Container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Icon Badge
                    NeumorphicCard(
                      borderRadius: 100,
                      padding: const EdgeInsets.all(18),
                      distance: 6,
                      blur: 14,
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 48,
                        color: LettuceGuardColors.primaryGreen,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Join LettuceGuard',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: LettuceGuardColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Set up your greenhouse operator profile',
                      style: TextStyle(
                        fontSize: 13,
                        color: LettuceGuardColors.textMuted,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. Floating Neumorphic Cardbox
                    NeumorphicCard(
                      borderRadius: 28,
                      padding: const EdgeInsets.all(24),
                      distance: 10,
                      blur: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Operator Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: LettuceGuardColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Full Name Input Field
                          NeumorphicCard(
                            isInset: true,
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            distance: 3,
                            blur: 6,
                            child: TextField(
                              controller: nameController,
                              enabled: !_isLoading,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(fontSize: 13, color: LettuceGuardColors.textMuted),
                                prefixIcon: Icon(Icons.person_outline, color: LettuceGuardColors.primaryGreen),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Email Input Field
                          NeumorphicCard(
                            isInset: true,
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            distance: 3,
                            blur: 6,
                            child: TextField(
                              controller: emailController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(fontSize: 13, color: LettuceGuardColors.textMuted),
                                prefixIcon: Icon(Icons.email_outlined, color: LettuceGuardColors.primaryGreen),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Password Input Field with Interactive Eye Toggle & Validation
                          NeumorphicCard(
                            isInset: true,
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            distance: 3,
                            blur: 6,
                            child: TextField(
                              controller: passwordController,
                              enabled: !_isLoading,
                              obscureText: _obscurePassword,
                              onChanged: (val) {
                                if (_passwordErrorText != null) {
                                  setState(() {
                                    _passwordErrorText = _validatePassword(val);
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '8-12 chars, A-Z, 0-9, symbol',
                                hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
                                labelStyle: const TextStyle(fontSize: 13, color: LettuceGuardColors.textMuted),
                                prefixIcon: const Icon(Icons.lock_outline, color: LettuceGuardColors.primaryGreen),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: LettuceGuardColors.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          // Password Rule Error / Warning Text
                          if (_passwordErrorText != null) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                _passwordErrorText!,
                                style: const TextStyle(
                                  color: LettuceGuardColors.statusError,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Neumorphic Primary Register Button
                          GestureDetector(
                            onTap: _isLoading ? null : _handleRegistration,
                            child: NeumorphicCard(
                              borderRadius: 18,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: LettuceGuardColors.primaryGreen,
                              distance: 6,
                              blur: 12,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'CREATE ACCOUNT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Back to Login Button
                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.arrow_back, size: 18, color: LettuceGuardColors.primaryGreen),
                      label: const Text(
                        'Already have an account? Sign In',
                        style: TextStyle(
                          color: LettuceGuardColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
