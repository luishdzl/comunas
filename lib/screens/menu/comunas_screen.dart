import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ComunasScreen extends StatefulWidget {
  @override
  _ComunasScreenState createState() => _ComunasScreenState();
}

class _ComunasScreenState extends State<ComunasScreen> {
  List comunas = [];
  int totalVoceros = 0;

  @override
  void initState() {
    super.initState();
    loadLocalJson();
  }

  Future<void> loadLocalJson() async {
    final String response = await rootBundle.loadString('lib/screens/menu/comunas.json');
    final List data = json.decode(response);

  int voceroCount = data.fold(0, (int sum, comuna) => sum + (comuna['voceros'] as int? ?? 0));


    setState(() {
      comunas = data;
      totalVoceros = voceroCount;
    });
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
                  'Lista de Juntas Comunales',
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(comuna['nombre']),
                        subtitle: Text(comuna['direccion']),
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
        _statCard('Juntas Comunales', comunas.length.toString(), Icons.apartment, Colors.blueAccent),
        _statCard('Voceros', totalVoceros.toString(), Icons.record_voice_over, Colors.deepPurple),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
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
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }
}
