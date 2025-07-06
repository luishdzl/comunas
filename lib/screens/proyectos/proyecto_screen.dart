import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'proyecto_detalle_screen.dart';

class ProyectoScreen extends StatefulWidget {
  @override
  _ProyectoScreenState createState() => _ProyectoScreenState();
}

class _ProyectoScreenState extends State<ProyectoScreen> {
  List proyectos = [];
  List proyectosFiltrados = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProyectos();
    _searchController.addListener(_filtrarProyectos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProyectos() async {
    final response = await http.get(
      Uri.parse('https://main.d216v5k7f3pzsl.amplifyapp.com/api/proyectos'),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        proyectos = data;
        proyectosFiltrados = data;
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al cargar los datos')));
    }
  }

  void _filtrarProyectos() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      proyectosFiltrados = proyectos.where((proyecto) {
        return (proyecto['nombre']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (proyecto['status']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (proyecto['categoria']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (proyecto['comuna']?.toString().toLowerCase() ?? '')
                .contains(query);
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
                    hintText: 'Buscar por nombre, categoría o comuna',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text("Nombre: ${proyecto['nombre']}"),
                        subtitle: Text(
                            "Comuna: ${proyecto['comuna']} — Estado: ${proyecto['status']}"),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProyectoDetalleScreen(
                                  proyecto: proyecto),
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
