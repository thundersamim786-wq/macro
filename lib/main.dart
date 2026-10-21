import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MacroAutoApp());
}

class MacroAutoApp extends StatelessWidget {
  const MacroAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macro Touch Automator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MacroHomePage(),
    );
  }
}

class MacroHomePage extends StatefulWidget {
  const MacroHomePage({super.key});

  @override
  State<MacroHomePage> createState() => _MacroHomePageState();
}

class _MacroHomePageState extends State<MacroHomePage> {
  static const MethodChannel _platform = MethodChannel('com.macro.automator/actions');

  bool _isAccessibilityEnabled = false;
  bool _isRecording = false;
  final List<Offset> _recordedPoints = [];

  @override
  void initState() {
    super.initState();
    _checkAccessibilityPermission();
  }

  Future<void> _checkAccessibilityPermission() async {
    try {
      final bool? enabled = await _platform.invokeMethod<bool>('isAccessibilityEnabled');
      if (mounted) {
        setState(() {
          _isAccessibilityEnabled = enabled ?? false;
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _isAccessibilityEnabled = false;
        });
      }
    }
  }

  Future<void> _openAccessibilitySettings() async {
    await _platform.invokeMethod('openAccessibilitySettings');
  }

  Future<void> _enterPipMode() async {
    try {
      await _platform.invokeMethod('enterPip');
    } on PlatformException catch (e) {
      debugPrint('Error entering PiP: ${e.message}');
    }
  }

  Future<void> _playMacro() async {
    if (_recordedPoints.isEmpty) return;

    for (final point in _recordedPoints) {
      await _platform.invokeMethod('dispatchTap', {
        'x': point.dx,
        'y': point.dy,
      });
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPip = MediaQuery.of(context).size.width < 250;

    if (isPip) {
      return Scaffold(
        body: Center(
          child: IconButton(
            iconSize: 40,
            icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
            onPressed: _playMacro,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Macro Action Runner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt),
            tooltip: 'Enter PiP',
            onPressed: _enterPipMode,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  _isAccessibilityEnabled ? Icons.check_circle : Icons.warning,
                  color: _isAccessibilityEnabled ? Colors.green : Colors.amber,
                ),
                title: const Text('Accessibility Service'),
                subtitle: Text(
                  _isAccessibilityEnabled
                      ? 'Enabled and ready to dispatch gestures'
                      : 'Required to automate screen clicks',
                ),
                trailing: ElevatedButton(
                  onPressed: _openAccessibilitySettings,
                  child: const Text('Configure'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (_isRecording) {
                    setState(() {
                      _recordedPoints.add(details.localPosition);
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black12,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          _isRecording
                              ? 'Tap anywhere to record coordinates\nPoints: ${_recordedPoints.length}'
                              : 'Tap "Record Action" to start',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      ..._recordedPoints.map(
                        (p) => Positioned(
                          left: p.dx - 12,
                          top: p.dy - 12,
                          child: const Icon(
                            Icons.adjust,
                            color: Colors.deepPurpleAccent,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                    label: Text(_isRecording ? 'Stop Recording' : 'Record Action'),
                    onPressed: () {
                      setState(() {
                        if (!_isRecording) _recordedPoints.clear();
                        _isRecording = !_isRecording;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Macro'),
                    onPressed: _recordedPoints.isEmpty ? null : _playMacro,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
