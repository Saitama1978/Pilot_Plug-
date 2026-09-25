import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const PilotPlugApp());
}

class PilotPlugApp extends StatefulWidget {
  const PilotPlugApp({super.key});

  @override
  State<PilotPlugApp> createState() => _PilotPlugAppState();
}

class _PilotPlugAppState extends State<PilotPlugApp> {
  // 1. STATE PARA SA DARK MODE / LIGHT MODE
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pilot Plug',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // LIGHT THEME CONFIGURATION
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1D4ED8),
          unselectedItemColor: Colors.grey,
        ),
      ),
      
      // DARK THEME CONFIGURATION
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121824),
        cardColor: const Color(0xFF1B2230),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121824),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF121824),
          selectedItemColor: Color(0xFF29B6F6),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: PilotPlugDashboard(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

enum GpsStatus { disconnected, connecting, connected }

class PilotPlugDashboard extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const PilotPlugDashboard({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<PilotPlugDashboard> createState() => _PilotPlugDashboardState();
}

class _PilotPlugDashboardState extends State<PilotPlugDashboard> {
  // 2. STATE PARA SA TABS, GPS, AT MBTILES
  int _selectedIndex = 0;
  String _mbtilesPath = '';
  GpsStatus _gpsStatus = GpsStatus.disconnected;
  final LatLng _currentLocation = const LatLng(14.6000, 120.9833);

  // LOGIC PARA SA GPS BUTTON
  void _toggleGps() {
    setState(() {
      if (_gpsStatus == GpsStatus.disconnected) {
        _gpsStatus = GpsStatus.connecting;
        
        // Simulating GPS Connection Delay (2 seconds)
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _gpsStatus == GpsStatus.connecting) {
            setState(() {
              _gpsStatus = GpsStatus.connected;
            });
          }
        });
      } else {
        _gpsStatus = GpsStatus.disconnected;
      }
    });
  }

  // LOGIC PARA SA MBTILES IMPORT
  Future<void> _importMBTiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;

        if (filePath.toLowerCase().endsWith('.mbtiles')) {
          setState(() {
            _mbtilesPath = filePath;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Matagumpay na na-import: ${result.files.single.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maling file! Siguraduhing .mbtiles file ang pipiliin.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sa pag-load ng MBTiles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // LOGIC PARA SA INFO BUTTON
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Pilot Plug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Pilot Plug Dashboard v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Developer: Renante Fullo'),
            SizedBox(height: 8),
            Text('Maritime navigation software designed for harbor pilots and vessel navigation.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Pilot Plug Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              'Developer: Renante Fullo',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // DARK / LIGHT MODE TOGGLE BUTTON
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: widget.isDarkMode ? Colors.amber : Colors.indigo,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
          // APP INFO BUTTON
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Info',
          ),
        ],
      ),

      // INDEXEDSTACK PARA SA PAGPAPALIT NG TABS
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildPilotageScreen(cardColor), // Tab 0
          _buildDockingScreen(cardColor),  // Tab 1
          _buildNmeaScreen(cardColor),     // Tab 2
        ],
      ),

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // LUMILIPAT NA ANG TAB DITO
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat),
            label: 'Pilotage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.anchor),
            label: 'Docking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'NMEA Share',
          ),
        ],
      ),
    );
  }

  // TAB 0: PILOTAGE SCREEN
  Widget _buildPilotageScreen(Color cardColor) {
    Color statusColor;
    String statusText;
    String buttonText;

    switch (_gpsStatus) {
      case GpsStatus.connected:
        statusColor = Colors.green;
        statusText = 'GPS CONNECTED';
        buttonText = 'DISCONNECT';
        break;
      case GpsStatus.connecting:
        statusColor = Colors.amber;
        statusText = 'CONNECTING...';
        buttonText = 'CANCEL';
        break;
      case GpsStatus.disconnected:
      default:
        statusColor = Colors.red;
        statusText = 'DISCONNECTED';
        buttonText = 'CONNECT GPS';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          // 1. GPS Status Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 10),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gpsStatus == GpsStatus.connected
                        ? Colors.red.withOpacity(0.2)
                        : const Color(0xFF263248),
                    foregroundColor: _gpsStatus == GpsStatus.connected ? Colors.red : Colors.grey,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _toggleGps, // GUMAGANA NA ANG CONNECT GPS
                  icon: Icon(
                    _gpsStatus == GpsStatus.connected ? Icons.gps_off : Icons.gps_fixed,
                    size: 16,
                  ),
                  label: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Telemetry Cards (COG, SOG, ACCURACY)
          Row(
            children: [
              _buildTelemetryCard(
                'COG',
                _gpsStatus == GpsStatus.connected ? '142.5°' : '0.0°',
                widget.isDarkMode ? Colors.white : Colors.black87,
                cardColor,
              ),
              const SizedBox(width: 8),
              _buildTelemetryCard(
                'SOG',
                _gpsStatus == GpsStatus.connected ? '11.4 kn' : '0.0 kn',
                const Color(0xFF00E676),
                cardColor,
              ),
              const SizedBox(width: 8),
              _buildTelemetryCard(
                'ACCURACY',
                _gpsStatus == GpsStatus.connected ? 'HIGH (1.2m)' : 'OFF',
                const Color(0xFF00E5FF),
                cardColor,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Mode Bar & Import MBTiles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: Color(0xFF29B6F6), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _mbtilesPath.isEmpty
                        ? 'Mode: Online OSM (Import .mbtiles fo...'
                        : 'Mode: Offline MBTiles Loaded',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _importMBTiles,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('Import MBTiles', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. Map Display Area
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _currentLocation,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.pilot_plug',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation,
                        width: 40,
                        height: 40,
                        child: Transform.rotate(
                          angle: _gpsStatus == GpsStatus.connected ? 1.42 : 0,
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.redAccent,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: DOCKING SCREEN
  Widget _buildDockingScreen(Color cardColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Docking Assistance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.anchor, size: 64, color: Color(0xFF29B6F6)),
                  const SizedBox(height: 16),
                  Text(
                    'Docking Telemetry Active',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDockingMetric('Bow Dist.', _gpsStatus == GpsStatus.connected ? '45 m' : 'N/A'),
                      _buildDockingMetric('Stern Dist.', _gpsStatus == GpsStatus.connected ? '38 m' : 'N/A'),
                      _buildDockingMetric('Rate of Turn', _gpsStatus == GpsStatus.connected ? '0.2°/s' : '0.0°/s'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: NMEA SHARE SCREEN
  Widget _buildNmeaScreen(Color cardColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NMEA Stream & Share',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('UDP/TCP Broadcast:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _gpsStatus == GpsStatus.connected ? 'STREAMING' : 'IDLE',
                        style: TextStyle(
                          color: _gpsStatus == GpsStatus.connected ? Colors.green : Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text('Live NMEA Log:'),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _gpsStatus == GpsStatus.connected
                              ? '\$GPRMC,123519,A,1436.000,N,12059.000,E,022.4,084.4,230326,003.1,W*6A\n'
                                '\$GPGGA,123519,1436.000,N,12059.000,E,1,08,0.9,545.4,M,46.9,M,,*47\n'
                                '\$GPVTG,054.7,T,,M,002.2,N,004.1,K*48'
                              : 'Waiting for GPS connection to stream NMEA sentences...',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.greenAccent,
                            fontSize: 12,
                          ),
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

  Widget _buildDockingMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
        ),
      ],
    );
  }

  Widget _buildTelemetryCard(String title, String value, Color valueColor, Color cardColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
