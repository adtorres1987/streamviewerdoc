import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/guards.dart';
import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/room_provider.dart';
import '../../services/group_service.dart';

/// Shows a single group's details — room list + member invite action.
class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupProvider(groupId));
    final roomsAsync = ref.watch(roomsProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Grupo'),
          data: (g) => Text(g.name),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invitar miembro',
            onPressed: () => _showInviteDialog(context, ref),
          ),
        ],
      ),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(roomsProvider(groupId)),
        ),
        data: (rooms) {
          // Sort newest first.
          final sorted = [...rooms]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sorted.isEmpty
              ? _EmptyRooms(
                  onCreate: () => _showCreateRoomDialog(context, ref))
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(roomsProvider(groupId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) =>
                        _RoomTile(room: sorted[index]),
                  ),
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRoomDialog(context, ref),
        tooltip: 'Crear sala',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateRoomDialog(
      BuildContext context, WidgetRef ref) async {
    // Guard: active subscription required.
    final hasAccess = await checkRoomAccess(ref, context);
    if (!hasAccess || !context.mounted) return;

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva sala'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre de la sala',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final room = await ref
            .read(roomActionsProvider.notifier)
            .createRoom(groupId, controller.text.trim());
        // Navigate immediately into the PDF viewer as host.
        if (context.mounted) {
          context.push('/room/${room.id}?role=host');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
    controller.dispose();
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar miembro'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email del invitado',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa un email' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Invitar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await GroupService().inviteToGroup(groupId, controller.text.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitación enviada.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
    controller.dispose();
  }
}

// ---------------------------------------------------------------------------
// Room list tile
// ---------------------------------------------------------------------------

class _RoomTile extends ConsumerWidget {
  const _RoomTile({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEnter = room.status == 'waiting' || room.status == 'active';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(room.status).withOpacity(0.15),
          child: Icon(Icons.picture_as_pdf, color: _statusColor(room.status)),
        ),
        title: Text(room.name),
        subtitle: Row(
          children: [
            _StatusBadge(status: room.status),
            const SizedBox(width: 8),
            Text(
              'Código: ${room.code}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: canEnter ? const Icon(Icons.chevron_right) : null,
        onTap: canEnter
            ? () {
                // Determine role client-side from hostId.
                // The server enforces the real role — this sets the initial UI mode.
                final currentUser = ref.read(currentUserProvider);
                final role =
                    room.hostId == currentUser?.id ? 'host' : 'viewer';
                context.push('/room/${room.id}?role=$role');
              }
            : null,
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'active' => Colors.green,
        'waiting' => Colors.blue,
        'host_disconnected' => Colors.orange,
        _ => Colors.grey,
      };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Activa', Colors.green.shade700),
      'waiting' => ('Esperando', Colors.blue.shade700),
      'host_disconnected' => ('Desconectado', Colors.orange.shade700),
      _ => ('Cerrada', Colors.grey.shade600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local sub-widgets
// ---------------------------------------------------------------------------

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.meeting_room_outlined,
                size: 64, color: Color(0xFF4F46E5)),
            const SizedBox(height: 20),
            Text('Sin salas todavía',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Crea la primera sala para empezar una sesión sincronizada.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear sala'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
