import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../utils/app_snackbar.dart';

/// Call before any action that needs a live network call.
/// Returns true if online. If offline, shows a snackbar and returns false
/// so the caller can bail out without attempting the request.
bool ensureOnline(BuildContext context, WidgetRef ref) {
  final isOnline = ref
      .read(isOnlineProvider)
      .maybeWhen(
        data: (online) => online,
        orElse: () => true, // don't block actions while status is loading
      );

  if (!isOnline) {
    AppSnackbar.error(
      context,
      'No internet connection. Please try again once you\'re back online.',
    );
  }
  return isOnline;
}
