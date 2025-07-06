import 'package:flutter/material.dart';

class VehiculoDetalleScreen extends StatelessWidget {
  final Map vehiculo;

  VehiculoDetalleScreen({required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("${vehiculo['marca']} ${vehiculo['modelo']}"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: vehiculo.entries.map((entry) {
          final key = entry.key;
          final value = entry.value?.toString() ?? '-';
          return _buildInfoCard(
            title: _formatKey(key),
            value: value,
            icon: Icons.info_outline,
            color: Colors.blueAccent,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(12),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => "${match.group(1)} ${match.group(2)}"
    ).replaceAll('_', ' ').toUpperCase();
  }
}
