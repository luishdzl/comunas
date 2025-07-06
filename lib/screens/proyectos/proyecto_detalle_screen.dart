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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoCard(
            icon: Icons.assignment,
            title: "Nombre",
            value: proyecto['nombre'],
            color: Colors.blueAccent,
          ),
          _buildInfoCard(
            icon: Icons.check_circle,
            title: "Estado",
            value: proyecto['status'],
            color: proyecto['status'] == 'activo'
                ? Colors.green
                : Colors.orange,
          ),
          _buildInfoCard(
            icon: Icons.date_range,
            title: "Fecha de creación",
            value: proyecto['fechaCreacion'].toString().split('T')[0],
            color: Colors.indigo,
          ),
          _buildInfoCard(
            icon: Icons.update,
            title: "Última actividad",
            value: proyecto['ultimaActividad'].toString().split('T')[0],
            color: Colors.teal,
          ),
          _buildInfoCard(
            icon: Icons.category,
            title: "Categoría",
            value: proyecto['categoria'],
            color: Colors.purple,
          ),
          _buildInfoCard(
            icon: Icons.location_city,
            title: "Comuna",
            value: proyecto['comuna'],
            color: Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: 8),
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
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[600])),
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
