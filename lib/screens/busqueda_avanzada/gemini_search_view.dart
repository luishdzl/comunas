import 'package:flutter/material.dart';
import 'dart:convert';
import 'gemini_service.dart';

class GeminiSearchView extends StatefulWidget {
  @override
  _GeminiSearchViewState createState() => _GeminiSearchViewState();
}

class _GeminiSearchViewState extends State<GeminiSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  Map<String, dynamic>? _searchResults;
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _selectedItem;
  bool _dataLoaded = false;

  // Variables responsive
  bool get _isSmallScreen => MediaQuery.of(context).size.width < 600;
  bool get _isVerySmallScreen => MediaQuery.of(context).size.width < 400;
  double get _horizontalPadding => _isSmallScreen ? 12.0 : 16.0;
  double get _verticalPadding => _isSmallScreen ? 8.0 : 16.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await GeminiService.initialize();
      
      setState(() {
        _isLoading = false;
        _dataLoaded = true;
      });
      
      print('📊 Estado de datos: ${GeminiService.getDataStatus()}');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando datos: $e';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    if (!_dataLoaded) {
      setState(() {
        _errorMessage = 'Los datos aún no están cargados';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = null;
      _selectedItem = null;
    });

    try {
      final results = await GeminiService.queryData(
        userQuery: _searchController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        
        if (results['type'] == 'error') {
          _errorMessage = results['data'];
        } else if (results['type'] == 'structured') {
          _searchResults = _cleanAndStructureData(results['data']);
        } else {
          _searchResults = _parseTextResponse(results['data']);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error en la búsqueda: $e';
      });
    }
  }

  Map<String, dynamic> _cleanAndStructureData(dynamic rawData) {
    if (rawData is! Map) {
      return {
        'type': 'text',
        'message': 'Formato de respuesta inválido'
      };
    }

    final Map<String, dynamic> convertedData = {};
    rawData.forEach((key, value) {
      convertedData[key.toString()] = value;
    });

    final type = convertedData['type']?.toString() ?? 'desconocido';
    final summary = convertedData['summary']?.toString() ?? 'Resumen no disponible';
    var data = convertedData['data'];

    if (data == null || data is! List) {
      data = _extractDataFromRawResponse(convertedData);
    }

    return {
      'type': type,
      'summary': summary,
      'data': data ?? []
    };
  }

  List<dynamic> _extractDataFromRawResponse(Map<String, dynamic> rawData) {
    final extractedData = <dynamic>[];
    
    rawData.forEach((key, value) {
      if (value is List) {
        extractedData.addAll(value);
      } else if (value is Map) {
        if (value.containsKey('marca') || value.containsKey('vehiculos')) {
          extractedData.add(value);
        }
        else if (value.containsKey('categoria') || value.containsKey('proyectos')) {
          extractedData.add(value);
        }
        else if (value.containsKey('nombre') && 
                (value.containsKey('consejosComunales') || 
                 value.containsKey('poblacionVotante'))) {
          extractedData.add(value);
        }
      }
    });

    return extractedData;
  }

  Map<String, dynamic> _parseTextResponse(String text) {
    try {
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = text.substring(jsonStart, jsonEnd + 1);
        final parsed = _cleanAndStructureData(json.decode(jsonString));
        if (parsed['data'] is List && (parsed['data'] as List).isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      print('No se pudo extraer JSON del texto: $e');
    }

    return {
      'type': 'text',
      'message': text
    };
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return FullScreenModal(item: item);
      },
    );
  }

  Widget _buildSearchInput() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: _isSmallScreen ? 8.0 : 0),
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Búsqueda Inteligente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
                fontSize: _isSmallScreen ? 20 : 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ejemplos: "vehículos Toyota", "proyectos de agua", "comunas con más población"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: _isSmallScreen ? 12 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_dataLoaded) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Cargando datos...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            // Diseño responsive para el campo de búsqueda
            if (_isVerySmallScreen) 
              _buildVerticalSearchLayout()
            else 
              _buildHorizontalSearchLayout(),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSearchLayout() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Escribe tu consulta...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: _isSmallScreen ? 12 : 14,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: _isSmallScreen ? 18 : 24),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = null;
                          _selectedItem = null;
                        });
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _performSearch(),
            enabled: _dataLoaded && !_isLoading,
          ),
        ),
        SizedBox(width: _isSmallScreen ? 8 : 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? SizedBox(
                  width: _isSmallScreen ? 40 : 48,
                  height: _isSmallScreen ? 40 : 48,
                  child: const CircularProgressIndicator(),
                )
              : ElevatedButton(
                  onPressed: _dataLoaded ? _performSearch : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isSmallScreen ? 16 : 24,
                      vertical: _isSmallScreen ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(_isSmallScreen ? 40 : 48, _isSmallScreen ? 40 : 48),
                  ),
                  child: Icon(
                    Icons.search,
                    size: _isSmallScreen ? 20 : 24,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVerticalSearchLayout() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Escribe tu consulta...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = null;
                        _selectedItem = null;
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _performSearch(),
          enabled: _dataLoaded && !_isLoading,
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _dataLoaded ? _performSearch : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Buscar'),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorCard(_errorMessage);
    }

    if (_searchResults == null) {
      return _buildEmptyState(
        'Realiza una búsqueda', 
        'Escribe tu consulta en el campo de búsqueda superior'
      );
    }

    if (_searchResults!['type'] == 'text') {
      return _buildTextResponse(_searchResults!['message'] ?? '');
    }

    final type = _searchResults!['type'];
    final data = _searchResults!['data'];
    final summary = _searchResults!['summary'];

    if (data == null || (data is List && data.isEmpty)) {
      return _buildEmptyState(
        'No se encontraron resultados', 
        'Intenta con otros términos de búsqueda'
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null && summary != 'Resumen no disponible')
          _buildSummaryCard(summary),
        const SizedBox(height: 12),
        Expanded(
          child: _buildStructuredResults(type, data),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red[50],
      margin: EdgeInsets.symmetric(
        horizontal: _isSmallScreen ? 4 : 8,
        vertical: 8,
      ),
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline, 
              color: Colors.red[400], 
              size: _isSmallScreen ? 36 : 48
            ),
            SizedBox(height: _isSmallScreen ? 8 : 12),
            Text(
              'Error en la búsqueda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red[800],
                fontSize: _isSmallScreen ? 16 : 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _isSmallScreen ? 6 : 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[700],
                fontSize: _isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: _isSmallScreen ? 4 : 8,
        vertical: 8,
      ),
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 20 : 32),
        child: Column(
          children: [
            Icon(
              Icons.search, 
              color: Colors.grey[400], 
              size: _isSmallScreen ? 48 : 64
            ),
            SizedBox(height: _isSmallScreen ? 12 : 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: _isSmallScreen ? 16 : 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _isSmallScreen ? 6 : 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
                fontSize: _isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextResponse(String message) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: _isSmallScreen ? 4 : 8,
        vertical: 8,
      ),
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_snippet, color: Colors.blue[600]),
                SizedBox(width: _isSmallScreen ? 6 : 8),
                Text(
                  'Respuesta en texto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: _isSmallScreen ? 16 : 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: _isSmallScreen ? 8 : 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: _isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Card(
      color: Colors.blue[50],
      margin: EdgeInsets.symmetric(
        horizontal: _isSmallScreen ? 4 : 8,
      ),
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 10 : 12),
        child: Row(
          children: [
            Icon(
              Icons.summarize, 
              color: Colors.blue[600],
              size: _isSmallScreen ? 18 : 24,
            ),
            SizedBox(width: _isSmallScreen ? 6 : 8),
            Expanded(
              child: Text(
                summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                  fontSize: _isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredResults(String type, dynamic data) {
    if (data is! List || data.isEmpty) {
      return _buildEmptyState(
        'Datos no válidos', 
        'La estructura de los datos no es la esperada'
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: _isSmallScreen ? 4 : 8,
        vertical: 8,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Padding(
          padding: EdgeInsets.only(bottom: _isSmallScreen ? 8 : 12),
          child: _buildResultCard(type, item, index),
        );
      },
    );
  }

  Widget _buildResultCard(String type, dynamic item, int index) {
    switch (type) {
      case 'vehiculos':
        return _buildVehiculoCard(item, index);
      case 'proyectos':
        return _buildProyectoCard(item, index);
      case 'comunas':
        return _buildComunaCard(item, index);
      default:
        return _buildGenericCard(item, index, type);
    }
  }

  Widget _buildVehiculoCard(dynamic item, int index) {
    final marca = item['marca']?.toString() ?? 'Marca no especificada';
    final cantidad = item['cantidad'] ?? 0;
    final vehiculos = item['vehiculos'] as List? ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car, 
                  color: Colors.blue[600],
                  size: _isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: _isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    marca,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: _isSmallScreen ? 16 : 18,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    '$cantidad',
                    style: TextStyle(
                      fontSize: _isSmallScreen ? 12 : 14,
                    ),
                  ),
                  backgroundColor: Colors.blue[100],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            SizedBox(height: _isSmallScreen ? 8 : 12),
            if (vehiculos.isNotEmpty) 
              ...vehiculos.map((vehiculo) => _buildVehiculoItem(vehiculo)).toList(),
            if (vehiculos.isEmpty)
              Text(
                'No hay vehículos detallados',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: _isSmallScreen ? 14 : 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiculoItem(Map<String, dynamic> vehiculo) {
    final placa = vehiculo['placa']?.toString() ?? 'Sin placa';
    final modelo = vehiculo['modelo']?.toString() ?? 'Modelo no especificado';
    final clase = vehiculo['clase']?.toString() ?? 'Clase no especificada';
    final estatus = vehiculo['estatus']?.toString() ?? 'Estatus desconocido';
    final comuna = vehiculo['comuna']?.toString();
    final observacion = vehiculo['observacion']?.toString();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey[50],
      child: ListTile(
        leading: Icon(
          Icons.car_rental, 
          color: Colors.blue,
          size: _isSmallScreen ? 20 : 24,
        ),
        title: Text(
          '$modelo - $placa',
          style: TextStyle(
            fontSize: _isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clase: $clase',
              style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
            ),
            Text(
              'Estatus: $estatus',
              style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
            ),
            if (comuna != null) 
              Text(
                'Comuna: $comuna',
                style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
              ),
            if (observacion != null) 
              Text(
                'Obs: ${observacion.length > 40 ? '${observacion.substring(0, 40)}...' : observacion}',
                style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: _isSmallScreen ? 14 : 16
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 12 : 16,
          vertical: _isSmallScreen ? 4 : 8,
        ),
        onTap: () => _showItemDetails({
          'type': 'vehiculo',
          'title': '$modelo - $placa',
          'data': vehiculo,
        }),
      ),
    );
  }

  Widget _buildProyectoCard(dynamic item, int index) {
    final categoria = item['categoria']?.toString() ?? 'Categoría no especificada';
    final cantidad = item['cantidad'] ?? 0;
    final proyectos = item['proyectos'] as List? ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work, 
                  color: Colors.green[600],
                  size: _isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: _isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    categoria,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: _isSmallScreen ? 16 : 18,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    '$cantidad',
                    style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
                  ),
                  backgroundColor: Colors.green[100],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            SizedBox(height: _isSmallScreen ? 8 : 12),
            if (proyectos.isNotEmpty)
              ...proyectos.map((proyecto) => _buildProyectoItem(proyecto)).toList(),
            if (proyectos.isEmpty)
              Text(
                'No hay proyectos detallados',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: _isSmallScreen ? 14 : 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProyectoItem(Map<String, dynamic> proyecto) {
    final nombre = proyecto['nombre']?.toString() ?? 'Proyecto sin nombre';
    final estatus = proyecto['estatus']?.toString() ?? 'Estatus desconocido';
    final comuna = proyecto['comuna']?.toString();
    final familias = proyecto['familiasBeneficiadas'];
    final ultimaActividad = proyecto['ultimaActividad']?.toString();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey[50],
      child: ListTile(
        leading: Icon(
          Icons.assignment, 
          color: Colors.green,
          size: _isSmallScreen ? 20 : 24,
        ),
        title: Text(
          nombre,
          style: TextStyle(
            fontSize: _isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatus: $estatus',
              style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
            ),
            if (comuna != null) 
              Text(
                'Comuna: $comuna',
                style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
              ),
            if (familias != null) 
              Text(
                'Familias: $familias',
                style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
              ),
            if (ultimaActividad != null) 
              Text(
                'Última: $ultimaActividad',
                style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: _isSmallScreen ? 14 : 16
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 12 : 16,
          vertical: _isSmallScreen ? 4 : 8,
        ),
        onTap: () => _showItemDetails({
          'type': 'proyecto',
          'title': nombre,
          'data': proyecto,
        }),
      ),
    );
  }

  Widget _buildComunaCard(dynamic item, int index) {
    final nombre = item['nombre']?.toString() ?? 'Comuna sin nombre';
    final consejosComunales = item['consejosComunales'];
    final poblacionVotante = item['poblacionVotante'];
    final proyectosActivos = item['proyectosActivos'];

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.location_city, 
          color: Colors.orange[600],
          size: _isSmallScreen ? 20 : 24,
        ),
        title: Text(
          nombre,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: _isSmallScreen ? 16 : 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (consejosComunales != null) 
              Text(
                'Consejos: $consejosComunales',
                style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
              ),
            if (poblacionVotante != null) 
              Text(
                'Población: $poblacionVotante',
                style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
              ),
            if (proyectosActivos != null) 
              Text(
                'Proyectos: $proyectosActivos',
                style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: _isSmallScreen ? 14 : 16
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 12 : 16,
          vertical: _isSmallScreen ? 8 : 12,
        ),
        onTap: () => _showItemDetails({
          'type': 'comuna',
          'title': nombre,
          'data': item,
        }),
      ),
    );
  }

  Widget _buildGenericCard(dynamic item, int index, String type) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.category, 
          color: Colors.purple[600],
          size: _isSmallScreen ? 20 : 24,
        ),
        title: Text(
          'Item ${index + 1}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: _isSmallScreen ? 16 : 18,
          ),
        ),
        subtitle: Text(
          'Tipo: $type',
          style: TextStyle(fontSize: _isSmallScreen ? 12 : 14),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: _isSmallScreen ? 14 : 16
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 12 : 16,
          vertical: _isSmallScreen ? 8 : 12,
        ),
        onTap: () => _showItemDetails({
          'type': type,
          'title': 'Item ${index + 1}',
          'data': item is Map ? item : {'valor': item.toString()},
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda Inteligente'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _isSmallScreen ? 8.0 : 16.0,
            vertical: _isSmallScreen ? 8.0 : 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchInput(),
              SizedBox(height: _isSmallScreen ? 16 : 20),
              Expanded(
                child: _isLoading && !_dataLoaded
                    ? const Center(child: CircularProgressIndicator())
                    : _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Nuevo widget para el modal a pantalla completa
class FullScreenModal extends StatelessWidget {
  final Map<String, dynamic> item;

  const FullScreenModal({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final type = item['type'];
    final title = item['title'];
    final data = item['data'] as Map<String, dynamic>;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Detalles del ${_getTypeName(type)}',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, size: isSmallScreen ? 24 : 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [

            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del modal
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: isSmallScreen ? 32 : 40,
                          color: Colors.blue[700],
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tipo: ${_getTypeName(type)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Detalles
                  Text(
                    'Información Detallada',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  ..._buildDetailFields(data, isSmallScreen),
                  
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Botones de acción
                  if (type == 'vehiculo') _buildVehiculoActions(),
                  if (type == 'proyecto') _buildProyectoActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailFields(Map<String, dynamic> data, bool isSmallScreen) {
    final fields = <Widget>[];
    final validEntries = data.entries.where((entry) => 
        entry.value != null && 
        entry.key != 'type' && 
        entry.key != 'title').toList();

    if (validEntries.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              'No hay información adicional disponible',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    for (final entry in validEntries) {
      fields.addAll([
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '${_capitalize(entry.key)}:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  entry.value.toString(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ]);
    }

    return fields;
  }

  Widget _buildVehiculoActions() {
    return Row(
      children: [
      ],
    );
  }

  Widget _buildProyectoActions() {
    return Row(
      children: [
        SizedBox(width: 12),
      ],
    );
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'vehiculo': return 'Vehículo';
      case 'proyecto': return 'Proyecto';
      case 'comuna': return 'Comuna';
      default: return 'Elemento';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'vehiculo': return Icons.directions_car;
      case 'proyecto': return Icons.work;
      case 'comuna': return Icons.location_city;
      default: return Icons.category;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}