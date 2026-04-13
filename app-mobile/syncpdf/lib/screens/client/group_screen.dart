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
    final currentUser = ref.watch(currentUserProvider);

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
          final isOwner =
              groupAsync.valueOrNull?.ownerId == currentUser?.id;
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
                    itemBuilder: (context, index) {
                      final room = sorted[index];
                      final isHost = room.hostId == currentUser?.id;
                      final canEnter = room.status == 'waiting' ||
                          room.status == 'active' ||
                          (room.status == 'host_disconnected' && isHost);
                      final role = isHost ? 'host' : 'viewer';
                      return _RoomTile(
                        room: room,
                        isOwner: isOwner,
                        currentUserId: currentUser?.id,
                        onEnter: canEnter
                            ? () => context.push(
                                '/room/${room.id}?role=$role')
                            : null,
                        onReopen: (isHost && room.status == 'closed')
                            ? () => _confirmReopenRoom(context, ref, room)
                            : null,
                        onDeleteRequested: () =>
                            _confirmDeleteRoom(context, ref, room),
                      );
                    },
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

  Future<void> _confirmReopenRoom(
      BuildContext context, WidgetRef ref, Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reabrir sala'),
        content: Text(
            '¿Quieres volver a abrir "${room.name}"? La sala quedará en espera hasta que ingreses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(roomActionsProvider.notifier)
            .reopenRoom(room.id, groupId: groupId);
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
  }

  Future<void> _confirmDeleteRoom(
      BuildContext context, WidgetRef ref, Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar sala'),
        content: Text(
            '¿Seguro que quieres eliminar "${room.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(roomActionsProvider.notifier)
            .deleteRoom(room.id, groupId: groupId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
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

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.isOwner,
    required this.currentUserId,
    required this.onEnter,
    required this.onReopen,
    required this.onDeleteRequested,
  });
  final Room room;
  final bool isOwner;
  final String? currentUserId;
  final VoidCallback? onEnter;
  final VoidCallback? onReopen;
  final VoidCallback onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    final isHost = room.hostId == currentUserId;
    final canEnter = room.status == 'waiting' ||
        room.status == 'active' ||
        (room.status == 'host_disconnected' && isHost);
    final canReopen = isHost && room.status == 'closed';
    final statusColor = _statusColor(room.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(38),
          child: Icon(Icons.picture_as_pdf, color: statusColor),
        ),
        title: Text(room.name),
        subtitle: Row(
          children: [
            _StatusBadge(status: room.status),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Código: ${room.code}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: isOwner
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'enter') {
                    onEnter?.call();
                  } else if (value == 'reopen') {
                    onReopen?.call();
                  } else if (value == 'delete') {
                    onDeleteRequested();
                  }
                },
                itemBuilder: (_) => [
                  if (canEnter)
                    const PopupMenuItem(
                      value: 'enter',
                      child: Row(children: [
                        Icon(Icons.play_arrow_outlined),
                        SizedBox(width: 8),
                        Text('Entrar a la sala'),
                      ]),
                    ),
                  if (canReopen)
                    const PopupMenuItem(
                      value: 'reopen',
                      child: Row(children: [
                        Icon(Icons.restart_alt_outlined),
                        SizedBox(width: 8),
                        Text('Reabrir sala'),
                      ]),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar sala',
                          style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              )
            : canEnter
                ? const Icon(Icons.chevron_right)
                : canReopen
                    ? const Icon(Icons.restart_alt_outlined)
                    : null,
        onTap: !isOwner
            ? (canEnter
                ? onEnter
                : canReopen
                    ? onReopen
                    : null)
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
