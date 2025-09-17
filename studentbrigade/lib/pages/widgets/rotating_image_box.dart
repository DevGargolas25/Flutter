import 'dart:async';
import 'package:flutter/material.dart';

class RotatingImageBox extends StatefulWidget {
  const RotatingImageBox({super.key});

  @override
  State<RotatingImageBox> createState() => _RotatingImageBoxState();
}

class _RotatingImageBoxState extends State<RotatingImageBox> {
  final List<String> _images = [
    'assets/images/aid1.jpg',
    'assets/images/aid2.jpg',
    'assets/images/aid3.jpg',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF75C1C7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          _images[_currentIndex],
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
