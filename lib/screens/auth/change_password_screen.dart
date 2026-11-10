import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskmap/providers/firebase_provider.dart';

import '../../widgets/custom_password_field.dart';

import '../../utils/firebase_error_handler.dart';
import '../../utils/app_snackbar.dart';
import '../../theme/app_colors.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  static const String routeName = "/change-password";

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _obscurecurrentPassword = true;
  bool _obscurenewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      //back arrow to dashboard
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A56DB)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      color: Color(0xFF1A56DB),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TaskMap',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A56DB),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password
                        _buildLabel('Current Password'),
                        const SizedBox(height: 6),
                        CustomPasswordField(
                          obscure: _obscurecurrentPassword,
                          onToggle: () => setState(
                            () => _obscurecurrentPassword =
                                !_obscurecurrentPassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                          onChanged: (value) => _currentPassword = value,
                          onSaved: (value) => _currentPassword = value!.trim(),
                        ),
                        const SizedBox(height: 16),
                        // Password
                        _buildLabel('New Password'),
                        const SizedBox(height: 6),
                        CustomPasswordField(
                          obscure: _obscurenewPassword,
                          onToggle: () => setState(
                            () => _obscurenewPassword = !_obscurenewPassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            if (value == _currentPassword) {
                              return "New password must be different from current password";
                            }

                            return null;
                          },
                          onChanged: (value) => _newPassword = value,
                          onSaved: (value) => _newPassword = value!.trim(),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password
                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 6),
                        CustomPasswordField(
                          obscure: _obscureConfirmPassword,
                          onToggle: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }

                            if (value != _newPassword) {
                              return 'Passwords do not match';
                            }

                            return null;
                          },
                          onChanged: (value) => _confirmPassword = value,
                          onSaved: (value) => _confirmPassword = value!.trim(),
                        ),
                        const SizedBox(height: 24),
                        // Sign In button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                try {
                                  await ref
                                      .read(firebaseServiceProvider)
                                      .changePassword(
                                        currentPassword: _currentPassword,
                                        newPassword: _newPassword,
                                      );

                                  if (!mounted) return;

                                  AppSnackbar.success(
                                    context,
                                    "Your password has been updated successfully.",
                                  );

                                  Navigator.pop(context);
                                } catch (e) {
                                  AppSnackbar.error(
                                    context,
                                    FirebaseErrorHandler.getMessage(e),
                                  );
                                }
                              }
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A56DB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }
}
