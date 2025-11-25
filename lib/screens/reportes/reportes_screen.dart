import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ReportesScreen extends StatefulWidget {
  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List _comunas = [];
  List _proyectos = [];
  List _vehiculos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final String comunasData = await rootBundle.loadString('lib/assets/comunas.json');
      final String proyectosData = await rootBundle.loadString('lib/assets/proyectos.json');
      final String vehiculosData = await rootBundle.loadString('lib/assets/vehiculos.json');

      setState(() {
        _comunas = json.decode(comunasData);
        _proyectos = json.decode(proyectosData);
        _vehiculos = json.decode(vehiculosData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _errorMessage = 'Error cargando datos: $e';
        _isLoading = false;
      });
    }
  }

  // Métodos de cálculo para estadísticas
  int get _totalComunas => _comunas.length;
  int get _totalProyectos => _proyectos.length;
  int get _totalVehiculos => _vehiculos.length;
  
  int get _totalPoblacionVotante {
    return _comunas.fold(0, (int sum, comuna) => sum + ((comuna['poblacionVotante'] ?? 0) as int));
  }
  
  int get _totalConsejosComunales {
    return _comunas.fold(0, (int sum, comuna) => sum + ((comuna['cantidadConsejosComunales'] ?? 0) as int));
  }

  double get _presupuestoTotalProyectos {
    return _proyectos.fold(0.0, (double sum, proyecto) => sum + ((proyecto['presupuesto'] ?? 0).toDouble()));
  }

Map<String, int> get _proyectosPorEstado {
  Map<String, int> counts = {};
  for (var proyecto in _proyectos) {
    String estado = proyecto['estatusProyecto']?.toString() ?? 'Sin estado';
    counts[estado] = (counts[estado] ?? 0) + 1;
  }
  return counts;
}
int get _totalPersonasBeneficiadas {
  return _proyectos.fold(0, (int sum, proyecto) => sum + ((proyecto['personasBeneficiadas'] ?? 0) as int));
}

int get _totalFamiliasBeneficiadas {
  return _proyectos.fold(0, (int sum, proyecto) => sum + ((proyecto['familiasBeneficiadas'] ?? 0) as int));
}

int get _totalComunidadesBeneficiadas {
  return _proyectos.fold(0, (int sum, proyecto) => sum + ((proyecto['comunidadesBeneficiadas'] ?? 0) as int));
}

  Map<String, int> get _proyectosPorCategoria {
    Map<String, int> counts = {};
    for (var proyecto in _proyectos) {
      String categoria = proyecto['categoria']?.toString() ?? 'Sin categoría';
      counts[categoria] = (counts[categoria] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get _vehiculosPorEstado {
    Map<String, int> counts = {};
    for (var vehiculo in _vehiculos) {
      String estado = vehiculo['estatus']?.toString() ?? 'Sin estatus';
      counts[estado] = (counts[estado] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error al cargar datos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllData,
                child: Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildSummaryCards(),
          SizedBox(height: 20),
          _buildProyectosStats(),
          SizedBox(height: 20),
          _buildVehiculosStats(),
          SizedBox(height: 20),
          _buildComunasStats(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportes y Estadísticas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            SizedBox(height: 8),
            Text(
              'Resumen general del sistema de comunas',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Actualizado: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: [
        _buildStatCard('Comunas', _totalComunas.toString(), Icons.location_city, Colors.blue),
        _buildStatCard('Proyectos', _totalProyectos.toString(), Icons.work, Colors.green),
        _buildStatCard('Vehículos', _totalVehiculos.toString(), Icons.directions_car, Colors.orange),
        _buildStatCard('Población', _formatNumber(_totalPoblacionVotante), Icons.people, Colors.purple),
        _buildStatCard('Consejos', _totalConsejosComunales.toString(), Icons.groups, Colors.teal),
        _buildStatCard('Presupuesto', _formatCurrency(_presupuestoTotalProyectos), Icons.attach_money, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Container(
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(minHeight: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProyectosStats() {
    final proyectosPorEstado = _proyectosPorEstado;
    final proyectosPorCategoria = _proyectosPorCategoria;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Proyectos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Text('Por Estado:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            _buildProgressBars(proyectosPorEstado),
            SizedBox(height: 16),
            
            Text('Por Categoría:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            _buildCategoryList(proyectosPorCategoria),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars(Map<String, int> data) {
    final total = data.values.fold(0, (int sum, value) => sum + value);
    
    return Column(
      children: data.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total) : 0.0;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${entry.value} (${(percentage * 100).toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[300],
                color: _getStatusColor(entry.key),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryList(Map<String, int> data) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: data.entries.map((entry) {
        return Chip(
          label: Text('${entry.key}: ${entry.value}', style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.blue.withOpacity(0.1),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildVehiculosStats() {
    final vehiculosPorEstado = _vehiculosPorEstado;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Vehículos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildVehicleStatusGrid(vehiculosPorEstado),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleStatusGrid(Map<String, int> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 1,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: data.entries.map((entry) {
        return Container(
          decoration: BoxDecoration(
            color: _getStatusColor(entry.key).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getStatusColor(entry.key)),
          ),
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(entry.key),
                ),
              ),
              SizedBox(height: 4),
              Text(
                _getStatusText(entry.key),
                style: TextStyle(
                  fontSize: 11,
                  color: _getStatusColor(entry.key),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComunasStats() {
    var comunaMayorPoblacion = _comunas.isNotEmpty 
        ? _comunas.reduce((a, b) => (a['poblacionVotante'] ?? 0) > (b['poblacionVotante'] ?? 0) ? a : b)
        : null;

    var comunaMayorConsejos = _comunas.isNotEmpty
        ? _comunas.reduce((a, b) => (a['cantidadConsejosComunales'] ?? 0) > (b['cantidadConsejosComunales'] ?? 0) ? a : b)
        : null;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estadísticas de Comunas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            if (comunaMayorPoblacion != null) 
              _buildComunaStatItem(
                'Comuna con mayor población:',
                '${comunaMayorPoblacion['nombre']}',
                '${_formatNumber(comunaMayorPoblacion['poblacionVotante'] as int)} habitantes',
                Icons.people,
              ),
            
            if (comunaMayorConsejos != null) 
              _buildComunaStatItem(
                'Comuna con más consejos:',
                '${comunaMayorConsejos['nombre']}',
                '${comunaMayorConsejos['cantidadConsejosComunales']} consejos',
                Icons.groups,
              ),
            
            _buildComunaStatItem(
              'Promedio de consejos:',
              'Por comuna',
              '${(_totalConsejosComunales / _totalComunas).toStringAsFixed(1)}',
              Icons.analytics,
            ),
            
            _buildComunaStatItem(
              'Promedio de población:',
              'Por comuna',
              '${_formatNumber((_totalPoblacionVotante / _totalComunas).round())} hab.',
              Icons.people_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComunaStatItem(String label, String subtitle, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[800]), textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'aprobado':
      return Colors.blue;
    case 'en ejecución':
      return Colors.green;
    case 'finalizado':
      return Colors.purple;
    case 'paralizado':
      return Colors.orange;
    case 'inconcluso':
      return Colors.red;
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }
}