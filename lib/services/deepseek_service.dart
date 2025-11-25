import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  // Para testing, puedes usar esta API key temporal o configurar la tuya
  static const String _apiKey = 'sk-ab49c7ffd155413a8c33a2a7fbf034c9'; // Reemplaza con tu API key real
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  static Future<String> queryData({
    required String userQuery,
    required String proyectosJson,
    required String comunasJson,
    required String vehiculosJson,
  }) async {
    try {
      print('🔍 Iniciando consulta a DeepSeek...');
      print('📝 Query del usuario: $userQuery');
      
      final prompt = _buildPrompt(userQuery, proyectosJson, comunasJson, vehiculosJson);
      
      print('📤 Enviando request a la API...');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un asistente especializado en análisis de datos de comunas, proyectos y vehículos. Proporciona respuestas precisas basadas EXCLUSIVAMENTE en los datos JSON proporcionados. Si no hay datos para la consulta, indica que no se encontró información.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.1,
          'max_tokens': 2000
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['choices'][0]['message']['content'];
        print('✅ Resultado obtenido: $result');
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('Error de autenticación. Verifica tu API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Límite de solicitudes excedido. Intenta más tarde.');
      } else {
        throw Exception('Error en la API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en DeepSeekService: $e');
      throw Exception('Error al conectar con el servicio: $e');
    }
  }

  static String _buildPrompt(
    String userQuery, 
    String proyectosJson, 
    String comunasJson, 
    String vehiculosJson
  ) {
    // Limitar el tamaño de los JSON para no exceder límites de tokens
    final proyectosLimitados = _limitJsonSize(proyectosJson, 3000);
    final comunasLimitadas = _limitJsonSize(comunasJson, 3000);
    final vehiculosLimitados = _limitJsonSize(vehiculosJson, 2000);

    return '''
Consulta del usuario: "$userQuery"

Datos disponibles (RESPONDE SOLO CON ESTOS DATOS):

PROYECTOS (proyectos.json):
$proyectosLimitados

COMUNAS (comunas.json):
$comunasLimitadas

VEHÍCULOS (vehiculos.json):
$vehiculosLimitados

Instrucciones CRÍTICAS:
1. Responde ÚNICAMENTE con la información contenida en los JSON proporcionados
2. Si no hay datos para la consulta, di: "No se encontraron datos que coincidan con tu búsqueda"
3. Sé específico y cita números, nombres y fechas exactas de los JSON
4. Formatea la respuesta de manera clara con saltos de línea
5. No inventes información que no esté en los JSON
6. Para consultas de ubicación, usa los datos de "linderoNorte", "linderoSur", etc.

Ejemplo de respuesta para "proyectos en Comuna El Paraíso":
"En Comuna El Paraíso se encontraron 2 proyectos:
- Construcción de Escuela Primaria (EN EJECUCIÓN)
- Vialidad Principal (INCONCLUSO)
Total: 2 proyectos"

Responde en español de manera concisa y útil.
''';
  }

  static String _limitJsonSize(String jsonString, int maxLength) {
    if (jsonString.length <= maxLength) return jsonString;
    return jsonString.substring(0, maxLength) + '... [DATOS TRUNCADOS POR LÍMITE]';
  }
}