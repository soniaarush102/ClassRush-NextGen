import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class OpenRoomsScreen extends StatefulWidget {
  const OpenRoomsScreen({super.key});

  @override
  State<OpenRoomsScreen> createState() => _OpenRoomsScreenState();
}

class _OpenRoomsScreenState extends State<OpenRoomsScreen> {
  final _searchController = TextEditingController();
  String _selectedTopic = 'All topics';

  final List<_DiscussionRoom> _rooms = [
    _DiscussionRoom(
      title: 'Number Theory: Modular Arithmetic',
      topic: 'Number Theory',
      description: 'Explore congruences, remainders and clever olympiad tricks.',
      participants: 4,
      level: 'Olympiad',
      host: 'Maths Explorer',
    ),
    _DiscussionRoom(
      title: 'Geometry Problem-Solving Corner',
      topic: 'Geometry',
      description: 'Bring a geometry problem and work through it together.',
      participants: 3,
      level: 'All levels',
      host: 'Euclid Club',
    ),
    _DiscussionRoom(
      title: 'Combinatorics: Counting Challenges',
      topic: 'Combinatorics',
      description: 'Discuss counting strategies, invariants and constructions.',
      participants: 5,
      level: 'Olympiad',
      host: 'Counting Crew',
    ),
    _DiscussionRoom(
      title: 'Algebra Practice and Ideas',
      topic: 'Algebra',
      description: 'Share approaches to equations, inequalities and polynomials.',
      participants: 2,
      level: 'All levels',
      host: 'Algebra Circle',
    ),
  ];

  static const _topics = [
    'All topics',
    'Number Theory',
    'Geometry',
    'Combinatorics',
    'Algebra',
  ];

  List<_DiscussionRoom> get _visibleRooms {
    final query = _searchController.text.trim().toLowerCase();
    return _rooms.where((room) {
      final matchesTopic =
          _selectedTopic == 'All topics' || room.topic == _selectedTopic;
      final matchesSearch = query.isEmpty ||
          room.title.toLowerCase().contains(query) ||
          room.description.toLowerCase().contains(query) ||
          room.topic.toLowerCase().contains(query);
      return matchesTopic && matchesSearch;
    }).toList();
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
        title: const Text('Open discussion rooms'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _showCreateRoomDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create room'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(compact ? 16 : 32, 20, compact ? 16 : 32, 32),
        children: [
          Text(
            'Find your maths discussion',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an open room, meet other maths enthusiasts and solve problems together.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search topics or room names',
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topics.map((topic) {
              return ChoiceChip(
                label: Text(topic),
                selected: _selectedTopic == topic,
                onSelected: (_) => setState(() => _selectedTopic = topic),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '${_visibleRooms.length} open rooms',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              const Icon(Icons.circle, color: Colors.green, size: 9),
              const SizedBox(width: 6),
              Text(
                'Open to join',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_visibleRooms.isEmpty)
            _EmptyRooms(onCreate: _showCreateRoomDialog)
          else
            ..._visibleRooms.map(
              (room) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RoomCard(room: room, onJoin: () => _joinRoom(room)),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Room discovery preview · Rooms are sample data until a backend is connected.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  void _joinRoom(_DiscussionRoom room) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Join flow for "${room.title}" will connect when rooms are online.'),
      ),
    );
  }

  Future<void> _showCreateRoomDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String topic = 'Number Theory';

    final created = await showDialog<_DiscussionRoom>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create a discussion room'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Room name',
                      hintText: 'e.g. RMO Geometry Discussion',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: topic,
                    decoration: const InputDecoration(labelText: 'Maths topic'),
                    items: _topics.skip(1).map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => topic = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'What will you discuss?',
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
                  _DiscussionRoom(
                    title: title,
                    topic: topic,
                    description: descriptionController.text.trim().isEmpty
                        ? 'An open maths discussion. Join and share your ideas.'
                        : descriptionController.text.trim(),
                    participants: 1,
                    level: 'All levels',
                    host: 'You',
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    descriptionController.dispose();

    if (created != null && mounted) {
      setState(() => _rooms.insert(0, created));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room added to this preview. Online room creation needs a backend.'),
        ),
      );
    }
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onJoin});

  final _DiscussionRoom room;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
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
                    color: AppTheme.brandOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.forum_rounded, color: AppTheme.brandOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 5),
                      Text(room.description),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onJoin,
                  child: const Text('Join'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _RoomMeta(icon: Icons.category_outlined, label: room.topic),
                _RoomMeta(icon: Icons.people_outline, label: '${room.participants} participants'),
                _RoomMeta(icon: Icons.school_outlined, label: room.level),
                _RoomMeta(icon: Icons.person_outline, label: 'Started by ${room.host}'),
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
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 46, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('No rooms match your search.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create a room'),
          ),
        ],
      ),
    );
  }
}

class _DiscussionRoom {
  const _DiscussionRoom({
    required this.title,
    required this.topic,
    required this.description,
    required this.participants,
    required this.level,
    required this.host,
  });

  final String title;
  final String topic;
  final String description;
  final int participants;
  final String level;
  final String host;
}
