import 'package:flutter/material.dart';

void main() {
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

  final List<Widget> _pages = [
    const PilotageScreen(),
    const DockingScreen(),
    const Center(child: Text('Bridge Wing View', style: TextStyle(color: Colors.white70))),
    const Center(child: Text('Training Mode', style: TextStyle(color: Colors.white70))),
    const Center(child: Text('NMEA Testing', style: TextStyle(color: Colors.white70))),
    const Center(child: Text('Maintenance', style: TextStyle(color: Colors.white70))),
  ];

  @override
  Widget build(BuildContext context) {
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
                  Text('Live AIS, NMEA & Docking Data Viewer'),
                ],
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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

class PilotageScreen extends StatelessWidget {
  const PilotageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Header Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                    SizedBox(width: 6),
                    Text('LIVE AIS & NMEA', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text('ROT: +7.8°/min', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Telemetry Grid
          Row(
            children: [
              _buildCard('HDG', '136.0°', Colors.white),
              const SizedBox(width: 8),
              _buildCard('COG', '130.8°', Colors.white),
              const SizedBox(width: 8),
              _buildCard('SOG', '6.2 kn', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 10),

          // Map & Live Target Area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF11161D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 64, color: Colors.white24),
                        SizedBox(height: 8),
                        Text('Live AIS Map & Vector Display', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black80,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Developer: Renante Fullo', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Offline maps • No ads', style: TextStyle(color: Colors.grey, fontSize: 10)),
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
  const DockingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('DOCKING PREDICTION TOOL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 16),
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
                  _buildDockingMetric('BOW DISTANCE', '0.57 NM', Colors.redAccent),
                  _buildDockingMetric('LATERAL SPEED', '4.00 kn', Colors.greenAccent),
                  _buildDockingMetric('STERN DISTANCE', '0.12 NM', Colors.lightBlueAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Developed by Renante Fullo', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDockingMetric(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
