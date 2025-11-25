// gemini_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyC_dxZRgrNsljTBwKF9U60WACoMy4J9z40'; 
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent';

  // Variables para almacenar los JSONs cargados
  static String? _proyectosJson;
  static String? _comunasJson;
  static String? _vehiculosJson;
  static bool _isInitialized = false;

  // Método para inicializar y cargar todos los JSONs
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('📂 Cargando archivos JSON...');
      
      _proyectosJson = await _loadJsonFile('lib/assets/proyectos.json');
      _comunasJson = await _loadJsonFile('lib/assets/comunas.json');
      _vehiculosJson = await _loadJsonFile('lib/assets/vehiculos.json');
      
      _isInitialized = true;
      print('✅ Archivos JSON cargados exitosamente');
      print('📊 Proyectos: ${_proyectosJson?.length ?? 0} caracteres');
      print('📊 Comunas: ${_comunasJson?.length ?? 0} caracteres');
      print('📊 Vehículos: ${_vehiculosJson?.length ?? 0} caracteres');
      
    } catch (e) {
      print('❌ Error cargando archivos JSON: $e');
      rethrow;
    }
  }

  // Método para cargar un archivo JSON
  static Future<String> _loadJsonFile(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      print('❌ Error cargando $path: $e');
      // Si falla con rootBundle, intentar con File (para debugging)
      try {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (e2) {
        print('❌ También falló carga con File: $e2');
      }
      rethrow;
    }
  }

  // Método principal de consulta modificado
  static Future<Map<String, dynamic>> queryData({
    required String userQuery,
  }) async {
    try {
      // Verificar que los JSONs estén cargados
      if (!_isInitialized) {
        await initialize();
      }

      // Verificar que tenemos todos los datos
      if (_proyectosJson == null || _comunasJson == null || _vehiculosJson == null) {
        throw Exception('No se pudieron cargar los archivos JSON');
      }

      print('🔍 Iniciando consulta a Gemini 2.0 Flash Lite...');
      print('📝 Query: $userQuery');
      
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      final prompt = _buildStructuredPrompt(
        userQuery, 
        _proyectosJson!, 
        _comunasJson!, 
        _vehiculosJson!
      );
      
      print('📤 Enviando request...');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.1,
            'topP': 0.8,
            'topK': 40,
            'maxOutputTokens': 2048,
          }
        }),
      );

      print('📥 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Respuesta recibida correctamente');
        
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty && 
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final result = data['candidates'][0]['content']['parts'][0]['text'];
          print('📄 Resultado length: ${result.length} caracteres');
          
          // Intentar parsear como JSON estructurado
          try {
            final parsedResult = jsonDecode(result);
            return {
              'type': 'structured',
              'data': parsedResult,
              'rawText': result
            };
          } catch (e) {
            // Si no es JSON, devolver como texto
            return {
              'type': 'text',
              'data': result,
              'rawText': result
            };
          }
        } else {
          return {
            'type': 'error',
            'data': '❌ No se pudo extraer el texto de la respuesta del modelo.',
            'rawText': 'Error en estructura de respuesta'
          };
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return {
          'type': 'error',
          'data': '❌ Error HTTP ${response.statusCode}',
          'rawText': 'Error de conexión'
        };
      }
    } catch (e) {
      print('❌ Error en GeminiService: $e');
      return {
        'type': 'error',
        'data': '❌ Error en el servicio: $e',
        'rawText': 'Error de conexión'
      };
    }
  }

  // Método para verificar el estado de los datos
  static Map<String, dynamic> getDataStatus() {
    return {
      'initialized': _isInitialized,
      'proyectos_loaded': _proyectosJson != null,
      'comunas_loaded': _comunasJson != null,
      'vehiculos_loaded': _vehiculosJson != null,
      'proyectos_length': _proyectosJson?.length ?? 0,
      'comunas_length': _comunasJson?.length ?? 0,
      'vehiculos_length': _vehiculosJson?.length ?? 0,
    };
  }

  static String _buildStructuredPrompt(
    String userQuery, 
    String proyectosJson, 
    String comunasJson, 
    String vehiculosJson
  ) {
    return '''
Analiza estos datos JSON y responde esta consulta: "$userQuery"

DATOS JSON:

PROYECTOS:
$proyectosJson

COMUNAS:
$comunasJson

VEHÍCULOS:
$vehiculosJson

IMPORTANTE: Responde SOLO con un objeto JSON válido con esta estructura:

Para consultas sobre vehículos:
{
  "type": "vehiculos",
  "summary": "Resumen general",
  "data": [
    {
      "marca": "Toyota",
      "cantidad": 1,
      "vehiculos": [
        {
          "placa": "ABC123",
          "modelo": "Hilux",
          "clase": "Camioneta",
          "estatus": "asignado",
          "comuna": "Comuna Sabana Grande",
          "observacion": "Vehículo para visitas técnicas"
        }
      ]
    }
  ]
}

Para consultas sobre proyectos:
{
  "type": "proyectos", 
  "summary": "Resumen general",
  "data": [
    {
      "categoria": "Cultura",
      "cantidad": 1,
      "proyectos": [
        {
          "id": "22",
          "nombre": "Casa de la Cultura",
          "estatus": "EN EJECUCIÓN",
          "comuna": "Comuna Sabana Grande",
          "familiasBeneficiadas": 340,
          "ultimaActividad": "2024-06-24"
        }
      ]
    }
  ]
}

Para consultas sobre comunas:
{
  "type": "comunas",
  "summary": "Resumen general", 
  "data": [
    {
      "nombre": "Comuna Los Palos Grandes",
      "consejosComunales": 9,
      "poblacionVotante": 7300,
      "proyectosActivos": 2
    }
  ]
}

Si no puedes estructurar la respuesta, devuelve un objeto con type "text" y un campo "message" con la respuesta en texto plano.

SOLO DEVUELVE EL JSON, SIN TEXTO ADICIONAL.
''';
  }
}