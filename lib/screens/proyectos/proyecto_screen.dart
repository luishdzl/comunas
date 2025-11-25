import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'proyecto_detalle_screen.dart';

class ProyectoScreen extends StatefulWidget {
  @override
  _ProyectoScreenState createState() => _ProyectoScreenState();
}

class _ProyectoScreenState extends State<ProyectoScreen> {
  List proyectos = [];
  List proyectosFiltrados = [];
  TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadProyectosFromJson();
    _searchController.addListener(_filtrarProyectos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadProyectosFromJson() async {
    try {
      final String data = await rootBundle.loadString('lib/assets/proyectos.json');
      final List jsonResult = json.decode(data);

      setState(() {
        proyectos = jsonResult;
        proyectosFiltrados = jsonResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los proyectos: $e';
        isLoading = false;
      });
    }
  }

  void _filtrarProyectos() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      proyectosFiltrados = proyectos.where((proyecto) {
        return (proyecto['nombreProyecto']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (proyecto['estatusProyecto']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (proyecto['categoria']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (proyecto['comuna']?.toString().toLowerCase() ?? '')
                .contains(query) ||
            (proyecto['codigoProyecto']?.toString().toLowerCase() ?? '')
                .contains(query);
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APROBADO':
        return Colors.blue;
      case 'EN EJECUCIÓN':
        return Colors.green;
      case 'FINALIZADO':
        return Colors.purple;
      case 'PARALIZADO':
        return Colors.orange;
      case 'INCONCLUSO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'APROBADO':
        return 'Aprobado';
      case 'EN EJECUCIÓN':
        return 'En Ejecución';
      case 'FINALIZADO':
        return 'Finalizado';
      case 'PARALIZADO':
        return 'Paralizado';
      case 'INCONCLUSO':
        return 'Inconcluso';
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
              onPressed: loadProyectosFromJson,
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
              hintText: 'Buscar por nombre, categoría, comuna, código o estado',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lista de Proyectos (${proyectosFiltrados.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text('Total: ${proyectos.length}'),
                backgroundColor: Colors.blue.shade100,
              ),
            ],
          ),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: proyectosFiltrados.length,
            itemBuilder: (context, index) {
              final proyecto = proyectosFiltrados[index];
              final statusColor = _getStatusColor(proyecto['estatusProyecto']);
              
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(proyecto['estatusProyecto']),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    proyecto['nombreProyecto'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text("Código: ${proyecto['codigoProyecto']}"),
                      SizedBox(height: 2),
                      Text("Comuna: ${proyecto['comuna']}"),
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
                              _getStatusText(proyecto['estatusProyecto']),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "• ${proyecto['categoria']}",
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APROBADO':
        return Icons.check_circle;
      case 'EN EJECUCIÓN':
        return Icons.play_arrow;
      case 'FINALIZADO':
        return Icons.done_all;
      case 'PARALIZADO':
        return Icons.pause_circle;
      case 'INCONCLUSO':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}