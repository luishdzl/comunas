import 'package:flutter/material.dart';

class VehiculoDetalleScreen extends StatelessWidget {
  final Map vehiculo;

  VehiculoDetalleScreen({required this.vehiculo});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'asignado':
        return Colors.green;
      case 'extraviado':
        return Colors.red;
      case 'devuelto_a_caracas':
        return Colors.blue;
      case 'inactivo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'asignado':
        return 'Asignado';
      case 'extraviado':
        return 'Extraviado';
      case 'devuelto_a_caracas':
        return 'Devuelto a Caracas';
      case 'inactivo':
        return 'Inactivo';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(vehiculo['estatus']);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("${vehiculo['marca']} ${vehiculo['modelo']}"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tarjeta de información principal
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    radius: 40,
                    child: Icon(
                      Icons.directions_car,
                      size: 40,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "${vehiculo['marca']} ${vehiculo['modelo']}",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Placa: ${vehiculo['placa']}",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _getStatusText(vehiculo['estatus']),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Información específica del vehículo
          _buildInfoCard(
            icon: Icons.confirmation_number,
            title: "Placa",
            value: vehiculo['placa'],
            color: Colors.blue,
          ),
          _buildInfoCard(
            icon: Icons.directions_car,
            title: "Clase",
            value: vehiculo['clase'],
            color: Colors.green,
          ),
          _buildInfoCard(
            icon: Icons.business_center,
            title: "Marca",
            value: vehiculo['marca'],
            color: Colors.purple,
          ),
          _buildInfoCard(
            icon: Icons.engineering,
            title: "CC",
            value: vehiculo['cc'],
            color: Colors.orange,
          ),
          _buildInfoCard(
            icon: Icons.model_training,
            title: "Modelo",
            value: vehiculo['modelo'],
            color: Colors.indigo,
          ),
          _buildInfoCard(
            icon: Icons.color_lens,
            title: "Color",
            value: vehiculo['color'],
            color: Colors.pink,
          ),
          _buildInfoCard(
            icon: Icons.calendar_today,
            title: "Año",
            value: vehiculo['ano'].toString(),
            color: Colors.teal,
          ),
          _buildInfoCard(
            icon: Icons.confirmation_number,
            title: "Serial Carrocería",
            value: vehiculo['serialCarroceria'],
            color: Colors.brown,
          ),
          _buildInfoCard(
            icon: Icons.date_range,
            title: "Fecha de Entrega",
            value: _formatDate(vehiculo['fechaDeEntrega']),
            color: Colors.cyan,
          ),

          // Observaciones
          if (vehiculo['observacion'] != null && vehiculo['observacion'].isNotEmpty)
            _buildInfoCard(
              icon: Icons.note,
              title: "Observación",
              value: vehiculo['observacion'],
              color: Colors.grey,
            ),

          if (vehiculo['observacionArchivo'] != null && vehiculo['observacionArchivo'].isNotEmpty)
            _buildInfoCard(
              icon: Icons.folder_open,
              title: "Observación Archivo",
              value: vehiculo['observacionArchivo'],
              color: Colors.blueGrey,
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
}