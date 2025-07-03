import 'package:flutter/material.dart';

class VehiculoDetalleScreen extends StatelessWidget {
  final Map vehiculo;

  VehiculoDetalleScreen({required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(vehiculo['nombre']),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoCard(
              icon: Icons.directions_car,
              title: "Nombre del vehículo",
              value: vehiculo['nombre'],
              color: Colors.blueAccent,
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.confirmation_number,
              title: "Placa",
              value: vehiculo['placa'],
              color: Colors.indigo,
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.build_circle,
              title: "Estado",
              value: vehiculo['estado'],
              color: vehiculo['estado'] == 'Funcional' ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
