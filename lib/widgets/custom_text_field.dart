import 'package:flutter/material.dart';
import 'package:taskmap/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    this.onSaved,
    this.onChanged,
    required this.hintText,
    required this.prefixIcon,
    required this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF9CA3AF), size: 20),
        filled: true,
        fillColor: AppColors.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
    );
  }
}
