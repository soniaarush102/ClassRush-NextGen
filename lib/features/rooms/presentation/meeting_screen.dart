import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

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
  List<Offset> _activeStroke = [];
  Offset? _strokeStart;
  String _boardTool = 'Pen';
  Color _penColor = Colors.black;
  _MeetingMode _mode = _MeetingMode.whiteboard;
  bool _isLeaving = false;

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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repository.watchBoardStrokes(widget.roomId),
      builder: (context, snapshot) {
        final savedStrokes = (snapshot.data ?? const <Map<String, dynamic>>[])
            .map(_decodeStroke)
            .toList();
        final allStrokes = [
          ...savedStrokes,
          if (_activeStroke.isNotEmpty)
            _BoardStroke(
              points: _activeStroke,
              color: _activeStrokeColor,
              width: _activeStrokeWidth,
            ),
        ];

        return Column(
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: _boardTool,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'Pen', child: Text('Pen')),
                    DropdownMenuItem(value: 'Highlighter', child: Text('Highlight')),
                    DropdownMenuItem(value: 'Eraser', child: Text('Eraser')),
                    DropdownMenuItem(value: 'Line', child: Text('Line')),
                    DropdownMenuItem(value: 'Rectangle', child: Text('Rectangle')),
                    DropdownMenuItem(value: 'Circle', child: Text('Circle')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _boardTool = value);
                  },
                ),
                IconButton(
                  tooltip: 'Undo last stroke',
                  onPressed: savedStrokes.isEmpty
                      ? null
                      : () async {
                          final strokes = snapshot.data!;
                          final lastId = strokes.last['id'] as String?;
                          if (lastId == null) return;
                          try {
                            await _repository.deleteBoardStroke(widget.roomId, lastId);
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not undo the last stroke.')),
                            );
                          }
                        },
                  icon: const Icon(Icons.undo_rounded),
                ),
                IconButton(
                  tooltip: 'Clear board',
                  onPressed: savedStrokes.isEmpty
                      ? null
                      : () async {
                          try {
                            await _repository.clearBoard(widget.roomId);
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not clear the board.')),
                            );
                          }
                        },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                if (_boardTool == 'Pen')
                  PopupMenuButton<Color>(
                    tooltip: 'Pen colour',
                    initialValue: _penColor,
                    onSelected: (color) => setState(() => _penColor = color),
                    itemBuilder: (context) => [
                      Colors.black,
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.purple,
                      Colors.orange,
                      Colors.teal,
                      Colors.white,
                    ].map((color) => PopupMenuItem<Color>(
                      value: color,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 9, backgroundColor: color),
                          const SizedBox(width: 10),
                          Text(_penColorName(color)),
                          if (_penColor.toARGB32() == color.toARGB32()) ...[
                            const Spacer(),
                            const Icon(Icons.check, size: 16),
                          ],
                        ],
                      ),
                    )).toList(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.palette_outlined, color: _penColor),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                const Spacer(),
                const Text('Shared Whiteboard'),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _strokeStart = _normalise(details.localPosition, size);
                        _activeStroke = [_strokeStart!];
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        final current = _normalise(details.localPosition, size);
                        if (_boardTool == 'Pen' || _boardTool == 'Highlighter' || _boardTool == 'Eraser') {
                          _activeStroke.add(current);
                        } else {
                          _activeStroke = _makeToolPoints(_strokeStart!, current);
                        }
                      });
                    },
                    onPanEnd: (_) {
                      final completedStroke = List<Offset>.from(_activeStroke);
                      setState(() {
                        _activeStroke = [];
                        _strokeStart = null;
                      });
                      if (completedStroke.isNotEmpty) {
                        _saveBoardStroke(
                          completedStroke,
                          color: _activeStrokeColor,
                          width: _activeStrokeWidth,
                        );
                      }
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
                          strokes: allStrokes,
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
              snapshot.hasError
                  ? 'Could not load the shared whiteboard: ${snapshot.error}'
                  : 'Drawings sync with room members after each stroke is finished.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  List<Offset> _makeToolPoints(Offset start, Offset end) {
    if (_boardTool == 'Line') return [start, end];
    if (_boardTool == 'Rectangle') {
      return [
        start,
        Offset(end.dx, start.dy),
        end,
        Offset(start.dx, end.dy),
        start,
      ];
    }
    if (_boardTool == 'Circle') {
      final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final radiusX = (end.dx - start.dx).abs() / 2;
      final radiusY = (end.dy - start.dy).abs() / 2;
      return List.generate(49, (index) {
        final angle = index * 2 * math.pi / 48;
        return Offset(center.dx + radiusX * math.cos(angle), center.dy + radiusY * math.sin(angle));
      });
    }
    return [start, end];
  }

  String _penColorName(Color color) {
    if (color == Colors.black) return 'Black';
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.teal) return 'Teal';
    return 'White';
  }

  Color get _activeStrokeColor {
    if (_boardTool == 'Eraser') return Theme.of(context).colorScheme.surface;
    if (_boardTool == 'Highlighter') return const Color(0x66FFEB3B);
    return _penColor;
  }

  double get _activeStrokeWidth {
    if (_boardTool == 'Eraser') return 20;
    if (_boardTool == 'Highlighter') return 12;
    return 3;
  }

  _BoardStroke _decodeStroke(Map<String, dynamic> stroke) {
    final rawPoints = stroke['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((rawPoint) {
      final pair = rawPoint as List<dynamic>;
      return Offset(
        (pair[0] as num).toDouble(),
        (pair[1] as num).toDouble(),
      );
    }).toList();
    return _BoardStroke(
      points: points,
      color: Color((stroke['color'] as num?)?.toInt() ??
          Theme.of(context).colorScheme.onSurface.value),
      width: (stroke['width'] as num?)?.toDouble() ?? 3,
    );
  }

  Future<void> _saveBoardStroke(
    List<Offset> points, {
    required Color color,
    required double width,
  }) async {
    try {
      await _repository.addBoardStroke(
        widget.roomId,
        points,
        color: color.value,
        width: width,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Whiteboard sync failed (${error.code}): ${error.message ?? 'No additional details'}'),
          duration: const Duration(seconds: 12),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Whiteboard sync failed: ${error.toString().length > 180 ? error.toString().substring(0, 180) : error.toString()}'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repository.watchParticipants(widget.roomId),
      builder: (context, snapshot) {
        final participants = snapshot.data ?? const <Map<String, dynamic>>[];
        final myUid = FirebaseAuth.instance.currentUser?.uid;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Participants (${participants.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: snapshot.hasError
                    ? Center(
                        child: Text(
                          'Could not load participants.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    : !snapshot.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : participants.isEmpty
                            ? Center(
                                child: Text(
                                  'No participants yet.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              )
                            : ListView.separated(
                                itemCount: participants.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final participant = participants[index];
                                  final uid =
                                      participant['uid'] as String? ?? '';
                                  final name =
                                      participant['displayName'] as String? ??
                                          'Member';
                                  final isMe = uid == myUid;
                                  final initial =
                                      name.trim().isEmpty ? 'M' : name.trim()[0];

                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.videocam_off_outlined,
                                          size: 26,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 13,
                                              child: Text(
                                                initial.toUpperCase(),
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                isMe ? '$name (you)' : name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Camera not connected',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
              const SizedBox(height: 8),
              Text(
                'Participant list updates live. Video and microphone calling are not connected yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoardStroke {
  const _BoardStroke({
    required this.points,
    required this.color,
    required this.width,
  });

  final List<Offset> points;
  final Color color;
  final double width;
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({required this.strokes});

  final List<_BoardStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final points = stroke.points
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
