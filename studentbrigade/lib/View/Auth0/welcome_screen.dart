import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToLogin;
  final VoidCallback onNavigateToSignUp;

  const WelcomeScreen({
    super.key,
    required this.onNavigateToLogin,
    required this.onNavigateToSignUp,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.roboto(
      fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white,
      letterSpacing: 2,
    );
    final subtitleStyle = GoogleFonts.roboto(
      fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.9),
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
                  // Logo (coloca tu Asset o NetworkImage)
                  SizedBox(
                    width: 180, height: 180,
                    child: Image.asset(
                      'assets/images/logo.png', // <-- agrega tu logo aquí
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Student Brigade', style: titleStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Emergency response at your fingertips', style: subtitleStyle, textAlign: TextAlign.center),
                ],
              ),
            ),

            // Botones
            Column(
              children: [
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
                Text('Universidad de los Andes',
                    style: GoogleFonts.roboto(color: Colors.white70)),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
