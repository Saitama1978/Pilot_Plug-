import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const PilotPlugApp());
}

class PilotPlugApp extends StatelessWidget {
  const PilotPlugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pilot Plug',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121824),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121824),
          elevation: 0,
        ),
      ),
      home: const PilotPlugDashboard(),
    );
  }
}

class PilotPlugDashboard extends StatefulWidget {
  const PilotPlugDashboard({super.key});

  @override
  State<PilotPlugDashboard> createState() => _PilotPlugDashboardState();
}

class _PilotPlugDashboardState extends State<PilotPlugDashboard> {
  int _selectedIndex = 0;
  String _mbtilesPath = '';
  
  // Default map position (Manila Area base sa screenshot)
  final LatLng _currentLocation = const LatLng(14.6000, 120.9833);

  // NA-FIX NA MBTILES IMPORT LOGIC (Walang PlatformException Crash)
  Future<void> _importMBTiles() async {
    try {
      // FileType.any ang gagamitin para hindi mag-crash ang FilePicker sa Android
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;

        // I-verify sa Dart code kung .mbtiles ang napiling file
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Pilot Plug Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Developer: Renante Fullo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            // 1. GPS Status Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2230),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.circle, color: Colors.amber, size: 10),
                      SizedBox(width: 8),
                      Text(
                        'CONNECTING...',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF263248),
                      foregroundColor: Colors.grey,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                    label: const Text(
                      'CONNECT GPS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Telemetry Cards (COG, SOG, ACCURACY)
            Row(
              children: [
                _buildTelemetryCard('COG', '0.0°', Colors.white),
                const SizedBox(width: 8),
                _buildTelemetryCard('SOG', '0.0 kn', const Color(0xFF00E676)),
                const SizedBox(width: 8),
                _buildTelemetryCard('ACCURACY', 'OFF', const Color(0xFF00E5FF)),
              ],
            ),
            const SizedBox(height: 10),

            // 3. Mode Bar & Import MBTiles Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2230),
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
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
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

            // 4. Map Display Area (Dark Styled Map with Vessel Position)
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
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.redAccent,
                            size: 32,
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
      ),

      // 5. Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF121824),
        selectedItemColor: const Color(0xFF29B6F6),
        unselectedItemColor: Colors.grey,
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

  Widget _buildTelemetryCard(String title, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2230),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
