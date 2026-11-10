import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskmap/providers/firebase_provider.dart';
import 'package:taskmap/screens/auth/login_screen.dart';

import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_password_field.dart';

import '../../utils/firebase_error_handler.dart';
import '../../utils/app_snackbar.dart';
import '../../theme/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  static const String routeName = "/register";

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
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
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Full Name
                        _buildLabel('Full Name'),
                        const SizedBox(height: 6),
                        CustomTextField(
                          hintText: 'e.g. Alex Johnson',
                          prefixIcon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter your name";
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _name = value!.trim();
                          },
                        ),

                        const SizedBox(height: 16),
                        // School Email
                        _buildLabel('School Email'),
                        const SizedBox(height: 6),
                        CustomTextField(
                          hintText: 'student@polytechnic.edu.sg',
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }

                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return "Enter a valid email";
                            }

                            return null;
                          },
                          onSaved: (value) {
                            _email = value!.trim();
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        CustomPasswordField(
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                          onChanged: (value) => _password = value,
                          onSaved: (value) {
                            _password = value!.trim();
                          },
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

                            if (value != _password) {
                              return 'Passwords do not match';
                            }

                            return null;
                          },
                          onChanged: (value) => _confirmPassword = value,
                          onSaved: (value) {
                            _confirmPassword = value!.trim();
                          },
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
                                      .register(
                                        email: _email,
                                        password: _password,
                                      );
                                  await FirebaseAuth.instance.currentUser
                                      ?.updateDisplayName(_name);
                                  await ref
                                      .read(userServiceProvider)
                                      .createUser(
                                        UserModel(
                                          uid: FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                          fullName: _name,
                                          email: _email,
                                          emailVerified: false,
                                          isPremium: false,
                                          premiumExpiry: null,
                                          aiUsageCount: 0,
                                          lastResetDate: DateTime.now(),
                                          createdAt: DateTime.now(),
                                        ),
                                      );
                                  await ref
                                      .read(firebaseServiceProvider)
                                      .sendEmailVerification();

                                  if (!mounted) return;

                                  AppSnackbar.success(
                                    context,
                                    "Account created successfully. Please verify your email.",
                                  );
                                  Navigator.pushReplacementNamed(
                                    context,
                                    LoginScreen.routeName,
                                  );
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
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Create Account',
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
                  const SizedBox(height: 20),
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have a account? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            LoginScreen.routeName,
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A56DB),
                          ),
                        ),
                      ),
                    ],
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
