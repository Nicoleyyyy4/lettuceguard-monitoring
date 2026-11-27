import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../providers/sensor_provider.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/responsive.dart';
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    // Passwords are opaque credentials; preserve whitespace exactly as entered.
    final password = passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: LettuceGuardColors.statusError,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password.'),
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
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = switch (e) {
        fb_auth.FirebaseAuthException(:final code, :final message) => switch (code) {
          'user-not-found' || 'wrong-password' || 'invalid-credential' =>
            'Firebase rejected this email or password. Check that the account '
                'exists in LettuceGuard’s Firebase project.',
          'invalid-email' => 'Please enter a valid email address.',
          'user-disabled' => 'This account has been disabled.',
          'network-request-failed' =>
            'Could not reach Firebase. Check the device’s internet connection.',
          'operation-not-allowed' =>
            'Email and password sign-in is not enabled for this Firebase project.',
          'too-many-requests' =>
            'Too many sign-in attempts. Wait a while, then try again.',
          'invalid-api-key' =>
            'Firebase rejected this app’s API key. Check the Firebase configuration.',
          _ => message ?? 'Sign in failed (Firebase error: $code).',
        },
        _ => 'Sign in failed. Please try again.',
      };

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
    final provider = SensorProviderScope.maybeOf(context);

    return Scaffold(
      backgroundColor: LettuceGuardColors.canvas(context),
      body: Stack(
        children: [
          if (isDesktop)
            Row(
              children: [
                Expanded(flex: 11, child: _buildHeroShowcase(context)),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _buildLoginCard(context, showBrandHeader: false),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            _buildMobileLayout(context),
          if (provider != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              right: 16,
              child: Material(
                color: LettuceGuardColors.surface(
                  context,
                ).withValues(alpha: 0.9),
                shape: CircleBorder(
                  side: BorderSide(color: LettuceGuardColors.border(context)),
                ),
                child: IconButton(
                  tooltip: provider.isDarkMode
                      ? 'Switch to Light Theme'
                      : 'Switch to Dark Theme',
                  icon: Icon(
                    provider.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    size: 20,
                    color: LettuceGuardColors.textPrimary(context),
                  ),
                  onPressed: provider.toggleThemeMode,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroShowcase(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LettuceGuardColors.heroGradient(context),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LettuceGuardColors.accentLightGreen.withValues(
                  alpha: 0.12,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LettuceGuardColors.secondaryTeal.withValues(alpha: 0.18),
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
                  // Brand mark
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LettuceGuard',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Smart Hydroponics Telemetry',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Main pitch
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precision greenhouse monitoring, everywhere.',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Track nutrient pH, TDS, water temperature, reservoir depth, and air climate in real time with automated thermal safeguards.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _HeroFeatureTile(
                          icon: Icons.sensors_rounded,
                          title: 'Live ESP32 & Cloud Telemetry',
                          subtitle:
                              'Real-time readings for DHT22, DS18B20, pH, TDS, and ultrasonic tank levels.',
                        ),
                        const SizedBox(height: 14),
                        const _HeroFeatureTile(
                          icon: Icons.thermostat_auto_rounded,
                          title: 'Automated Heat & Pump Alerts',
                          subtitle:
                              'Confirmed multi-stage heat warnings with automatic circulation pump status.',
                        ),
                        const SizedBox(height: 14),
                        const _HeroFeatureTile(
                          icon: Icons.insights_rounded,
                          title: 'Interactive Historical Analytics',
                          subtitle:
                              'Inspect optimal nutrient zones and chronological greenhouse trends.',
                        ),
                      ],
                    ),
                  ),

                  Text(
                    'LettuceGuard IoT Hydroponics Platform',
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

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // Top gradient accent backdrop
        Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: LettuceGuardColors.heroGradient(context),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(36),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'LettuceGuard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IoT Hydroponics Monitoring System',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLoginCard(context, showBrandHeader: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(
    BuildContext context, {
    required bool showBrandHeader,
  }) {
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
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: LettuceGuardColors.textPrimary(context),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in with your operator account to monitor your greenhouse.',
                style: TextStyle(
                  fontSize: 13,
                  color: LettuceGuardColors.textSecondary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'operator@lettuceguard.io',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isLoading) _handleLogin();
                },
                decoration: InputDecoration(
                  labelText: 'Password',
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('LOGIN TO SYSTEM'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                "Don't have an account?",
                style: TextStyle(
                  fontSize: 13.5,
                  color: LettuceGuardColors.textSecondary(context),
                ),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                child: const Text(
                  'Register Here',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: LettuceGuardColors.accentLightGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
