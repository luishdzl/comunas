import 'package:flutter/material.dart';

class ProyectoDetalleScreen extends StatelessWidget {
  final Map proyecto;

  ProyectoDetalleScreen({required this.proyecto});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APROBADO':
        return Colors.blue;
      case 'EN EJECUCIÓN':
        return Colors.green;
      case 'FINALIZADO':
        return Colors.purple;
      case 'PARALIZADO':
        return Colors.orange;
      case 'INCONCLUSO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(proyecto['estatusProyecto']);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(proyecto['nombreProyecto']),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tarjeta de estado
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
                          _getStatusText(proyecto['estatusProyecto']),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        proyecto['codigoProyecto'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMiniStat(
                        'Familias',
                        proyecto['familiasBeneficiadas'].toString(),
                        Icons.family_restroom,
                        Colors.blue,
                      ),
                      SizedBox(width: 16),
                      _buildMiniStat(
                        'Personas',
                        proyecto['personasBeneficiadas'].toString(),
                        Icons.people,
                        Colors.green,
                      ),
                      SizedBox(width: 16),
                      _buildMiniStat(
                        'Comunidades',
                        proyecto['comunidadesBeneficiadas'].toString(),
                        Icons.location_city,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          _buildInfoCard(
            icon: Icons.assignment,
            title: "Nombre del Proyecto",
            value: proyecto['nombreProyecto'],
            color: Colors.blueAccent,
          ),
          _buildInfoCard(
            icon: Icons.description,
            title: "Observaciones",
            value: proyecto['observacion'] ?? 'Sin observaciones',
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
            icon: Icons.assignment_ind,
            title: "Consejo Comunal",
            value: proyecto['consejoComunalId'] ?? 'No especificado',
            color: Colors.teal,
          ),
          _buildInfoCard(
            icon: Icons.featured_play_list,
            title: "Consulta ID",
            value: proyecto['consultaId'] ?? 'No especificado',
            color: Colors.indigo,
          ),
          _buildInfoCard(
            icon: Icons.date_range,
            title: "Fecha de creación",
            value: proyecto['fechaCreacion'].toString().split('T')[0],
            color: Colors.cyan,
          ),
          _buildInfoCard(
            icon: Icons.update,
            title: "Última actividad",
            value: proyecto['ultimaActividad'].toString().split('T')[0],
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'APROBADO':
        return 'APROBADO';
      case 'EN EJECUCIÓN':
        return 'EN EJECUCIÓN';
      case 'FINALIZADO':
        return 'FINALIZADO';
      case 'PARALIZADO':
        return 'PARALIZADO';
      case 'INCONCLUSO':
        return 'INCONCLUSO';
      default:
        return status;
    }
  }
}