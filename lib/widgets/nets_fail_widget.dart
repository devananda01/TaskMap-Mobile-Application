import 'dart:async';
import 'package:flutter/material.dart';

class NETSFailWidget extends StatefulWidget {
  const NETSFailWidget({super.key});

  @override
  State<NETSFailWidget> createState() => _NETSFailWidgetState();
}

class _NETSFailWidgetState extends State<NETSFailWidget> {
  Timer? _timer;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  // Starts a countdown timer that updates the UI every second and navigates back when it reaches zero
  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
        if (_countdown == 0) Navigator.of(context).pushReplacementNamed("/");
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'images/red_cross.png',
          width: MediaQuery.of(context).size.width * 0.6,
        ),

        const SizedBox(height: 10),

        const Text(
          "Payment Failed",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "Returning to home in $_countdown seconds",
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
