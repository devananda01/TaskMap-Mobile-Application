import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final bool large;

  const SectionLabel(this.text, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: large ? 14 : 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }
}
