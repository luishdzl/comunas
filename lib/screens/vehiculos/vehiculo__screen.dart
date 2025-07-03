import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'vehiculo_detalle_screen.dart';

class VehiculoScreen extends StatefulWidget {
  @override
   _VehiculoScreenState createState() =>
   _VehiculoScreenState();
}

class _VehiculoScreenState extends State<VehiculoScreen>{
  List vehiculos = [];
  List vehiculosFiltrados = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLocalJson();
    _searchController.addListener(_filtrarVehiculos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadLocalJson() async {
    final String response = await rootBundle.loadString('lib/screens/vehiculos/vehiculos.json');
    final List data = json.decode(response);


    setState(() {
      vehiculos = data;
      vehiculosFiltrados = data;
    });
  }
    void _filtrarVehiculos() {
    String query = _searchController.text.toLowerCase();

        setState(() {
      vehiculosFiltrados = vehiculos.where((vehiculo) {
        final nombre = vehiculo['nombre'].toString().toLowerCase();
        final placa = vehiculo['placa'].toString().toLowerCase();
        return nombre.contains(query) || placa.contains(query);
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
    hintText: 'Buscar por nombre o placa...',
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
),
SizedBox(height: 16),

                Text(
                  'Lista de vehiculos',
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(vehiculo['nombre']),
                        subtitle: Text(vehiculo['placa']),
                        trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehiculoDetalleScreen(vehiculo: vehiculo),
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