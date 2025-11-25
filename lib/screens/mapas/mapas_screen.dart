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
  bool _showInfoPanel = false;
  double _currentScale = 1.0;

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
    final double baseRadius = 100.0;
    final double radius = baseRadius * (1 + (count - 10) * 0.05).clamp(1.0, 2.0);
    
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
    setState(() {
      _currentScale = 1.0;
    });
  }

  void _zoomIn() {
    final newValue = _transformationController.value.clone();
    newValue.scale(1.5, 1.5);
    _transformationController.value = newValue;
    setState(() {
      _currentScale *= 1.5;
    });
  }

  void _zoomOut() {
    final newValue = _transformationController.value.clone();
    newValue.scale(0.75, 0.75);
    _transformationController.value = newValue;
    setState(() {
      _currentScale *= 0.75;
    });
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

    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    final mapSize = isPortrait ? screenSize.width * 0.9 : screenSize.height * 0.8;
    final mapCenter = mapSize / 2;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildFilterBar(context),
                Expanded(
                  child: Center(
                    child: _buildInteractiveMap(mapSize, mapCenter),
                  ),
                ),
              ],
            ),
            
            if (_showInfoPanel)
              Positioned(
                bottom: 70,
                left: 16,
                right: 16,
                child: _buildInfoPanel(context),
              ),
            
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  _buildToggleButton(),
                  SizedBox(height: 8),
                  _buildMobileZoomControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Card(
      margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 12,
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list, color: Colors.blue, size: isSmallScreen ? 18 : 20),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Text('Filtrar:', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16
                )),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                underline: SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: 'todas', 
                    child: Text(
                      'Todas las Comunas',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    )),
                  DropdownMenuItem(
                    value: 'grandes', 
                    child: Text(
                      'Comunas Grandes (>8000 hab.)',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
            ),
            if (!_isSmallScreen(context)) ...[
              SizedBox(width: 16),
              _buildZoomControls(),
            ],
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

  Widget _buildMobileZoomControls() {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          IconButton(
            icon: Icon(Icons.zoom_in, size: 20),
            onPressed: _zoomIn,
            tooltip: 'Acercar',
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 20),
            onPressed: _resetZoom,
            tooltip: 'Restablecer zoom',
          ),
          IconButton(
            icon: Icon(Icons.zoom_out, size: 20),
            onPressed: _zoomOut,
            tooltip: 'Alejar',
          ),
        ],
      ),
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

  Widget _buildInteractiveMap(double mapSize, double mapCenter) {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: EdgeInsets.all(20),
      minScale: 0.1,
      maxScale: 4.0,
      onInteractionUpdate: (ScaleUpdateDetails details) {
        if (details.scale != 1.0) {
          setState(() {
            _currentScale *= details.scale;
          });
        }
      },
      child: Container(
        width: mapSize,
        height: mapSize,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(mapSize, mapSize),
              painter: _MapConnectionsPainter(
                comunas: _comunasFiltradas,
                comunaPositions: _comunaPositions,
                comunaConnections: _comunaConnections,
                mapCenter: mapCenter,
              ),
            ),
            
            for (var comuna in _comunasFiltradas)
              if (_comunaPositions[comuna['nombre']] != null)
                _ComunaMarker(
                  comuna: comuna,
                  proyectos: _proyectos,
                  position: _comunaPositions[comuna['nombre']]!,
                  onTap: () => _showComunaDetails(comuna, context),
                  scale: _currentScale,
                  mapCenter: mapCenter,
                  mapSize: mapSize,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Card(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: isSmallScreen ? 18 : 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mapa de Relaciones',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: isSmallScreen ? 16 : 18),
                  onPressed: _toggleInfoPanel,
                  tooltip: 'Cerrar panel',
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildInfoItem('Comunas:', '${_comunasFiltradas.length}/${_comunas.length}', context),
            _buildInfoItem('Proyectos activos:', _getProyectosActivosCount().toString(), context),
            _buildInfoItem('Población total:', '${_getPoblacionTotal()} hab.', context),
            SizedBox(height: 8),
            Text(
              'Leyenda:',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: isSmallScreen ? 12 : 14
              ),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildLegendItem(Colors.green, '0-1', context),
                _buildLegendItem(Colors.orange, '2-3', context),
                _buildLegendItem(Colors.red, '4+', context),
                _buildLegendItem(Colors.blue, 'Conexión', context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label, 
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 10 : 12,
          height: isSmallScreen ? 10 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          text, 
          style: TextStyle(fontSize: isSmallScreen ? 10 : 12)
        ),
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
    return _proyectos.where((p) => p['estatusProyecto'] == 'EN EJECUCIÓN').length;
  }

  int _getPoblacionTotal() {
    return _comunasFiltradas.fold(0, (int sum, comuna) => sum + ((comuna['poblacionVotante'] ?? 0) as int));
  }

  void _showComunaDetails(Map comuna, BuildContext context) {
    final proyectosComuna = _proyectos.where((p) => p['comuna'] == comuna['nombre']).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
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
              
              _buildResponsiveDetailItem('Código:', comuna['codigo']?.toString() ?? 'No disponible', context),
              _buildResponsiveDetailItem('RIF:', comuna['rif']?.toString() ?? 'No disponible', context),
              _buildResponsiveDetailItem('Dirección:', comuna['direccion']?.toString() ?? 'No disponible', context),
              _buildResponsiveDetailItem('Población votante:', '${comuna['poblacionVotante'] ?? 0} habitantes', context),
              _buildResponsiveDetailItem('Consejos comunales:', '${comuna['cantidadConsejosComunales'] ?? 0}', context),
              _buildResponsiveDetailItem('Proyectos en la comuna:', '${proyectosComuna.length}', context),
              
              if (proyectosComuna.isNotEmpty) ...[
                SizedBox(height: 16),
                Text('Proyectos:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...proyectosComuna.take(3).map((proyecto) {
                  final nombreProyecto = proyecto['nombreProyecto']?.toString() ?? 'Sin nombre';
                  final estatusProyecto = proyecto['estatusProyecto']?.toString() ?? 'Sin estado';
                  
                  return ListTile(
                    leading: Icon(Icons.arrow_right, color: Colors.blue),
                    title: Text(
                      nombreProyecto,
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: Chip(
                      label: Text(
                        _getStatusText(estatusProyecto), 
                        style: TextStyle(fontSize: 10)
                      ),
                      backgroundColor: _getStatusColor(estatusProyecto).withOpacity(0.1),
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ],
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveDetailItem(String label, String value, BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: isSmallScreen ? 2 : 1,
            child: Text(
              label, 
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 14,
                fontWeight: FontWeight.w500
              ),
            ),
          ),
          Expanded(
            flex: isSmallScreen ? 3 : 2,
            child: Text(
              value, 
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 14,
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == null) return Colors.grey;
    
    switch (status.toUpperCase()) {
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
    if (status == null) return 'Sin estado';
    
    switch (status.toUpperCase()) {
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

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
}

class _MapConnectionsPainter extends CustomPainter {
  final List comunas;
  final Map<String, Offset> comunaPositions;
  final Map<String, List<String>> comunaConnections;
  final double mapCenter;

  _MapConnectionsPainter({
    required this.comunas,
    required this.comunaPositions,
    required this.comunaConnections,
    required this.mapCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(mapCenter, mapCenter);
    
    final connectionPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 1.5
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _ComunaMarker extends StatelessWidget {
  final Map comuna;
  final List proyectos;
  final Offset position;
  final VoidCallback onTap;
  final double scale;
  final double mapCenter;
  final double mapSize;

  const _ComunaMarker({
    required this.comuna,
    required this.proyectos,
    required this.position,
    required this.onTap,
    required this.scale,
    required this.mapCenter,
    required this.mapSize,
  });

  Color _getMarkerColor(int proyectosCount) {
    if (proyectosCount == 0) return Colors.grey;
    if (proyectosCount <= 1) return Colors.green;
    if (proyectosCount <= 3) return Colors.orange;
    return Colors.red;
  }

  String _getShortName(String fullName) {
    if (fullName == null) return '';
    
    final parts = fullName.split(' ');
    if (parts.length > 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return fullName.length > 12 ? '${fullName.substring(0, 10)}...' : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final proyectosComuna = proyectos.where((p) => p['comuna'] == comuna['nombre']).toList();
    final markerColor = _getMarkerColor(proyectosComuna.length);
    
    final double baseMarkerSize = mapSize * 0.08;
    final double adaptiveMarkerSize = baseMarkerSize / scale.clamp(0.5, 2.0);
    
    final double leftPosition = mapCenter + position.dx - adaptiveMarkerSize / 2;
    final double topPosition = mapCenter + position.dy - adaptiveMarkerSize / 2;

    return Positioned(
      left: leftPosition,
      top: topPosition,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: adaptiveMarkerSize,
          height: adaptiveMarkerSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: adaptiveMarkerSize,
                height: adaptiveMarkerSize,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: max(1.5, 1.5 / scale.clamp(0.5, 2.0)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    proyectosComuna.length.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: adaptiveMarkerSize * 0.3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              Positioned(
                left: adaptiveMarkerSize / 2 - 25,
                top: adaptiveMarkerSize + 2,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 50,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    _getShortName(comuna['nombre'] ?? ''),
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: adaptiveMarkerSize * 0.15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}