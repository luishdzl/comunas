import 'package:flutter/material.dart';

class ProyectoDetalleScreen extends StatelessWidget {
  final Map proyecto;

  ProyectoDetalleScreen({required this.proyecto});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'activo':
        return Colors.green;
      case 'completado':
        return Colors.blue;
      case 'en pausa':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(proyecto['status']);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(proyecto['nombre']),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tarjeta de estado con progreso
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          proyecto['status'].toString().toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          _buildInfoCard(
            icon: Icons.assignment,
            title: "Nombre del Proyecto",
            value: proyecto['nombre'],
            color: Colors.blueAccent,
          ),
          _buildInfoCard(
            icon: Icons.description,
            title: "Descripción",
            value: proyecto['descripcion'] ?? 'Sin descripción',
            color: Colors.purple,
          ),
          _buildInfoCard(
            icon: Icons.category,
            title: "Categoría",
            value: proyecto['categoria'],
            color: Colors.deepPurple,
          ),
          _buildInfoCard(
            icon: Icons.location_city,
            title: "Comuna",
            value: proyecto['comuna'],
            color: Colors.deepOrange,
          ),
          _buildInfoCard(
            icon: Icons.attach_money,
            title: "Presupuesto",
            value: _formatCurrency((proyecto['presupuesto'] ?? 0).toDouble()),
            color: Colors.green,
          ),
          _buildInfoCard(
            icon: Icons.people,
            title: "Beneficiarios",
            value: '${proyecto['beneficiarios']} personas',
            color: Colors.teal,
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
            color: Colors.cyan,
          ),
        ],
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
                          fontSize: 16,
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