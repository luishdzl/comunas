import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'vehiculo_detalle_screen.dart';

class VehiculoScreen extends StatefulWidget {
  @override
  _VehiculoScreenState createState() => _VehiculoScreenState();
}

class _VehiculoScreenState extends State<VehiculoScreen> {
  List vehiculos = [];
  List vehiculosFiltrados = [];
  TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadVehiculosFromJson();
    _searchController.addListener(_filtrarVehiculos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadVehiculosFromJson() async {
    try {
      final String data = await rootBundle.loadString('lib/assets/vehiculos.json');
      final List jsonResult = json.decode(data);

      setState(() {
        vehiculos = jsonResult;
        vehiculosFiltrados = jsonResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los vehículos: $e';
        isLoading = false;
      });
    }
  }

  void _filtrarVehiculos() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      vehiculosFiltrados = vehiculos.where((vehiculo) {
        return (vehiculo['placa']?.toString().toLowerCase() ?? '').contains(query) ||
            (vehiculo['marca']?.toString().toLowerCase() ?? '').contains(query) ||
            (vehiculo['modelo']?.toString().toLowerCase() ?? '').contains(query) ||
            (vehiculo['estatus']?.toString().toLowerCase() ?? '').contains(query) ||
            (vehiculo['clase']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'asignado':
        return Colors.green;
      case 'extraviado':
        return Colors.red;
      case 'devuelto_a_caracas':
        return Colors.blue;
      case 'inactivo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'asignado':
        return Icons.check_circle;
      case 'extraviado':
        return Icons.error;
      case 'devuelto_a_caracas':
        return Icons.arrow_back;
      case 'inactivo':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'asignado':
        return 'Asignado';
      case 'extraviado':
        return 'Extraviado';
      case 'devuelto_a_caracas':
        return 'Devuelto a Caracas';
      case 'inactivo':
        return 'Inactivo';
      default:
        return status;
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
              onPressed: loadVehiculosFromJson,
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
          SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por placa, marca, modelo, clase o estatus...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lista de Vehículos (${vehiculosFiltrados.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text('Total: ${vehiculos.length}'),
                backgroundColor: Colors.blue.shade100,
              ),
            ],
          ),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: vehiculosFiltrados.length,
            itemBuilder: (context, index) {
              final vehiculo = vehiculosFiltrados[index];
              final statusColor = _getStatusColor(vehiculo['estatus']);
              
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(vehiculo['estatus']),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "${vehiculo['marca']} ${vehiculo['modelo']}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text("Placa: ${vehiculo['placa']} • ${vehiculo['ano']}"),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              _getStatusText(vehiculo['estatus']),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "• ${vehiculo['clase']}",
                            style: TextStyle(fontSize: 12),
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