import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        backgroundColor: cs.primary,   // ✅ Usa color primario dinámico
        foregroundColor: cs.onPrimary, // ✅ Texto y íconos legibles
      ),
      body: Center(
        child: Text(
          "Dummy Analytics Page",
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface, // ✅ Se adapta a claro/oscuro
          ),
        ),
      ),
    );
  }
}

