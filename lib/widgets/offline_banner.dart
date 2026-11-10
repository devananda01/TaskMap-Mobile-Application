import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

/// Slim red bar pinned to the top of the app whenever there's no
/// connection. Disappears automatically the moment connectivity returns.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);

    final isOffline = isOnlineAsync.maybeWhen(
      data: (online) => !online,
      orElse: () => false, // don't flash "offline" while the stream loads
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isOffline
          ? Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              color: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'No internet connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('online')),
    );
  }
}
