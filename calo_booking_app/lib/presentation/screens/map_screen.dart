import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  final Function(int) onNavChange;

  const MapScreen({super.key, required this.onNavChange});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ'),
        backgroundColor: const Color(0xFF016D3B),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Bản đồ sân cầu lông',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chức năng sắp phát hành',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF016D3B),
        selectedItemColor: const Color(0xFFD4A820),
        unselectedItemColor: Colors.white70,
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          widget.onNavChange(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: 'Bản đồ'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications),
            label: 'Nổi bật',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
