import 'package:flutter/material.dart';

/// Generic base banner — a coloured strip pinned to the bottom of the screen.
///
/// Used by the concrete host-disconnected, host-reconnected, and
/// session-closed banners.
class SyncBanner extends StatelessWidget {
  const SyncBanner({
    super.key,
    required this.color,
    required this.message,
    this.actions = const [],
  });

  final Color color;
  final String message;

  /// Optional row of action widgets (e.g. TextButtons) placed to the right
  /// of the message.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: ColoredBox(
        color: color,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOST_DISCONNECTED banner
// ---------------------------------------------------------------------------

/// Shown when the host drops.  Viewer enters free-scroll mode.
class HostDisconnectedBanner extends StatelessWidget {
  const HostDisconnectedBanner({super.key, this.lastPage});

  /// Last known page the host was on — displayed for context.
  final int? lastPage;

  @override
  Widget build(BuildContext context) {
    final pageInfo = lastPage != null ? ' · Ultima pag. $lastPage' : '';
    return SyncBanner(
      color: Colors.orange.shade800,
      message: 'Host desconectado$pageInfo · Navegando libremente',
    );
  }
}

// ---------------------------------------------------------------------------
// HOST_RECONNECTED banner
// ---------------------------------------------------------------------------

/// Shown when the host reconnects.  Viewer chooses to re-sync or stay free.
class HostReconnectedBanner extends StatelessWidget {
  const HostReconnectedBanner({
    super.key,
    required this.hostName,
    required this.onAccept,
    required this.onDecline,
  });

  final String hostName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return SyncBanner(
      color: Colors.indigo.shade700,
      message: '$hostName volvio  Volver a sincronizar?',
      actions: [
        TextButton(
          onPressed: onAccept,
          child: const Text('Si', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: onDecline,
          child: const Text('No',
              style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SESSION_CLOSED banner
// ---------------------------------------------------------------------------

/// Shown when the session is permanently ended.
class SessionClosedBanner extends StatelessWidget {
  const SessionClosedBanner({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SyncBanner(
      color: Colors.red.shade800,
      message: 'La sesion fue cerrada por el servidor.',
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('Salir', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
