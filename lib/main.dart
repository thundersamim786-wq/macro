import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MacroApp());
}

class MacroApp extends StatelessWidget {
  const MacroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'macro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.amber,
        useMaterial3: true,
      ),
      home: const MacroDashboard(),
    );
  }
}

class MacroDashboard extends StatefulWidget {
  const MacroDashboard({super.key});

  @override
  State<MacroDashboard> createState() => _MacroDashboardState();
}

class _MacroDashboardState extends State<MacroDashboard> with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('com.macro.automator/actions');

  bool _isAccessibilityEnabled = false;
  bool _isOverlayEnabled = false;
  int _selectedLoops = 0; // 0 = Infinite loop
  bool _antiBanJitter = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final bool acc = await _channel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
      final bool ovl = await _channel.invokeMethod<bool>('isOverlayEnabled') ?? false;
      if (mounted) {
        setState(() {
          _isAccessibilityEnabled = acc;
          _isOverlayEnabled = ovl;
        });
      }
    } on PlatformException catch (_) {}
  }

  Future<void> _startFloatingWidget() async {
    if (!_isAccessibilityEnabled || !_isOverlayEnabled) return;
    await _channel.invokeMethod('startFloatingService', {
      'loops': _selectedLoops,
      'antiBan': _antiBanJitter,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canLaunch = _isAccessibilityEnabled && _isOverlayEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('macro'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  _isOverlayEnabled ? Icons.check_circle : Icons.layers_clear,
                  color: _isOverlayEnabled ? Colors.green : Colors.amber,
                ),
                title: const Text('1. Display Over Other Apps'),
                subtitle: const Text('Allows floating controls to hover over games'),
                trailing: ElevatedButton(
                  onPressed: () => _channel.invokeMethod('openOverlaySettings'),
                  child: Text(_isOverlayEnabled ? 'Enabled' : 'Grant'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  _isAccessibilityEnabled ? Icons.check_circle : Icons.accessibility_new,
                  color: _isAccessibilityEnabled ? Colors.green : Colors.amber,
                ),
                title: const Text('2. Accessibility Service'),
                subtitle: const Text('Captures and replays your touch gestures'),
                trailing: ElevatedButton(
                  onPressed: () => _channel.invokeMethod('openAccessibilitySettings'),
                  child: Text(_isAccessibilityEnabled ? 'Enabled' : 'Enable'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Execution Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Repeat Count:', style: TextStyle(fontSize: 15)),
                        DropdownButton<int>(
                          value: _selectedLoops,
                          dropdownColor: Colors.grey[900],
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Infinite (∞)')),
                            DropdownMenuItem(value: 1, child: Text('1 Loop')),
                            DropdownMenuItem(value: 5, child: Text('5 Loops')),
                            DropdownMenuItem(value: 10, child: Text('10 Loops')),
                            DropdownMenuItem(value: 25, child: Text('25 Loops')),
                            DropdownMenuItem(value: 50, child: Text('50 Loops')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLoops = val);
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Anti-Ban Humanization'),
                      subtitle: const Text(
                        'Varies tap coordinates (±8px) and delay timings to avoid bot detection.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: _antiBanJitter,
                      onChanged: (val) => setState(() => _antiBanJitter = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                icon: const Icon(Icons.touch_app),
                label: const Text(
                  'Launch Floating Recorder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: canLaunch ? _startFloatingWidget : null,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Workflow:\n1. Open your game.\n2. Tap "● REC" on the floating bar and tap your actions normally.\n3. Tap "■ STOP" when done.\n4. Tap "▶ PLAY" to replay the recorded commands continuously.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
