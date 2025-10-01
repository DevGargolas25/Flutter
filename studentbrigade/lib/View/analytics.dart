import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        backgroundColor: const Color(0xFF99D2D2),
      ),
      body: const Center(
        child: Text(
          "Dummy Analytics Page ",
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF4A2951),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
