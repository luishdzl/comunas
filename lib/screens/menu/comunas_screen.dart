import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'comuna_detalle_screen.dart';

class ComunasScreen extends StatefulWidget {
  @override
  _ComunasScreenState createState() => _ComunasScreenState();
}

class _ComunasScreenState extends State<ComunasScreen> {
  List comunas = [];
  int totalConsejos = 0;
  int totalVotantes = 0;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadComunasFromJson();
  }

  Future<void> loadComunasFromJson() async {
    try {
      final String data = await rootBundle.loadString('lib/assets/comunas.json');
      final List jsonResult = json.decode(data);

      int consejos = jsonResult.fold(
          0, (sum, item) => sum + ((item['cantidadConsejosComunales'] ?? 0) as int));
      int votantes = jsonResult.fold(
          0, (sum, item) => sum + ((item['poblacionVotante'] ?? 0) as int));

      setState(() {
        comunas = jsonResult;
        totalConsejos = consejos;
        totalVotantes = votantes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los datos: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(errorMessage, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadComunasFromJson,
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(),
          SizedBox(height: 16),
          Text(
            'Lista de Comunas (${comunas.length})',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: comunas.length,
            itemBuilder: (context, index) {
              final comuna = comunas[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(comuna['nombre'] ?? 'Sin nombre'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Código: ${comuna['codigo'] ?? 'N/A'}'),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              '${comuna['cantidadConsejosComunales']} consejos',
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue.shade50,
                          ),
                          SizedBox(width: 4),
                          Chip(
                            label: Text(
                              '${comuna['poblacionVotante']} votantes',
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.green.shade50,
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ComunaDetalleScreen(
                                comuna: comuna)));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statCard('Consejos Comunales', totalConsejos.toString(),
            Icons.groups, Colors.blueAccent),
        _statCard('Población Votante', _formatNumber(totalVotantes),
            Icons.how_to_vote, Colors.deepPurple),
      ],
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            SizedBox(height: 4),
            Text(title, 
                style: TextStyle(fontSize: 14, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number > 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}