import 'package:flutter/material.dart';

class ComunaDetalleScreen extends StatelessWidget {
  final Map comuna;

  const ComunaDetalleScreen({required this.comuna});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(comuna['nombre'] ?? 'Sin nombre'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(Icons.location_city, 'Dirección',
              comuna['direccion'] ?? 'No disponible', Colors.blue),
          _buildInfoCard(Icons.groups, 'Consejos Comunales',
              '${comuna['cantidadConsejosComunales']}', Colors.indigo),
          _buildInfoCard(Icons.how_to_vote, 'Población Votante',
              '${comuna['poblacionVotante']}', Colors.purple),
          _buildInfoCard(
              Icons.person,
              'Vocero',
              '${comuna['nombreVocero'] ?? ''} — ${comuna['ciVocero'] ?? ''}',
              Colors.green),
          _buildInfoCard(
              Icons.phone,
              'Teléfono',
              comuna['telefono'] ?? 'No disponible',
              Colors.teal),
          _buildInfoCard(
              Icons.account_balance,
              'Cuenta Bancaria',
              comuna['cuentaBancaria'] ?? 'No disponible',
              Colors.orange),
          _buildInfoCard(
              Icons.assignment,
              'RIF',
              comuna['rif'] ?? 'No disponible',
              Colors.brown),
          _buildInfoCard(
              Icons.map,
              'Linderos',
              'Norte: ${comuna['linderoNorte']}\nSur: ${comuna['linderoSur']}\nEste: ${comuna['linderoEste']}\nOeste: ${comuna['linderoOeste']}',
              Colors.redAccent),
          _buildInfoCard(
              Icons.flag,
              'Parroquia',
              '${comuna['parroquiaRelation']?['nombre'] ?? ''}, ${comuna['parroquiaRelation']?['municipio'] ?? ''}, ${comuna['parroquiaRelation']?['estado'] ?? ''}',
              Colors.cyan),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
