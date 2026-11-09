import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../widgets/neumorphic_card.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _passwordErrorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Strict Password Validation Rule:
  /// - Length: 8 - 12 characters
  /// - At least 1 uppercase letter (A-Z)
  /// - At least 1 number (0-9)
  /// - At least 1 special character (!@#$%^&*(),.?":{}|<>)
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8 || password.length > 12) {
      return 'Password must be 8-12 characters long.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Must contain at least 1 uppercase letter (A-Z).';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Must contain at least 1 number (0-9).';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Must contain at least 1 special character.';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final passError = _validatePassword(password);
    setState(() {
      _passwordErrorText = passError;
    });

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: LettuceGuardColors.statusError,
        ),
      );
      return;
    }

    if (passError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passError),
          backgroundColor: LettuceGuardColors.statusError,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithEmail(email, password);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Sign in failed. Please check credentials and connection.';
      final errStr = e.toString().toLowerCase();

      if (errStr.contains('user-not-found') || errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
        errorMessage = 'Invalid email or password.';
      } else if (errStr.contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (errStr.contains('user-disabled')) {
        errorMessage = 'This account has been disabled.';
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
      body: Stack(
        children: [
          // 1. Background Image Design with Gradient Overlay
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

          // Decorative Neumorphic Accent Circle
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LettuceGuardColors.accentLightGreen.withValues(alpha: 0.2),
              ),
            ),
          ),

          // 2. Main Neumorphic Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Logo Badge
                    NeumorphicCard(
                      borderRadius: 100,
                      padding: const EdgeInsets.all(20),
                      distance: 8,
                      blur: 16,
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 64,
                        color: LettuceGuardColors.primaryGreen,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'LettuceGuard',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: LettuceGuardColors.textDark,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'IoT Hydroponics Monitoring System',
                      style: TextStyle(
                        fontSize: 13,
                        color: LettuceGuardColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

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
                            'Sign In',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: LettuceGuardColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter your credentials to monitor your greenhouse.',
                            style: TextStyle(
                              fontSize: 12,
                              color: LettuceGuardColors.textMuted,
                            ),
                          ),

                          const SizedBox(height: 22),

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

                          const SizedBox(height: 18),

                          // Password Input Field with Eye Icon Toggle & Rule Validation
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

                          // Inline Password Rule Error / Warning Text
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

                          const SizedBox(height: 26),

                          // Neumorphic Primary Action Button
                          GestureDetector(
                            onTap: _isLoading ? null : _handleLogin,
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
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'LOGIN TO SYSTEM',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Neumorphic Secondary Register Button
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: NeumorphicCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        distance: 4,
                        blur: 8,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: const [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                fontSize: 13,
                                color: LettuceGuardColors.textMuted,
                              ),
                            ),
                            Text(
                              'Register Here',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: LettuceGuardColors.primaryGreen,
                              ),
                            ),
                          ],
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
