import 'package:flutter/material.dart';
import 'package:taskmap/providers/firebase_provider.dart';
import 'package:taskmap/screens/auth/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskmap/utils/app_snackbar.dart';
import 'package:taskmap/theme/app_colors.dart';

class EmailVerificationScreen extends ConsumerWidget {
  static const String routeName = "/email-verification";

  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Verify Email",
          style: TextStyle(
            color: Color(0xFF1A56DB),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A56DB)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.mark_email_read_outlined,
                size: 90,
                color: Color(0xFF1A56DB),
              ),

              const SizedBox(height: 24),

              const Text(
                "Verify Your Email",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              const Text(
                "We've sent a verification email to your registered email address.\n\nPlease verify your email before logging in to TaskMap.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(firebaseServiceProvider)
                        .sendEmailVerification();

                    AppSnackbar.info(
                      context,
                      "Verification email sent. Please check your inbox.",
                    );
                  },
                  child: const Text("Resend Verification Email"),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    LoginScreen.routeName,
                    (route) => false,
                  );
                },
                child: const Text("Back to Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
