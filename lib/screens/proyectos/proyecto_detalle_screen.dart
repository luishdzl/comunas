import 'package:flutter/material.dart';

class ProyectoDetalleScreen extends StatelessWidget {
  final Map proyecto;

  ProyectoDetalleScreen({required this.proyecto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(proyecto['nombre']),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoCard(
              icon: Icons.assignment,
              title: "Nombre del proyecto",
              value: proyecto['nombre'],
              color: Colors.blueAccent,
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.location_on,
              title: "Dirección",
              value: proyecto['direccion'],
              color: Colors.green,
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.assignment_turned_in,
              title: "Cantidad de proyectos",
              value: proyecto['proyectos'].toString(),
              color: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required Color color}) {
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
