import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PilotPlugApp());
}

class PilotPlugApp extends StatefulWidget {
  const PilotPlugApp({super.key});

  @override
  State<PilotPlugApp> createState() => _PilotPlugAppState();
}

class _PilotPlugAppState extends State<PilotPlugApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pilot Plug App',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardColor: Colors.white,
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
        ),
        colorScheme: const ColorScheme.light(
          primary: Colors.blueAccent,
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        cardColor: const Color(0xFF161B22),
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161B22),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF161B22),
        ),
        useMaterial3: true,
      ),
      home: MainDashboard(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainDashboard({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

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
      PilotageScreen(isDarkMode: widget.isDarkMode),
      DockingScreen(
        bowDistance: bowDistance,
        lateralSpeed: lateralSpeed,
        sternDistance: sternDistance,
        onUpdate: _updateDockingData,
      ),
      const NmeaBroadcasterScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.navigation_outlined, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('Pilot Plug Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('Developer: Renante Fullo', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: widget.onToggleTheme,
          ),
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
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_boat), label: 'Pilotage'),
          BottomNavigationBarItem(icon: Icon(Icons.anchor), label: 'Docking'),
          BottomNavigationBarItem(icon: Icon(Icons.wifi_tethering), label: 'NMEA Share'),
        ],
      ),
    );
  }
}

class PilotageScreen extends StatefulWidget {
  final bool isDarkMode;

  const PilotageScreen({super.key, required this.isDarkMode});

  @override
  State<PilotageScreen> createState() => _PilotageScreenState();
}

class _PilotageScreenState extends State<PilotageScreen> {
  LatLng _currentPosition = const LatLng(14.5995, 120.9842);
  double _speedKnots = 0.0;
  double _heading = 0.0;
  bool _isConnected = false;
  bool _isConnecting = false;
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  Future<void> _toggleGPSConnection() async {
    if (_isConnected) {
      await _positionStream?.cancel();
      _positionStream = null;
      setState(() {
        _isConnected = false;
        _isConnecting = false;
      });
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Naka-OFF ang GPS ng Phone. Paki-turn ON ang Location Services.')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _isConnecting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kailangan ang GPS Permission para sa app.')),
          );
        }
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _speedKnots = position.speed * 1.94384;
          _heading = position.heading;
          _isConnected = true;
          _isConnecting = false;
        });
        _mapController.move(_currentPosition, 14.0);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
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
          _isConnected = true;
          _isConnecting = false;
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
    final cardBgColor = Theme.of(context).cardColor;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: _isConnected
                          ? Colors.greenAccent
                          : (_isConnecting ? Colors.amber : Colors.redAccent),
                      size: 10,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnected
                          ? 'GPS CONNECTED'
                          : (_isConnecting ? 'CONNECTING...' : 'DISCONNECTED'),
                      style: TextStyle(
                        color: _isConnected
                            ? Colors.greenAccent
                            : (_isConnecting ? Colors.amber : Colors.redAccent),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _toggleGPSConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.red.withOpacity(0.8) : Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: Icon(_isConnected ? Icons.power_settings_new : Icons.gps_fixed, size: 16),
                  label: Text(
                    _isConnected ? 'DISCONNECT' : 'CONNECT GPS',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildCard('COG', '${_heading.toStringAsFixed(1)}°', Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white, cardBgColor),
              const SizedBox(width: 8),
              _buildCard('SOG', '${_speedKnots.toStringAsFixed(1)} kn', Colors.greenAccent, cardBgColor),
              const SizedBox(width: 8),
              _buildCard('ACCURACY', _isConnected ? 'HIGH' : 'OFF', Colors.cyanAccent, cardBgColor),
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
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.pilotplug.app',
                        tileBuilder: widget.isDarkMode
                            ? (context, tileWidget, tile) {
                                return ColorFiltered(
                                  colorFilter: const ColorFilter.matrix(<double>[
                                    -0.2126, -0.7152, -0.0722, 0, 255,
                                    -0.2126, -0.7152, -0.0722, 0, 255,
                                    -0.2126, -0.7152, -0.0722, 0, 255,
                                    0,       0,       0,       1, 0,
                                  ]),
                                  child: tileWidget,
                                );
                              }
                            : null,
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
                        color: widget.isDarkMode ? Colors.black87 : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${_currentPosition.latitude.toStringAsFixed(5)}°N, ${_currentPosition.longitude.toStringAsFixed(5)}°E',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.cyanAccent : Colors.blueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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

  static Widget _buildCard(String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
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
          backgroundColor: Theme.of(context).cardColor,
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
    final cardBgColor = Theme.of(context).cardColor;

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
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
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
          const Text('Tap ✏️ icon on top right to edit values', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

class NmeaBroadcasterScreen extends StatefulWidget {
  const NmeaBroadcasterScreen({super.key});

  @override
  State<NmeaBroadcasterScreen> createState() => _NmeaBroadcasterScreenState();
}

class _NmeaBroadcasterScreenState extends State<NmeaBroadcasterScreen> {
  bool _isBroadcasting = false;
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  String _lastNmeaSentence = "No data transmitted yet.";
  final int _port = 10110;
  StreamSubscription<Position>? _positionStream;

  void _toggleBroadcasting(bool value) async {
    if (value) {
      try {
        _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
        setState(() {
          _isBroadcasting = true;
        });

        _serverSocket?.listen((Socket client) {
          setState(() {
            _clients.add(client);
          });

          client.done.then((_) {
            setState(() {
              _clients.remove(client);
            });
          });
        });

        _startNmeaStream();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start TCP Server: $e')),
          );
        }
      }
    } else {
      _stopBroadcasting();
    }
  }

  void _startNmeaStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      String nmea = _generateGPRMC(position);
      if (mounted) {
        setState(() {
          _lastNmeaSentence = nmea;
        });
      }

      for (var client in _clients) {
        client.write('$nmea\r\n');
      }
    });
  }

  void _stopBroadcasting() {
    _positionStream?.cancel();
    for (var client in _clients) {
      client.close();
    }
    _clients.clear();
    _serverSocket?.close();
    if (mounted) {
      setState(() {
        _isBroadcasting = false;
      });
    }
  }

  String _generateGPRMC(Position pos) {
    final now = DateTime.now().toUtc();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.00";
    final dateStr = "${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}";

    final latDeg = pos.latitude.abs().floor();
    final latMin = ((pos.latitude.abs() - latDeg) * 60).toStringAsFixed(4).padLeft(7, '0');
    final latDir = pos.latitude >= 0 ? 'N' : 'S';

    final lonDeg = pos.longitude.abs().floor();
    final lonMin = ((pos.longitude.abs() - lonDeg) * 60).toStringAsFixed(4).padLeft(7, '0');
    final lonDir = pos.longitude >= 0 ? 'E' : 'W';

    final speedKnots = (pos.speed * 1.94384).toStringAsFixed(1);
    final heading = pos.heading.toStringAsFixed(1);

    String body = "GPRMC,$timeStr,A,${latDeg.toString().padLeft(2, '0')}$latMin,$latDir,${lonDeg.toString().padLeft(3, '0')}$lonMin,$lonDir,$speedKnots,$heading,$dateStr,,";
    
    int checksum = 0;
    for (int i = 0; i < body.length; i++) {
      checksum ^= body.codeUnitAt(i);
    }

    return "\$$body*${checksum.toRadixString(16).toUpperCase().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _stopBroadcasting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardBgColor = Theme.of(context).cardColor;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NMEA BROADCASTER FOR OPENCPN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TCP NMEA Server', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Port: $_port • Clients Connected: ${_clients.length}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Switch(
                  value: _isBroadcasting,
                  onChanged: _toggleBroadcasting,
                  activeColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('LIVE SENTENCE TRANSMITTED:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Text(
              _lastNmeaSentence,
              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          const Text('OPENCPN CONNECTION GUIDE:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  '1. Ikonekta ang Laptop/PC sa Mobile Hotspot ng Cellphone mo.\n'
                  '2. Sa OpenCPN: Pumunta sa Options ⚙️ -> Connections -> Add Connection.\n'
                  '3. Network Type: TCP\n'
                  '4. Address: IP Address ng Cellphone (e.g. 192.168.43.1)\n'
                  '5. DataPort: 10110\n'
                  '6. I-click ang Apply / OK. Lalabas na ang real-time GPS position ng phone mo sa OpenCPN!',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
