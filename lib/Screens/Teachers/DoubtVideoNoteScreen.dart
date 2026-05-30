import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../../../servcies.dart';

enum _ToolMode { pen, eraser, move }

class DoubtVideoNoteScreen extends StatefulWidget {
  const DoubtVideoNoteScreen({super.key});

  @override
  State<DoubtVideoNoteScreen> createState() => _DoubtVideoNoteScreenState();
}

class _DoubtVideoNoteScreenState extends State<DoubtVideoNoteScreen> {
  static const double _canvasExtent = 5000;
  final _FastBoardController _board = _FastBoardController();
  final TransformationController _transformController =
      TransformationController();

  bool _isRecording = false;
  bool _isBusy = false;
  double _strokeWidth = 4;
  Color _activeColor = Colors.black;
  _ToolMode _toolMode = _ToolMode.pen;

  final List<Color> _palette = const [
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    // Disable secure flag while recording, otherwise captured video can be black.
    SecureScreen.disable();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _board.setStyle(_activeColor, _strokeWidth);
  }

  @override
  void dispose() {
    _transformController.dispose();
    // Restore app secure flag and default orientation policy.
    SecureScreen.enable();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _setDrawingStyle({Color? color, double? width}) {
    if (color != null) _activeColor = color;
    if (width != null) _strokeWidth = width;
    _board.setStyle(_activeColor, _strokeWidth);
    setState(() {});
  }

  void _onPanStart(DragStartDetails details) {
    if (_toolMode == _ToolMode.move) return;
    final point = details.localPosition;
    _board.beginStroke(
      point: point,
      eraser: _toolMode == _ToolMode.eraser,
      eraserWidth: max(_strokeWidth * 2.2, 8),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_toolMode == _ToolMode.move) return;
    final point = details.localPosition;
    _board.addPoint(point);
  }

  void _onPanEnd() {
    if (_toolMode == _ToolMode.move) return;
    _board.endStroke();
  }

  Future<bool> _requestRecordingPermissions() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      final hasPermissions = await _requestRecordingPermissions();
      if (!hasPermissions) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission is required")),
        );
        return;
      }

      bool started = await FlutterScreenRecording.startRecordScreenAndAudio(
        "doubt_video_${DateTime.now().millisecondsSinceEpoch}",
        titleNotification: "Doubt video recording",
        messageNotification: "Recording with voice",
      );

      if (!started) {
        // Fallback when voice recording init fails on some devices.
        started = await FlutterScreenRecording.startRecordScreen(
          "doubt_video_${DateTime.now().millisecondsSinceEpoch}",
          titleNotification: "Doubt video recording",
          messageNotification: "Recording in progress",
        );
      }

      if (!mounted) return;
      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Unable to start recording. Allow full app capture and permissions.",
            ),
          ),
        );
      }
      setState(() {
        _isRecording = started;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to start recording")),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _stopAndAttach() async {
    if (!_isRecording || _isBusy) return;
    setState(() => _isBusy = true);

    try {
      final String path = await FlutterScreenRecording.stopRecordScreen;
      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      if (path.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recording failed. Try again.")),
        );
        return;
      }

      final approved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _RecordedVideoPreviewScreen(videoPath: path),
        ),
      );

      if (!mounted) return;
      if (approved == true) {
        Navigator.pop(context, path);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to stop recording")));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: (_) => _onPanEnd(),
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(2000),
                    minScale: 0.3,
                    maxScale: 4.0,
                    panEnabled: _toolMode == _ToolMode.move,
                    scaleEnabled: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: (_) => _onPanEnd(),
                      child: SizedBox(
                        width: _canvasExtent,
                        height: _canvasExtent,
                        child: CustomPaint(
                          painter: _FastBoardPainter(
                            board: _board,
                            repaint: _board,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            "Doubt Video Board",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _toolChip(
                          "Pen",
                          _toolMode == _ToolMode.pen,
                          () => setState(() => _toolMode = _ToolMode.pen),
                        ),
                        const SizedBox(width: 6),
                        _toolChip(
                          "Eraser",
                          _toolMode == _ToolMode.eraser,
                          () => setState(() => _toolMode = _ToolMode.eraser),
                        ),
                        const SizedBox(width: 6),
                        _toolChip(
                          "Move",
                          _toolMode == _ToolMode.move,
                          () => setState(() => _toolMode = _ToolMode.move),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final color in _palette)
                          GestureDetector(
                            onTap: () {
                              setState(() => _toolMode = _ToolMode.pen);
                              _setDrawingStyle(color: color);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              height: 26,
                              width: 26,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      _activeColor == color
                                          ? Colors.white
                                          : Colors.white54,
                                  width: _activeColor == color ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Slider(
                            value: _strokeWidth,
                            min: 2,
                            max: 14,
                            divisions: 12,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white54,
                            onChanged: (v) => _setDrawingStyle(width: v),
                          ),
                        ),
                        Text(
                          _strokeWidth.toInt().toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _isBusy ? null : _board.clear,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: const Text("Clear"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: ElevatedButton.icon(
                onPressed:
                    _isBusy
                        ? null
                        : (_isRecording ? _stopAndAttach : _startRecording),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                ),
                label: Text(
                  _isRecording ? "Stop & Preview" : "Start Recording",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white54),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _Stroke {
  _Stroke({required this.color, required this.width, required this.points});

  final Color color;
  final double width;
  final List<Offset> points;
}

class _FastBoardController extends ChangeNotifier {
  final List<_Stroke> strokes = [];
  _Stroke? _active;
  Color _color = Colors.black;
  double _width = 4;
  int _lastNotifyMs = 0;

  void setStyle(Color color, double width) {
    _color = color;
    _width = width;
  }

  void beginStroke({
    required Offset point,
    required bool eraser,
    required double eraserWidth,
  }) {
    final stroke = _Stroke(
      color: eraser ? Colors.white : _color,
      width: eraser ? eraserWidth : _width,
      points: [point],
    );
    _active = stroke;
    strokes.add(stroke);
    notifyListeners();
  }

  void addPoint(Offset point) {
    final stroke = _active;
    if (stroke == null) return;
    final last = stroke.points.isNotEmpty ? stroke.points.last : null;
    if (last != null && _distance(last, point) < 1.4) return;
    stroke.points.add(point);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNotifyMs >= 8) {
      _lastNotifyMs = now;
      notifyListeners();
    }
  }

  void endStroke() {
    _active = null;
    _lastNotifyMs = 0;
    notifyListeners();
  }

  void clear() {
    strokes.clear();
    notifyListeners();
  }

  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
  }
}

class _FastBoardPainter extends CustomPainter {
  const _FastBoardPainter({required this.board, super.repaint});

  final _FastBoardController board;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in board.strokes) {
      if (stroke.points.isEmpty) continue;
      final paint =
          Paint()
            ..color = stroke.color
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = stroke.width
            ..style = PaintingStyle.stroke
            ..isAntiAlias = false;

      if (stroke.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
        continue;
      }

      final path =
          Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FastBoardPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}

class _RecordedVideoPreviewScreen extends StatefulWidget {
  const _RecordedVideoPreviewScreen({required this.videoPath});

  final String videoPath;

  @override
  State<_RecordedVideoPreviewScreen> createState() =>
      _RecordedVideoPreviewScreenState();
}

class _RecordedVideoPreviewScreenState
    extends State<_RecordedVideoPreviewScreen> {
  late final VideoPlayerController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.setVolume(1.0);
        _controller.play();
        setState(() => _loading = false);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview Video"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child:
                  _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.replay),
                    label: const Text("Retake"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check),
                    label: const Text("Use Video"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IconButton(
              onPressed: () {
                if (_loading) return;
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              icon: Icon(
                _loading || _controller.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
