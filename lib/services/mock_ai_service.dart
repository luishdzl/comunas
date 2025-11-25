import 'dart:convert';

class MockAIService {
  static Future<dynamic> queryData({
    required String userQuery,
    required String proyectosJson,
    required String comunasJson,
    required String vehiculosJson,
  }) async {
    // Simular procesamiento
    await Future.delayed(Duration(seconds: 1));

    final query = userQuery.toLowerCase();
    print('🔍 Mock: Procesando query: "$query"');
    
    // Respuesta estructurada para vehículos
    if (query.contains('vehículo') || query.contains('auto') || query.contains('marca') || query.contains('vehiculo')) {
      return {
        'type': 'vehiculos',
        'summary': 'Vehículos activos por marca (Datos de ejemplo)',
        'data': [
          {
            'marca': 'Toyota',
            'cantidad': 1,
            'vehiculos': [
              {
                'placa': 'ABC123',
                'modelo': 'Hilux',
                'clase': 'Camioneta',
                'estatus': 'asignado',
                'comuna': 'Comuna Sabana Grande',
                'observacion': 'Vehículo para visitas técnicas'
              }
            ]
          },
          {
            'marca': 'Nissan',
            'cantidad': 0,
            'vehiculos': []
          },
          {
            'marca': 'Ford',
            'cantidad': 1,
            'vehiculos': [
              {
                'placa': 'HIJ456',
                'modelo': 'Transit',
                'clase': 'Furgoneta',
                'estatus': 'asignado',
                'comuna': 'Comuna Altamira',
                'observacion': 'Transporte de personal'
              }
            ]
          }
        ]
      };
    }
    
    // Respuesta estructurada para proyectos
    else if (query.contains('proyecto')) {
      return {
        'type': 'proyectos',
        'summary': 'Proyectos encontrados (Datos de ejemplo)',
        'data': [
          {
            'categoria': 'Cultura',
            'cantidad': 1,
            'proyectos': [
              {
                'id': '22',
                'nombre': 'Casa de la Cultura',
                'estatus': 'EN EJECUCIÓN',
                'comuna': 'Comuna Sabana Grande',
                'familiasBeneficiadas': 340,
                'ultimaActividad': '2024-06-24'
              }
            ]
          },
          {
            'categoria': 'Seguridad',
            'cantidad': 1,
            'proyectos': [
              {
                'id': '23',
                'nombre': 'Sistema de Cámaras de Seguridad',
                'estatus': 'APROBADO',
                'comuna': 'Comuna Chacao',
                'familiasBeneficiadas': 520,
                'ultimaActividad': '2024-06-20'
              }
            ]
          }
        ]
      };
    }
    
    // Respuesta estructurada para comunas
    else if (query.contains('comuna')) {
      return {
        'type': 'comunas',
        'summary': 'Comunas encontradas (Datos de ejemplo)',
        'data': [
          {
            'nombre': 'Comuna Los Palos Grandes',
            'consejosComunales': 9,
            'poblacionVotante': 7300,
            'proyectosActivos': 2
          },
          {
            'nombre': 'Comuna La Castellana',
            'consejosComunales': 7,
            'poblacionVotante': 5800,
            'proyectosActivos': 3
          },
          {
            'nombre': 'Comuna La Florida',
            'consejosComunales': 11,
            'poblacionVotante': 8900,
            'proyectosActivos': 1
          }
        ]
      };
    }
    
    // Respuesta de texto plano por defecto - AHORA EN FORMATO MAP
    return {
      'type': 'text',
      'message': '''
🤖 **Búsqueda Inteligente (Modo Demo)**

📋 **Consulta:** "$userQuery"

📊 **Resultados de ejemplo:**

• **Vehículos activos:** 3 vehículos
  - Toyota: 1 vehículo (Hilux - ABC123)
  - Nissan: 0 vehículos  
  - Ford: 1 vehículo (Transit - HIJ456)

• **Proyectos en ejecución:** 2 proyectos
  - Casa de la Cultura (Cultura)
  - Sistema de Cámaras (Seguridad)

• **Comunas activas:** 3 comunas
  - Comuna Los Palos Grandes: 7,300 habitantes
  - Comuna La Castellana: 5,800 habitantes
  - Comuna La Florida: 8,900 habitantes

💡 *Esta es una respuesta de demostración con datos de ejemplo.*
'''
    };
  }
}