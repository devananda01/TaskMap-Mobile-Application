import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskmap/providers/firebase_provider.dart';
import 'package:taskmap/providers/user_provider.dart';
import 'package:taskmap/screens/auth/forgot_password_screen.dart';
import 'package:taskmap/screens/auth/register_screen.dart';
import 'package:taskmap/screens/auth/email_verification_screen.dart';
import 'package:taskmap/screens/dashboard/dashboard_screen.dart';

import 'package:taskmap/widgets/custom_text_field.dart';
import 'package:taskmap/widgets/custom_password_field.dart';

import '../../utils/firebase_error_handler.dart';
import '../../utils/app_snackbar.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = "/login";

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final hasSession = FirebaseAuth.instance.currentUser != null;

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
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),

                        const SizedBox(height: 16),
                        //  Email
                        _buildLabel('Email'),
                        const SizedBox(height: 6),
                        CustomTextField(
                          hintText: 'Enter your email',
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }

                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Enter a valid email';
                            }

                            return null;
                          },
                          onSaved: (value) {
                            _email = value!.trim();
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLabel('Password'),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  ForgotPasswordScreen.routeName,
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A56DB),
                                ),
                              ),
                            ),
                          ],
                        ),

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
                          onSaved: (value) {
                            _password = value!.trim();
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
                                      .login(
                                        email: _email,
                                        password: _password,
                                      );

                                  await ref
                                      .read(firebaseServiceProvider)
                                      .reloadUser();
                                  await ref
                                      .read(userProvider.notifier)
                                      .refreshUser();

                                  bool verified = ref
                                      .read(firebaseServiceProvider)
                                      .isEmailVerified();
                                  FocusScope.of(context).unfocus();

                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();

                                  if (!verified) {
                                    if (!mounted) return;

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EmailVerificationScreen(),
                                      ),
                                    );

                                    return;
                                  }
                                  if (!mounted) return;

                                  AppSnackbar.success(
                                    context,
                                    "Logged in successfully.",
                                  );
                                  await ref
                                      .read(userProvider.notifier)
                                      .loadUser();

                                  if (!mounted) return;

                                  Navigator.pushReplacementNamed(
                                    context,
                                    DashboardScreen.routeName,
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
                              children: [
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimaryOf(context),
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
                        const SizedBox(height: 20),
                        // Divider
                        const Row(
                          children: [
                            Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Or',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Google Sign In button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(firebaseServiceProvider)
                                    .signInWithGoogle();

                                if (!mounted) return;

                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                AppSnackbar.success(
                                  context,
                                  "Signed in with Google successfully.",
                                );
                                await ref
                                    .read(userProvider.notifier)
                                    .loadUser();

                                Navigator.pushReplacementNamed(
                                  context,
                                  DashboardScreen.routeName,
                                );
                              } catch (e) {
                                AppSnackbar.error(
                                  context,
                                  FirebaseErrorHandler.getMessage(e),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.g_mobiledata,
                              color: Colors.red,
                              size: 28,
                            ),
                            label: const Text(
                              "Continue with Google",
                              style: TextStyle(
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(firebaseServiceProvider)
                                    .signInWithGitHub();

                                if (!mounted) return;

                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();

                                AppSnackbar.success(
                                  context,
                                  "Signed in with GitHub successfully.",
                                );
                                await ref
                                    .read(userProvider.notifier)
                                    .loadUser();

                                Navigator.pushReplacementNamed(
                                  context,
                                  DashboardScreen.routeName,
                                );
                              } catch (e) {
                                AppSnackbar.error(
                                  context,
                                  FirebaseErrorHandler.getMessage(e),
                                );
                              }
                            },
                            icon: const Icon(Icons.code),
                            label: const Text("Continue with GitHub"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                        'New to TaskMap?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            RegisterScreen.routeName,
                          );
                        },
                        child: const Text(
                          'Create an account.',
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
