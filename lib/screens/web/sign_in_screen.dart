import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Sign-in screen for web — shows a single "Sign in with Google" button.
/// All auth complexity is behind the scenes.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _signingIn = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Branding
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.accentGold, Color(0xFFF5D77A)],
                ).createShader(bounds),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_esports,
                        size: 48, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'STASH 64',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Retro Game Collection Manager',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),

              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Sign in button
              _signingIn
                  ? const CircularProgressIndicator(
                      color: AppTheme.accentGold)
                  : _GoogleSignInButton(onPressed: _handleSignIn),

              const SizedBox(height: 32),
              const Text(
                'Sign in to sync your collection across devices',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });

    try {
      // TODO: Integrate with Google Sign-In SDK for web.
      // The SDK will provide the idToken after user clicks the button.
      // For now, this is the integration point:
      //
      //   final googleUser = await GoogleSignIn(
      //     clientId: 'YOUR_GOOGLE_CLIENT_ID',
      //     scopes: ['email', 'profile'],
      //   ).signIn();
      //   final auth = await googleUser?.authentication;
      //   final idToken = auth?.idToken;
      //
      // Then send to backend:
      //   await context.read<AuthProvider>().signInWithGoogle(idToken!);

      // Placeholder — will be wired to actual Google Sign-In SDK
      throw UnimplementedError(
          'Google Sign-In SDK integration pending. '
          'Set GOOGLE_CLIENT_ID and wire up the google_sign_in package.');
    } on UnimplementedError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      setState(() => _signingIn = false);
    }
  }
}

/// Official-looking Google Sign-In button.
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 2,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Google "G" logo placeholder (use official assets in production)
          Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
          SizedBox(width: 12),
          Text(
            'Sign in with Google',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}
