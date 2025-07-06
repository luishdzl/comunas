import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'comuna_detalle_screen.dart';

class ComunasScreen extends StatefulWidget {
  @override
  _ComunasScreenState createState() => _ComunasScreenState();
}

class _ComunasScreenState extends State<ComunasScreen> {
  List comunas = [];
  int totalConsejos = 0;
  int totalVotantes = 0;

  @override
  void initState() {
    super.initState();
    fetchComunas();
  }

Future<void> fetchComunas() async {
  final response = await http.get(Uri.parse(
      'https://main.d216v5k7f3pzsl.amplifyapp.com/api/comunas'));

  if (response.statusCode == 200) {
    final List data = json.decode(response.body);

    int consejos = data.fold(
        0, (sum, item) => sum + ((item['cantidadConsejosComunales'] ?? 0) as int));
    int votantes = data.fold(
        0, (sum, item) => sum + ((item['poblacionVotante'] ?? 0) as int));

    setState(() {
      comunas = data;
      totalConsejos = consejos;
      totalVotantes = votantes;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las comunas')));
  }
}

  @override
  Widget build(BuildContext context) {
    return comunas.isEmpty
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(),
                SizedBox(height: 16),
                Text(
                  'Lista de Comunas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                      child: ListTile(
                        title: Text(comuna['nombre'] ?? 'Sin nombre'),
                        subtitle: Text(
                            comuna['parroquiaRelation']?['nombre'] ?? ''),
                        trailing: Icon(Icons.arrow_forward_ios),
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
        _statCard('Población Votante', totalVotantes.toString(),
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
            Text(title, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }
}
