import 'package:flutter/material.dart';
import 'gemini_service.dart';

class GeminiSearchView extends StatefulWidget {
  final String proyectosJson;
  final String comunasJson;
  final String vehiculosJson;

  const GeminiSearchView({
    Key? key,
    required this.proyectosJson,
    required this.comunasJson,
    required this.vehiculosJson,
  }) : super(key: key);

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = null;
      _selectedItem = null;
    });

    try {
      final results = await GeminiService.queryData(
        userQuery: _searchController.text.trim(),
        proyectosJson: widget.proyectosJson,
        comunasJson: widget.comunasJson,
        vehiculosJson: widget.vehiculosJson,
      );

      setState(() {
        _isLoading = false;
        
        if (results['type'] == 'error') {
          _errorMessage = results['data'];
        } else if (results['type'] == 'structured') {
          _searchResults = results['data'];
        } else {
          _searchResults = {
            'type': 'text',
            'message': results['data']
          };
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error en la búsqueda: $e';
      });
    }
  }

  void _showItemDetails(Map<String, dynamic> item) {
    setState(() {
      _selectedItem = item;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItem = null;
    });
  }

  Widget _buildSearchInput() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Búsqueda Inteligente',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes preguntar: "vehículos Toyota", "proyectos de agua", "comunas con más de X población"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu consulta aquí...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _performSearch,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Buscar'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 12),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.search, color: Colors.grey[400], size: 64),
              const SizedBox(height: 16),
              Text(
                'Realiza una búsqueda',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escribe tu consulta en el campo de búsqueda superior',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si es texto plano
    if (_searchResults!['type'] == 'text') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_searchResults!['message'] ?? ''),
        ),
      );
    }

    // Si es respuesta estructurada
    final type = _searchResults!['type'];
    final data = _searchResults!['data'];
    final summary = _searchResults!['summary'];

    if (data == null || (data is List && data.isEmpty)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.search_off, color: Colors.grey[400], size: 64),
              const SizedBox(height: 16),
              Text(
                'No se encontraron resultados',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null)
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        _buildResultsList(type, data),
      ],
    );
  }

  Widget _buildResultsList(String type, dynamic data) {
    if (data is! List) return const SizedBox();

    switch (type) {
      case 'vehiculos':
        return _buildVehiculosList(data);
      case 'proyectos':
        return _buildProyectosList(data);
      case 'comunas':
        return _buildComunasList(data);
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Tipo de resultado no reconocido: $type'),
          ),
        );
    }
  }

  Widget _buildVehiculosList(List<dynamic> data) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final marcaData = data[index];
        final marca = marcaData['marca'];
        final cantidad = marcaData['cantidad'];
        final vehiculos = marcaData['vehiculos'] as List? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: const Icon(Icons.directions_car, color: Colors.blue),
            title: Text('$marca ($cantidad vehículos)'),
            subtitle: Text('${vehiculos.length} vehículos encontrados'),
            children: vehiculos.map((vehiculo) {
              return ListTile(
                leading: const Icon(Icons.car_rental, size: 20),
                title: Text('${vehiculo['modelo']} - ${vehiculo['placa']}'),
                subtitle: Text('Clase: ${vehiculo['clase']} - Estatus: ${vehiculo['estatus']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showItemDetails({
                  'type': 'vehiculo',
                  'title': '${vehiculo['modelo']} - ${vehiculo['placa']}',
                  'data': vehiculo,
                }),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildProyectosList(List<dynamic> data) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final categoriaData = data[index];
        final categoria = categoriaData['categoria'];
        final cantidad = categoriaData['cantidad'];
        final proyectos = categoriaData['proyectos'] as List? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: const Icon(Icons.work, color: Colors.green),
            title: Text('$categoria ($cantidad proyectos)'),
            subtitle: Text('${proyectos.length} proyectos encontrados'),
            children: proyectos.map((proyecto) {
              return ListTile(
                leading: const Icon(Icons.assignment, size: 20),
                title: Text(proyecto['nombre']),
                subtitle: Text('Estatus: ${proyecto['estatus']} - Comuna: ${proyecto['comuna']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showItemDetails({
                  'type': 'proyecto',
                  'title': proyecto['nombre'],
                  'data': proyecto,
                }),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildComunasList(List<dynamic> data) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final comuna = data[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.location_city, color: Colors.orange),
            title: Text(comuna['nombre']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consejos comunales: ${comuna['consejosComunales']}'),
                Text('Población votante: ${comuna['poblacionVotante']}'),
                if (comuna['proyectosActivos'] != null)
                  Text('Proyectos activos: ${comuna['proyectosActivos']}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showItemDetails({
              'type': 'comuna',
              'title': comuna['nombre'],
              'data': comuna,
            }),
          ),
        );
      },
    );
  }

  Widget _buildItemDetails() {
    if (_selectedItem == null) return const SizedBox();

    final type = _selectedItem!['type'];
    final title = _selectedItem!['title'];
    final data = _selectedItem!['data'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),
            ..._buildDetailFields(type, data),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailFields(String type, Map<String, dynamic> data) {
    final fields = <Widget>[];

    data.forEach((key, value) {
      if (value != null) {
        fields.addAll([
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '${_capitalize(key)}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ]);
      }
    });

    return fields;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda Inteligente'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchInput(),
            const SizedBox(height: 20),
            if (_selectedItem != null) ...[
              _buildItemDetails(),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: _buildResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}