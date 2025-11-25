import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class MapasScreen extends StatefulWidget {
  @override
  _MapasScreenState createState() => _MapasScreenState();
}

class _MapasScreenState extends State<MapasScreen> {
  List _comunas = [];
  List _proyectos = [];
  bool _isLoading = true;
  String _selectedFilter = 'todas';
  final TransformationController _transformationController = TransformationController();
  Map<String, Offset> _comunaPositions = {};
  Map<String, List<String>> _comunaConnections = {};
  bool _showInfoPanel = false; // Nueva variable para controlar la visibilidad del panel

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String comunasData = await rootBundle.loadString('lib/assets/comunas.json');
      final String proyectosData = await rootBundle.loadString('lib/assets/proyectos.json');

      setState(() {
        _comunas = json.decode(comunasData);
        _proyectos = json.decode(proyectosData);
        _isLoading = false;
        _initializeMapPositions();
        _calculateConnections();
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeMapPositions() {
    final int count = _comunas.length;
    final double radius = 120.0;
    
    for (int i = 0; i < count; i++) {
      final comuna = _comunas[i];
      final String nombre = comuna['nombre'];
      final double angle = 2 * pi * i / count;
      final double x = radius * cos(angle);
      final double y = radius * sin(angle);
      
      _comunaPositions[nombre] = Offset(x, y);
    }
  }

  void _calculateConnections() {
    for (var comuna in _comunas) {
      final String nombre = comuna['nombre'];
      _comunaConnections[nombre] = [];
      
      for (var otraComuna in _comunas) {
        if (otraComuna['nombre'] == nombre) continue;
        
        final String otraNombre = otraComuna['nombre'];
        
        if (_esLindero(comuna, otraComuna) || _esLindero(otraComuna, comuna)) {
          _comunaConnections[nombre]!.add(otraNombre);
        }
      }
    }
  }

  bool _esLindero(Map comuna, Map otraComuna) {
    final linderos = ['linderoNorte', 'linderoSur', 'linderoEste', 'linderoOeste'];
    final String otraNombre = otraComuna['nombre'];
    
    for (var lindero in linderos) {
      final String? valorLindero = comuna[lindero]?.toString().toLowerCase();
      if (valorLindero != null && 
          (valorLindero.contains(otraNombre.toLowerCase()) ||
           _contienePalabraComun(valorLindero, otraNombre))) {
        return true;
      }
    }
    return false;
  }

  bool _contienePalabraComun(String texto, String nombreComuna) {
    final palabrasComuna = nombreComuna.toLowerCase().split(' ');
    final palabrasTexto = texto.split(' ');
    
    for (var palabra in palabrasComuna) {
      if (palabra.length > 3 && palabrasTexto.contains(palabra)) {
        return true;
      }
    }
    return false;
  }

  List get _comunasFiltradas {
    if (_selectedFilter == 'todas') return _comunas;
    if (_selectedFilter == 'grandes') {
      return _comunas.where((c) => (c['poblacionVotante'] ?? 0) > 8000).toList();
    }
    return _comunas;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final newValue = _transformationController.value.clone();
    newValue.scale(1.5, 1.5);
    _transformationController.value = newValue;
  }

  void _zoomOut() {
    final newValue = _transformationController.value.clone();
    newValue.scale(0.75, 0.75);
    _transformationController.value = newValue;
  }

  void _toggleInfoPanel() {
    setState(() {
      _showInfoPanel = !_showInfoPanel;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: _buildInteractiveMap(),
            ),
          ],
        ),
        
        // Panel de información (condicional)
        if (_showInfoPanel)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildInfoPanel(),
          ),
        
        // Botón flotante para mostrar/ocultar el panel
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildToggleButton(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.filter_list, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                underline: SizedBox(),
                items: [
                  DropdownMenuItem(value: 'todas', child: Text('Todas las Comunas')),
                  DropdownMenuItem(value: 'grandes', child: Text('Comunas Grandes (>8000 hab.)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            _buildZoomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.zoom_out, size: 20),
          onPressed: _zoomOut,
          tooltip: 'Alejar',
        ),
        IconButton(
          icon: Icon(Icons.refresh, size: 20),
          onPressed: _resetZoom,
          tooltip: 'Restablecer zoom',
        ),
        IconButton(
          icon: Icon(Icons.zoom_in, size: 20),
          onPressed: _zoomIn,
          tooltip: 'Acercar',
        ),
      ],
    );
  }

  Widget _buildToggleButton() {
    return FloatingActionButton(
      onPressed: _toggleInfoPanel,
      mini: true,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      child: Icon(
        _showInfoPanel ? Icons.info_outline : Icons.info,
        size: 20,
      ),
      tooltip: _showInfoPanel ? 'Ocultar información' : 'Mostrar información',
    );
  }

  Widget _buildInteractiveMap() {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: EdgeInsets.all(100),
      minScale: 0.1,
      maxScale: 4.0,
      child: Container(
        width: 800,
        height: 800,
        color: Colors.blue[50],
        child: CustomPaint(
          size: Size(800, 800),
          painter: _MapPainter(
            comunas: _comunasFiltradas,
            comunaPositions: _comunaPositions,
            comunaConnections: _comunaConnections,
            onComunaTap: _showComunaDetails,
            proyectos: _proyectos,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Mapa de Relaciones entre Comunas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 18),
                  onPressed: _toggleInfoPanel,
                  tooltip: 'Cerrar panel',
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoItem('Comunas mostradas:', '${_comunasFiltradas.length} de ${_comunas.length}'),
            _buildInfoItem('Proyectos activos:', '${_getProyectosActivosCount().toString()}'),
            _buildInfoItem('Población total:', '${_getPoblacionTotal().toString()} habitantes'),
            SizedBox(height: 8),
            Text(
              'Leyenda:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                _buildLegendItem(Colors.green, '0-1 proyectos'),
                SizedBox(width: 8),
                _buildLegendItem(Colors.orange, '2-3 proyectos'),
                SizedBox(width: 8),
                _buildLegendItem(Colors.red, '4+ proyectos'),
                SizedBox(width: 8),
                _buildLegendItem(Colors.blue, 'Conexión'),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Las líneas azules muestran relaciones de linderos entre comunas',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Color _getMarkerColor(int proyectosCount) {
    if (proyectosCount == 0) return Colors.grey;
    if (proyectosCount <= 1) return Colors.green;
    if (proyectosCount <= 3) return Colors.orange;
    return Colors.red;
  }

  int _getProyectosActivosCount() {
    return _proyectos.where((p) => p['status'] == 'activo').length;
  }

  int _getPoblacionTotal() {
    return _comunasFiltradas.fold(0, (int sum, comuna) => sum + ((comuna['poblacionVotante'] ?? 0) as int));
  }

  void _showComunaDetails(Map comuna) {
    final proyectosComuna = _proyectos.where((p) => p['comuna'] == comuna['nombre']).toList();
    final connections = _comunaConnections[comuna['nombre']] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                comuna['nombre']?.toString() ?? 'Sin nombre',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Código: ${comuna['codigo'] ?? 'N/A'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              
              _buildDetailItem('Código:', comuna['codigo'] ?? 'No disponible'),
              _buildDetailItem('RIF:', comuna['rif'] ?? 'No disponible'),
              _buildDetailItem('Dirección:', comuna['direccion'] ?? 'No disponible'),
              _buildDetailItem('Población votante:', '${comuna['poblacionVotante'] ?? 0} habitantes'),
              _buildDetailItem('Consejos comunales:', '${comuna['cantidadConsejosComunales'] ?? 0}'),
              _buildDetailItem('Proyectos en la comuna:', '${proyectosComuna.length}'),
              
              SizedBox(height: 16),
              Text('Linderos:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildLinderoItem('Norte', comuna['linderoNorte']),
              _buildLinderoItem('Sur', comuna['linderoSur']),
              _buildLinderoItem('Este', comuna['linderoEste']),
              _buildLinderoItem('Oeste', comuna['linderoOeste']),
              
              if (connections.isNotEmpty) ...[
                SizedBox(height: 16),
                Text('Comunas Relacionadas:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: connections.map((nombre) => Chip(
                    label: Text(nombre, style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  )).toList(),
                ),
              ],
              
              if (proyectosComuna.isNotEmpty) ...[
                SizedBox(height: 16),
                Text('Proyectos:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...proyectosComuna.take(3).map((proyecto) => 
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_right, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(child: Text('${proyecto['nombre']}')),
                        Chip(
                          label: Text(proyecto['status'] ?? '', style: TextStyle(fontSize: 10)),
                          backgroundColor: _getStatusColor(proyecto['status']).withOpacity(0.1),
                        ),
                      ],
                    ),
                  )
                ).toList(),
              ],
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14))),
          Text(value, 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end),
        ],
      ),
    );
  }

  Widget _buildLinderoItem(String direccion, String? valor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Text('$direccion:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(valor ?? 'No disponible', 
                style: TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'activo':
        return Colors.green;
      case 'completado':
        return Colors.blue;
      case 'en pausa':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// La clase _MapPainter se mantiene igual que antes
class _MapPainter extends CustomPainter {
  final List comunas;
  final Map<String, Offset> comunaPositions;
  final Map<String, List<String>> comunaConnections;
  final Function(Map) onComunaTap;
  final List proyectos;

  _MapPainter({
    required this.comunas,
    required this.comunaPositions,
    required this.comunaConnections,
    required this.onComunaTap,
    required this.proyectos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final connectionPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var comuna in comunas) {
      final String nombre = comuna['nombre'];
      final Offset? position = comunaPositions[nombre];
      
      if (position != null) {
        final connectedComunas = comunaConnections[nombre] ?? [];
        
        for (var connectedNombre in connectedComunas) {
          final Offset? connectedPosition = comunaPositions[connectedNombre];
          if (connectedPosition != null) {
            canvas.drawLine(
              center + position,
              center + connectedPosition,
              connectionPaint,
            );
          }
        }
      }
    }

    for (var comuna in comunas) {
      final String nombre = comuna['nombre'];
      final Offset? position = comunaPositions[nombre];
      
      if (position != null) {
        final proyectosComuna = proyectos.where((p) => p['comuna'] == nombre).toList();
        final markerColor = _getMarkerColor(proyectosComuna.length);
        
        final circlePaint = Paint()
          ..color = markerColor
          ..style = PaintingStyle.fill;
        
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        
        canvas.drawCircle(center + position, 20, circlePaint);
        canvas.drawCircle(center + position, 20, borderPaint);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: proyectosComuna.length.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          center + position - Offset(textPainter.width / 2, textPainter.height / 2),
        );
        
        final namePainter = TextPainter(
          text: TextSpan(
            text: _getShortName(nombre),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        namePainter.layout();
        namePainter.paint(
          canvas,
          center + position + Offset(-namePainter.width / 2, 25),
        );
      }
    }
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length > 2) {
      return '${parts[1]} ${parts[2]}';
    }
    return fullName.length > 12 ? '${fullName.substring(0, 10)}...' : fullName;
  }

  Color _getMarkerColor(int proyectosCount) {
    if (proyectosCount == 0) return Colors.grey;
    if (proyectosCount <= 1) return Colors.green;
    if (proyectosCount <= 3) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  bool hitTest(Offset position) {
    final center = Offset(400, 400);
    
    for (var comuna in comunas) {
      final String nombre = comuna['nombre'];
      final Offset? comunaPosition = comunaPositions[nombre];
      
      if (comunaPosition != null) {
        final circleCenter = center + comunaPosition;
        final distance = (position - circleCenter).distance;
        
        if (distance <= 20) {
          onComunaTap(comuna);
          return true;
        }
      }
    }
    return false;
  }
}