import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'vehiculo_detalle_screen.dart';

class VehiculoScreen extends StatefulWidget {
  @override
  _VehiculoScreenState createState() => _VehiculoScreenState();
}

class _VehiculoScreenState extends State<VehiculoScreen> {
  List vehiculos = [];
  List vehiculosFiltrados = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchVehiculos();
    _searchController.addListener(_filtrarVehiculos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchVehiculos() async {
    final response = await http.get(Uri.parse(
        'https://main.d216v5k7f3pzsl.amplifyapp.com/api/vehiculos'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        vehiculos = data;
        vehiculosFiltrados = data;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los datos')),
      );
    }
  }

  void _filtrarVehiculos() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      vehiculosFiltrados = vehiculos.where((vehiculo) {
        return (vehiculo['placa']?.toString().toLowerCase() ?? '').contains(query) ||
            (vehiculo['marca']?.toString().toLowerCase() ?? '').contains(query) ||
            (vehiculo['modelo']?.toString().toLowerCase() ?? '').contains(query) ||
            (vehiculo['comuna']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return vehiculos.isEmpty
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
                    hintText: 'Buscar por placa, marca, modelo o comuna...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Lista de vehículos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: vehiculosFiltrados.length,
                  itemBuilder: (context, index) {
                    final vehiculo = vehiculosFiltrados[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text("${vehiculo['marca']} ${vehiculo['modelo']}"),
                        subtitle: Text("Placa: ${vehiculo['placa']}"),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VehiculoDetalleScreen(vehiculo: vehiculo),
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
