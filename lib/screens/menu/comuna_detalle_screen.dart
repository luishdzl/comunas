import 'package:flutter/material.dart';

class ComunaDetalleScreen extends StatelessWidget {
  final Map comuna;

  const ComunaDetalleScreen({required this.comuna});

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'No disponible';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(comuna['nombre'] ?? 'Sin nombre'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información básica
          _buildInfoCard(Icons.code, 'Código', comuna['codigo'] ?? 'No disponible', Colors.blue),
          _buildInfoCard(Icons.assignment, 'Número Comisión Promotora', comuna['numComisionPromotora'] ?? 'No disponible', Colors.green),
          _buildInfoCard(Icons.date_range, 'Fecha Comisión Promotora', _formatDate(comuna['fechaComisionPromotora']), Colors.orange),
          _buildInfoCard(Icons.assignment_ind, 'RIF', comuna['rif'] ?? 'No disponible', Colors.purple),
          _buildInfoCard(Icons.account_balance, 'Cuenta Bancaria', comuna['cuentaBancaria'] ?? 'No disponible', Colors.teal),
          _buildInfoCard(Icons.calendar_today, 'Fecha de Registro', _formatDate(comuna['fechaRegistro']), Colors.indigo),
          
          // Información de ubicación
          _buildInfoCard(Icons.location_on, 'Dirección', comuna['direccion'] ?? 'No disponible', Colors.brown),
          _buildInfoCard(Icons.map, 'Linderos', 
              'Norte: ${comuna['linderoNorte'] ?? 'No disponible'}\n'
              'Sur: ${comuna['linderoSur'] ?? 'No disponible'}\n'
              'Este: ${comuna['linderoEste'] ?? 'No disponible'}\n'
              'Oeste: ${comuna['linderoOeste'] ?? 'No disponible'}', 
              Colors.redAccent),
          
          // Información electoral
          _buildInfoCard(Icons.groups, 'Consejos Comunales', '${comuna['cantidadConsejosComunales'] ?? 0}', Colors.indigo),
          _buildInfoCard(Icons.how_to_vote, 'Población Votante', '${comuna['poblacionVotante'] ?? 0}', Colors.purple),
          _buildInfoCard(Icons.event, 'Fecha Última Elección', _formatDate(comuna['fechaUltimaEleccion']), Colors.pink),
          
          // Consejos Comunales
          if (comuna['consejosComunales'] != null && comuna['consejosComunales'].isNotEmpty)
            _buildConsejosComunalesCard(comuna['consejosComunales']),
          
          // Bancos de la Comuna
          if (comuna['bancoDeLaComuna'] != null && comuna['bancoDeLaComuna'].isNotEmpty)
            _buildBancosCard(comuna['bancoDeLaComuna']),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, Color color) {
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

  Widget _buildConsejosComunalesCard(List consejos) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  child: Icon(Icons.groups, color: Colors.indigo),
                ),
                SizedBox(width: 16),
                Text('Consejos Comunales',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
            SizedBox(height: 12),
            ...consejos.map<Widget>((consejo) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        consejo['nombre'] ?? 'Sin nombre',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBancosCard(List bancos) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  child: Icon(Icons.account_balance, color: Colors.teal),
                ),
                SizedBox(width: 16),
                Text('Bancos de la Comuna',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
            SizedBox(height: 12),
            ...bancos.map<Widget>((banco) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banco['nombreBanco'] ?? 'Sin nombre',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cuenta: ${banco['numeroCuenta'] ?? 'No disponible'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (banco['tipoCuenta'] != null)
                      Text(
                        'Tipo: ${banco['tipoCuenta']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}