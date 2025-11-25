import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
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
  bool _dataLoaded = false;
  
  // Variables para selección múltiple
  Set<String> _selectedItems = Set<String>();
  bool _isSelectionMode = false;

  // Variables responsive
  bool get _isSmallScreen => MediaQuery.of(context).size.width < 600;
  bool get _isVerySmallScreen => MediaQuery.of(context).size.width < 400;

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
      _selectedItems.clear();
      _isSelectionMode = false;
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(item: item),
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
      
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllItems() {
    setState(() {
      if (_searchResults != null && _searchResults!['data'] is List) {
        final data = _searchResults!['data'] as List;
        for (int i = 0; i < data.length; i++) {
          _selectedItems.add('item_$i');
        }
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _exportToExcel() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona al menos un item para exportar')),
      );
      return;
    }

    try {
      // Para Android/iOS, solicitar permisos
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      final data = _searchResults!['data'] as List;
      final selectedIndexes = _selectedItems.map((id) => int.parse(id.split('_')[1])).toList();
      final selectedData = selectedIndexes.map((index) => data[index]).toList();
      
      // Crear contenido CSV
      String csvContent = _convertToCsv(selectedData, _searchResults!['type']);
      
      // Guardar archivo temporalmente
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/exportacion_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent);
      
      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Exportación de datos - ${DateTime.now().toString()}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Archivo exportado y listo para compartir')),
      );

      _clearSelection();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al exportar: $e')),
      );
    }
  }

  String _convertToCsv(List<dynamic> data, String type) {
    switch (type) {
      case 'vehiculos':
        return _buildVehiculosCsv(data);
      case 'proyectos':
        return _buildProyectosCsv(data);
      case 'comunas':
        return _buildComunasCsv(data);
      default:
        return _buildGenericCsv(data, type);
    }
  }

  String _buildVehiculosCsv(List<dynamic> data) {
    List<List<dynamic>> rows = [];
    // Encabezados
    rows.add(['Marca', 'Cantidad', 'Placa', 'Modelo', 'Clase', 'Estatus', 'Comuna', 'Observacion']);
    
    for (var item in data) {
      final marca = item['marca']?.toString() ?? '';
      final cantidad = item['cantidad']?.toString() ?? '';
      final vehiculos = item['vehiculos'] as List? ?? [];
      
      for (var vehiculo in vehiculos) {
        rows.add([
          marca,
          cantidad,
          vehiculo['placa'] ?? '',
          vehiculo['modelo'] ?? '',
          vehiculo['clase'] ?? '',
          vehiculo['estatus'] ?? '',
          vehiculo['comuna'] ?? '',
          vehiculo['observacion'] ?? ''
        ]);
      }
    }
    
    return const ListToCsvConverter().convert(rows);
  }

  String _buildProyectosCsv(List<dynamic> data) {
    List<List<dynamic>> rows = [];
    // Encabezados
    rows.add(['Categoria', 'Cantidad', 'ID', 'Nombre', 'Estatus', 'Comuna', 'Familias Beneficiadas', 'Ultima Actividad']);
    
    for (var item in data) {
      final categoria = item['categoria']?.toString() ?? '';
      final cantidad = item['cantidad']?.toString() ?? '';
      final proyectos = item['proyectos'] as List? ?? [];
      
      for (var proyecto in proyectos) {
        rows.add([
          categoria,
          cantidad,
          proyecto['id'] ?? '',
          proyecto['nombre'] ?? '',
          proyecto['estatus'] ?? '',
          proyecto['comuna'] ?? '',
          proyecto['familiasBeneficiadas'] ?? '',
          proyecto['ultimaActividad'] ?? ''
        ]);
      }
    }
    
    return const ListToCsvConverter().convert(rows);
  }

  String _buildComunasCsv(List<dynamic> data) {
    List<List<dynamic>> rows = [];
    // Encabezados
    rows.add(['Nombre', 'Consejos Comunales', 'Poblacion Votante', 'Proyectos Activos']);
    
    for (var item in data) {
      rows.add([
        item['nombre'] ?? '',
        item['consejosComunales'] ?? '',
        item['poblacionVotante'] ?? '',
        item['proyectosActivos'] ?? ''
      ]);
    }
    
    return const ListToCsvConverter().convert(rows);
  }

  String _buildGenericCsv(List<dynamic> data, String type) {
    List<List<dynamic>> rows = [];
    rows.add(['Tipo', 'Index', 'Valor']);
    
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      rows.add([
        type,
        i + 1,
        item.toString()
      ]);
    }
    
    return const ListToCsvConverter().convert(rows);
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
                          _selectedItems.clear();
                          _isSelectionMode = false;
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
                        _selectedItems.clear();
                        _isSelectionMode = false;
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
        if (_isSelectionMode) _buildSelectionToolbar(),
        const SizedBox(height: 12),
        Expanded(
          child: _buildStructuredResults(type, data),
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar() {
    return Card(
      color: Colors.blue[50],
      margin: EdgeInsets.symmetric(
        horizontal: _isSmallScreen ? 4 : 8,
        vertical: 8,
      ),
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 8 : 12),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.blue[700],
              size: _isSmallScreen ? 18 : 24,
            ),
            SizedBox(width: _isSmallScreen ? 6 : 8),
            Text(
              '${_selectedItems.length} seleccionados',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: _isSmallScreen ? 14 : 16,
              ),
            ),
            Spacer(),
            if (_selectedItems.isNotEmpty)
              TextButton.icon(
                onPressed: _exportToExcel,
                icon: Icon(Icons.download, size: _isSmallScreen ? 16 : 20),
                label: Text(
                  'Exportar',
                  style: TextStyle(fontSize: _isSmallScreen ? 14 : 16),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green[700],
                ),
              ),
            SizedBox(width: _isSmallScreen ? 8 : 12),
            TextButton.icon(
              onPressed: _clearSelection,
              icon: Icon(Icons.clear, size: _isSmallScreen ? 16 : 20),
              label: Text(
                'Cancelar',
                style: TextStyle(fontSize: _isSmallScreen ? 14 : 16),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
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
    final itemId = 'item_$index';
    final isSelected = _selectedItems.contains(itemId);

    switch (type) {
      case 'vehiculos':
        return _buildVehiculoCard(item, index, isSelected, itemId);
      case 'proyectos':
        return _buildProyectoCard(item, index, isSelected, itemId);
      case 'comunas':
        return _buildComunaCard(item, index, isSelected, itemId);
      default:
        return _buildGenericCard(item, index, type, isSelected, itemId);
    }
  }

  Widget _buildVehiculoCard(dynamic item, int index, bool isSelected, String itemId) {
    final marca = item['marca']?.toString() ?? 'Marca no especificada';
    final cantidad = item['cantidad'] ?? 0;
    final vehiculos = item['vehiculos'] as List? ?? [];

    return Card(
      elevation: 2,
      color: isSelected ? Colors.blue[50] : null,
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isSelectionMode) 
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleItemSelection(itemId),
                  ),
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
              ...vehiculos.asMap().entries.map((entry) => 
                _buildVehiculoItem(entry.value, index, entry.key)
              ).toList(),
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

  Widget _buildVehiculoItem(Map<String, dynamic> vehiculo, int parentIndex, int childIndex) {
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
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
          }
        },
      ),
    );
  }

  Widget _buildProyectoCard(dynamic item, int index, bool isSelected, String itemId) {
    final categoria = item['categoria']?.toString() ?? 'Categoría no especificada';
    final cantidad = item['cantidad'] ?? 0;
    final proyectos = item['proyectos'] as List? ?? [];

    return Card(
      elevation: 2,
      color: isSelected ? Colors.green[50] : null,
      child: Padding(
        padding: EdgeInsets.all(_isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isSelectionMode) 
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleItemSelection(itemId),
                  ),
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
              ...proyectos.asMap().entries.map((entry) => 
                _buildProyectoItem(entry.value, index, entry.key)
              ).toList(),
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

  Widget _buildProyectoItem(Map<String, dynamic> proyecto, int parentIndex, int childIndex) {
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
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
          }
        },
      ),
    );
  }

  Widget _buildComunaCard(dynamic item, int index, bool isSelected, String itemId) {
    final nombre = item['nombre']?.toString() ?? 'Comuna sin nombre';
    final consejosComunales = item['consejosComunales'];
    final poblacionVotante = item['poblacionVotante'];
    final proyectosActivos = item['proyectosActivos'];

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: isSelected ? Colors.orange[50] : null,
      child: ListTile(
        leading: _isSelectionMode 
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleItemSelection(itemId),
              )
            : Icon(
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
        trailing: _isSelectionMode ? null : Icon(
          Icons.arrow_forward_ios, 
          size: _isSmallScreen ? 14 : 16
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 12 : 16,
          vertical: _isSmallScreen ? 8 : 12,
        ),
        onTap: _isSelectionMode 
            ? () => _toggleItemSelection(itemId)
            : () => _showItemDetails({
                'type': 'comuna',
                'title': nombre,
                'data': item,
              }),
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleItemSelection(itemId);
          }
        },
      ),
    );
  }

  Widget _buildGenericCard(dynamic item, int index, String type, bool isSelected, String itemId) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: isSelected ? Colors.purple[50] : null,
      child: ListTile(
        leading: _isSelectionMode 
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleItemSelection(itemId),
              )
            : Icon(
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
        trailing: _isSelectionMode ? null : Icon(
          Icons.arrow_forward_ios, 
          size: _isSmallScreen ? 14 : 16
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isSmallScreen ? 12 : 16,
          vertical: _isSmallScreen ? 8 : 12,
        ),
        onTap: _isSelectionMode 
            ? () => _toggleItemSelection(itemId)
            : () => _showItemDetails({
                'type': type,
                'title': 'Item ${index + 1}',
                'data': item is Map ? item : {'valor': item.toString()},
              }),
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleItemSelection(itemId);
          }
        },
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
        actions: [
          if (_searchResults != null && _searchResults!['type'] != 'text')
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.deselect : Icons.select_all),
              onPressed: _isSelectionMode ? _clearSelection : _selectAllItems,
              tooltip: _isSelectionMode ? 'Cancelar selección' : 'Seleccionar todo',
            ),
        ],
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

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const DetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final type = item['type'];
    final title = item['title'];
    final data = item['data'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del ${_getTypeName(type)}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareDetails(context, item),
            tooltip: 'Compartir detalles',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tipo: ${_getTypeName(type)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              ..._buildDetailFields(data),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailFields(Map<String, dynamic> data) {
    final fields = <Widget>[];
    final validEntries = data.entries.where((entry) => 
        entry.value != null).toList();

    if (validEntries.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay información adicional disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    for (final entry in validEntries) {
      fields.addAll([
        SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalize(entry.key),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  entry.value.toString(),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ]);
    }

    return fields;
  }

  Future<void> _shareDetails(BuildContext context, Map<String, dynamic> item) async {
    final type = item['type'];
    final title = item['title'];
    final data = item['data'] as Map<String, dynamic>;
    
    String shareText = 'Detalles del ${_getTypeName(type)}\n\n';
    shareText += 'Título: $title\n\n';
    
    data.forEach((key, value) {
      if (value != null) {
        shareText += '${_capitalize(key)}: $value\n';
      }
    });
    
    await Share.share(shareText);
  }
}

String _getTypeName(String type) {
  switch (type) {
    case 'vehiculo': return 'Vehículo';
    case 'proyecto': return 'Proyecto';
    case 'comuna': return 'Comuna';
    default: return 'Elemento';
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}