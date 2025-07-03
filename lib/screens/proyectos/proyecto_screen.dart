import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'proyecto_detalle_screen.dart';

class ProyectoScreen extends StatefulWidget {
  @override
   _ProyectoScreenState createState() =>
   _ProyectoScreenState();
}
class _ProyectoScreenState extends State<ProyectoScreen>{
  List proyectos = [];
  List proyectosFiltrados = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLocalJson();
    _searchController.addListener(_filtrarProyectos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadLocalJson() async {
    final String response = await rootBundle.loadString('lib/screens/proyectos/proyectos.json');
    final List data = json.decode(response);


    setState(() {
      proyectos = data;
      proyectosFiltrados = data;
    });
  }

  void _filtrarProyectos() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      proyectosFiltrados = proyectos.where((proyecto){
        final nombre = proyecto['nombre'].toString().toLowerCase();
        final direccion = proyecto['direccion'].toString().toLowerCase();
        return nombre.contains(query) || direccion.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return proyectos.isEmpty
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                TextField(
  controller: _searchController,
  decoration: InputDecoration(
    hintText: 'Buscar por nombre',
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
),
SizedBox(height: 16),

                Text(
                  'Lista de proyectos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: proyectosFiltrados.length,
                  itemBuilder: (context, index) {
                    final proyecto = proyectosFiltrados[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(proyecto['nombre']),
                        subtitle: Text(proyecto['direccion']),
                        trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProyectoDetalleScreen(proyecto: proyecto),
          ),
        );
      },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
  }


}