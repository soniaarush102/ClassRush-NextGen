import 'package:flutter/material.dart';

import '../data/discussion_room.dart';
import '../data/discussion_room_repository.dart';

class OpenRoomsScreen extends StatefulWidget {
  const OpenRoomsScreen({super.key});

  @override
  State<OpenRoomsScreen> createState() => _OpenRoomsScreenState();
}

class _OpenRoomsScreenState extends State<OpenRoomsScreen> {
  final _searchController = TextEditingController();
  final _repository = DiscussionRoomRepository();
  late final Stream<List<DiscussionRoom>> _roomsStream;
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _roomsStream = _repository.watchOpenRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open meeting rooms'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _isCreating ? null : _showCreateRoomDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create room'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<DiscussionRoom>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          final rooms = snapshot.data ?? const <DiscussionRoom>[];
          final query = _searchController.text.trim().toLowerCase();
          final visibleRooms = rooms.where((room) {
            return query.isEmpty ||
                room.title.toLowerCase().contains(query) ||
                room.description.toLowerCase().contains(query) ||
                room.hostName.toLowerCase().contains(query);
          }).toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 32, 20, compact ? 16 : 32, 32,
            ),
            children: [
              Text(
                'Find a meeting',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an open room or join a discussion with other participants.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search meeting names or descriptions',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                _RoomsMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load meeting rooms',
                  message: 'Check your connection and Firebase access, then try again.',
                  actionLabel: 'Retry',
                  onAction: () => setState(() {
                    // Rebuild the stream after a transient connection error.
                  }),
                )
              else if (visibleRooms.isEmpty)
                _RoomsMessage(
                  icon: Icons.meeting_room_outlined,
                  title: query.isEmpty ? 'No open rooms yet' : 'No matching rooms',
                  message: query.isEmpty
                      ? 'Create the first room. It will be visible here for others to join.'
                      : 'Try another search or create a new room.',
                  actionLabel: 'Create a room',
                  onAction: _showCreateRoomDialog,
                )
              else ...[
                Text(
                  '${visibleRooms.length} ${visibleRooms.length == 1 ? 'open room' : 'open rooms'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ...visibleRooms.map(
                  (room) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RoomCard(
                      room: room,
                      isJoining: _isJoining,
                      onJoin: () => _joinRoom(room),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _joinRoom(DiscussionRoom room) async {
    if (_isJoining) return;
    setState(() => _isJoining = true);
    try {
      await _repository.joinRoom(room.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have joined this room. The live whiteboard and video meeting workspace are not connected in this build yet.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } on DiscussionRoomException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not join this room. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _showCreateRoomDialog() async {
    if (_isCreating) return;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final details = await showDialog<_NewRoomDetails>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create a meeting room'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Meeting name',
                    hintText: 'e.g. Evening discussion',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'What would you like to discuss?',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(
                dialogContext,
                _NewRoomDetails(
                  title: title,
                  description: descriptionController.text.trim(),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
    if (details == null || !mounted) return;

    setState(() => _isCreating = true);
    try {
      await _repository.createRoom(
        title: details.title,
        topic: 'General',
        description: details.description,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your room is open and ready for others to join.'),
        ),
      );
    } on DiscussionRoomException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create the room. Check your connection and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

class _NewRoomDetails {
  const _NewRoomDetails({required this.title, required this.description});

  final String title;
  final String description;
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.isJoining,
    required this.onJoin,
  });

  final DiscussionRoom room;
  final bool isJoining;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final participantLabel =
        '${room.participantCount} ${room.participantCount == 1 ? 'participant' : 'participants'}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.meeting_room_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (room.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(room.description),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isJoining ? null : onJoin,
                  child: const Text('Join'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _RoomMeta(
                  icon: Icons.people_outline,
                  label: participantLabel,
                ),
                _RoomMeta(
                  icon: Icons.person_outline,
                  label: 'Created by ${room.hostName}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomMeta extends StatelessWidget {
  const _RoomMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RoomsMessage extends StatelessWidget {
  const _RoomsMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 12),
      child: Column(
        children: [
          Icon(
            icon,
            size: 46,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
