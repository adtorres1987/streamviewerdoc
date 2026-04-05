import 'package:flutter/material.dart';

/// Floating overlay (positioned top-right) that displays the room code and
/// participant count.  Shown/hidden by tapping the AppBar icon.
///
/// Usage:
/// ```dart
/// Stack(children: [
///   ...,
///   if (_showOverlay)
///     Positioned(
///       top: 8, right: 8,
///       child: RoomOverlay(
///         roomCode: code,
///         participantCount: count,
///         onClose: () => setState(() => _showOverlay = false),
///       ),
///     ),
/// ])
/// ```
class RoomOverlay extends StatelessWidget {
  const RoomOverlay({
    super.key,
    required this.roomCode,
    required this.participantCount,
    required this.onClose,
  });

  /// Short alphanumeric code participants use to identify the session.
  final String roomCode;

  /// Live count of connected participants (updated from [SyncState]).
  final int participantCount;

  /// Callback that hides the overlay.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sala',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, size: 16, color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Room code in large monospaced font.
            Text(
              roomCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  '$participantCount participante${participantCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
