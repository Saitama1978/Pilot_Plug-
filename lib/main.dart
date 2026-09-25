import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PilotPlugApp());
}

class PilotPlugApp extends StatelessWidget {
  const PilotPlugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pilot Plug App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        cardColor: const Color(0xFF161B22),
        primaryColor: Colors.blueAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF161B22),
        ),
        useMaterial3: true,
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  // Real-time / Editable Docking Parameters
  double bowDistance = 0.57;
  double lateralSpeed = 4.00;
  double sternDistance = 0.12;

  void _updateDockingData(double bow, double speed, double stern) {
    setState(() {
      bowDistance = bow;
      lateralSpeed = speed;
      sternDistance = stern;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const PilotageScreen(),
      DockingScreen(
        bowDistance: bowDistance,
        lateralSpeed: lateralSpeed,
        sternDistance: sternDistance,
        onUpdate: _updateDockingData,
      ),
      const BridgeWingScreen(),
      const TrainingScreen(),
      const TestingScreen(),
      const MaintenanceScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Row(
          children: [
            Icon(Icons.navigation_outlined, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Pilot Plug Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Pilot Plug App',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.anchor, size: 40, color: Colors.blueAccent),
                children: const [
                  SizedBox(height: 10),
                  Text('Developer: Renante Fullo', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Live AIS, NMEA & GPS Data Viewer'),
                ],
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_boat), label: 'Pilotage'),
          BottomNavigationBarItem(icon: Icon(Icons.anchor), label: 'Docking'),
          BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye), label: 'Bridge wing'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Training'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Testing'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Maintenance'),
        ],
      ),
    );
  }
}

class PilotageScreen extends StatefulWidget {
  const PilotageScreen({super.key});

  @override
  State<PilotageScreen> createState() => _PilotageScreenState();
}

class _PilotageScreenState extends State<PilotageScreen> {
  LatLng _currentPosition = const LatLng(14.5995, 120.9842);
  double _speedKnots = 0.0;
  double _heading = 0.0;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initGPS();
  }

  Future<void> _initGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _speedKnots = position.speed * 1.94384;
          _heading = position.heading;
          _isLoading = false;
        });

        _mapController.move(_currentPosition, _mapController.camera.zoom);
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: _isLoading ? Colors.amber : Colors.greenAccent, size: 10),
                    const SizedBox(width: 6),
                    Text(
                      _isLoading ? 'ACQUIRING GPS...' : 'MOBILE GPS ACTIVE',
                      style: TextStyle(
                        color: _isLoading ? Colors.amber : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  'LAT: ${_currentPosition.latitude.toStringAsFixed(4)}°',
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildCard('COG', '${_heading.toStringAsFixed(1)}°', Colors.white),
              const SizedBox(width: 8),
              _buildCard('SOG', '${_speedKnots.toStringAsFixed(1)} kn', Colors.greenAccent),
              const SizedBox(width: 8),
              _buildCard('ACCURACY', 'HIGH', Colors.cyanAccent),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.pilotplug.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 50,
                            height: 50,
                            child: Transform.rotate(
                              angle: (_heading * (3.141592653589793 / 180)),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.redAccent,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Developer: Renante Fullo', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            '${_currentPosition.latitude.toStringAsFixed(5)}°N, ${_currentPosition.longitude.toStringAsFixed(5)}°E',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class DockingScreen extends StatelessWidget {
  final double bowDistance;
  final double lateralSpeed;
  final double sternDistance;
  final Function(double, double, double) onUpdate;

  const DockingScreen({
    super.key,
    required this.bowDistance,
    required this.lateralSpeed,
    required this.sternDistance,
    required this.onUpdate,
  });

  void _showEditDialog(BuildContext context) {
    final bowController = TextEditingController(text: bowDistance.toStringAsFixed(2));
    final speedController = TextEditingController(text: lateralSpeed.toStringAsFixed(2));
    final sternController = TextEditingController(text: sternDistance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: const Text('Edit Docking Parameters', style: TextStyle(color: Colors.blueAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bowController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Bow Distance (NM)', labelStyle: TextStyle(color: Colors.grey)),
              ),
              TextField(
                controller: speedController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Lateral Speed (kn)', labelStyle: TextStyle(color: Colors.grey)),
              ),
              TextField(
                controller: sternController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Stern Distance (NM)', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final bow = double.tryParse(bowController.text) ?? bowDistance;
                final speed = double.tryParse(speedController.text) ?? lateralSpeed;
                final stern = double.tryParse(sternController.text) ?? sternDistance;
                onUpdate(bow, speed, stern);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DOCKING PREDICTION TOOL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                onPressed: () => _showEditDialog(context),
                tooltip: 'Manual Edit Values',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDockingMetric('BOW DISTANCE', '${bowDistance.toStringAsFixed(2)} NM', Colors.redAccent),
                  _buildDockingMetric('LATERAL SPEED', '${lateralSpeed.toStringAsFixed(2)} kn', Colors.greenAccent),
                  _buildDockingMetric('STERN DISTANCE', '${sternDistance.toStringAsFixed(2)} NM', Colors.lightBlueAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Developed by Renante Fullo • Tap ✏️ to edit values', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDockingMetric(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class BridgeWingScreen extends StatelessWidget {
  const BridgeWingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Bridge Wing View', style: TextStyle(color: Colors.white70)));
  }
}

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Training Mode', style: TextStyle(color: Colors.white70)));
  }
}

class TestingScreen extends StatelessWidget {
  const TestingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('NMEA & GPS Stream Tester', style: TextStyle(color: Colors.amberAccent)));
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('System Maintenance', style: TextStyle(color: Colors.white54)));
  }
}
