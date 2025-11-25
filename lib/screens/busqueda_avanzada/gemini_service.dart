// gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyC_dxZRgrNsljTBwKF9U60WACoMy4J9z40'; 
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent';

  static Future<Map<String, dynamic>> queryData({
    required String userQuery,
    required String proyectosJson,
    required String comunasJson,
    required String vehiculosJson,
  }) async {
    try {
      print('🔍 Iniciando consulta a Gemini 2.0 Flash Lite...');
      print('📝 Query: $userQuery');
      
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      final prompt = _buildStructuredPrompt(userQuery, proyectosJson, comunasJson, vehiculosJson);
      
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
        'data': '❌ Error de conexión: $e',
        'rawText': 'Error de conexión'
      };
    }
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