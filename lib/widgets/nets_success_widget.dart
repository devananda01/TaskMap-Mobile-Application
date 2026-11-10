import 'dart:async';
import 'package:flutter/material.dart';

class NETSSuccessWidget extends StatefulWidget {
  const NETSSuccessWidget({super.key});

  @override
  State<NETSSuccessWidget> createState() => _NETSSuccessWidgetState();
}

class _NETSSuccessWidgetState extends State<NETSSuccessWidget> {
  Timer? _timer;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  // Starts a countdown timer that updates the UI every second and
  // navigates back once it reaches zero — mirrors NETSFailWidget so both
  // screens behave the same way.
  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
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
      children: [
        Image.asset(
          'images/green_tick.png',
          width: MediaQuery.of(context).size.width * 0.6,
        ),

        const SizedBox(height: 10),

        const Text(
          "Payment Successful",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "You're now Premium! Returning home in $_countdown seconds",
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
