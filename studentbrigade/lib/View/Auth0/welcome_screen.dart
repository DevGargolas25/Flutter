// lib/view/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToLogin;
  final VoidCallback onNavigateToSignUp;

  /// Si es la primera vez sin internet, deshabilitamos botones de auth.
  final bool disableAuthButtons;

  /// (Opcional) Email del último login para UX (no sensible).
  final String? lastEmail;

  /// (Opcional) Si no es null, muestra un botón "Continuar".
  final VoidCallback? onContinueSession;

  const WelcomeScreen({
    super.key,
    required this.onNavigateToLogin,
    required this.onNavigateToSignUp,
    this.disableAuthButtons = false,
    this.lastEmail,
    this.onContinueSession, // ← NUEVO
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.roboto(
      fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2,
    );
    final subtitleStyle = GoogleFonts.roboto(
      fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.9),
    );
    final hintStyle = GoogleFonts.roboto(
      fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF75C1C7), Color(0xFF60B896)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Centro
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  SizedBox(
                    width: 180, height: 180,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Student Brigade', style: titleStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Emergency response at your fingertips', style: subtitleStyle, textAlign: TextAlign.center),
                  if (lastEmail != null && lastEmail!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Último acceso: $lastEmail', style: hintStyle, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),

            // Zona inferior
            if (!disableAuthButtons) ...[
              // Botón Continuar (opcional)
              if (onContinueSession != null) ...[
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A2951),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: onContinueSession,
                    child: Text('Continue as ${lastEmail ?? 'user'}'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Log in
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4A2951),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: onNavigateToLogin,
                  child: const Text('Log in'),
                ),
              ),
              const SizedBox(height: 12),

              // Sign up
              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: onNavigateToSignUp,
                  child: const Text('Sign up'),
                ),
              ),
              const SizedBox(height: 16),
              Text('Universidad de los Andes', style: GoogleFonts.roboto(color: Colors.white70)),
              const SizedBox(height: 8),
            ] else ...[
              // SIN Internet en primera vez: ocultar botones y mostrar mensaje
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "You can't sign in for the first time without an Internet connection. "
                      "Please connect to the Internet to continue.",
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text('Universidad de los Andes', style: GoogleFonts.roboto(color: Colors.white70)),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}


