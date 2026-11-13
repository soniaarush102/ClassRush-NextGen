import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/discussion_room_repository.dart';

enum _MeetingMode { whiteboard, presentation }

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
  });

  final String roomId;
  final String roomTitle;

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final _repository = DiscussionRoomRepository();
  final List<List<Offset>> _strokes = [];
  _MeetingMode _mode = _MeetingMode.whiteboard;
  bool _isLeaving = false;

  String get _myName {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'You';
  }

  Future<void> _leaveMeeting() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);
    try {
      await _repository.leaveRoom(widget.roomId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not leave the room. Please try again.')),
      );
      setState(() => _isLeaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton.icon(
            onPressed: _isLeaving ? null : _leaveMeeting,
            icon: const Icon(Icons.call_end_rounded),
            label: Text(_isLeaving ? 'Leaving…' : 'Leave'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                child: Column(
                  children: [
                    _modeSelector(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _mode == _MeetingMode.whiteboard
                          ? _whiteboard()
                          : _presentation(),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              flex: 3,
              child: _participantsPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSelector() {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<_MeetingMode>(
            segments: const [
              ButtonSegment(
                value: _MeetingMode.whiteboard,
                icon: Icon(Icons.draw_outlined),
                label: Text('Whiteboard'),
              ),
              ButtonSegment(
                value: _MeetingMode.presentation,
                icon: Icon(Icons.slideshow_outlined),
                label: Text('PPT'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _whiteboard() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Undo last stroke',
              onPressed: _strokes.isEmpty
                  ? null
                  : () => setState(() => _strokes.removeLast()),
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              tooltip: 'Clear board',
              onPressed: _strokes.isEmpty
                  ? null
                  : () => setState(_strokes.clear),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            const Spacer(),
            const Text('Whiteboard'),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (details) {
                  final point = _normalise(details.localPosition, size);
                  setState(() => _strokes.add([point]));
                },
                onPanUpdate: (details) {
                  if (_strokes.isEmpty) return;
                  final point = _normalise(details.localPosition, size);
                  setState(() => _strokes.last.add(point));
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: _BoardPainter(
                      strokes: _strokes,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your drawing is currently on this device only. Shared live drawing is a later integration step.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Offset _normalise(Offset point, Size size) {
    if (size.width <= 0 || size.height <= 0) return Offset.zero;
    return Offset(
      (point.dx / size.width).clamp(0.0, 1.0).toDouble(),
      (point.dy / size.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  Widget _presentation() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.slideshow_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text('Presentation workspace',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'PPT and PDF upload, slide navigation and shared presentation controls will be added in the next stage.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _participantsPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Participants',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off_outlined,
                            size: 30,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 6),
                        Text(
                          'Camera not connected',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        _myName.isEmpty ? '?' : _myName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_myName (you)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Video and microphone calling will be connected after a real-time call provider is configured.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final points = stroke
          .map((point) => Offset(point.dx * size.width, point.dy * size.height))
          .toList();
      if (points.length == 1) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
        continue;
      }
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
