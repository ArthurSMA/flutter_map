// Comunicação com a API de rotas OSRM

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ResultadoRota {
  final double distanciaMetros;
  final List<LatLng> pontosRota;

  ResultadoRota({required this.distanciaMetros, required this.pontosRota});
}

class OSRMService {
  final http.Client _client;

  OSRMService({http.Client? client}) : _client = client ?? http.Client();

  /// Consulta a API OSRM e retorna a distância + os pontos geométricos do trajeto
  Future<ResultadoRota?> obterRotaViaria(
    LatLng origem,
    LatLng destino,
  ) async {
    final url = Uri.parse(
      'https://routing.openstreetmap.de/routed-car/route/v1/driving/'
      '${origem.longitude},${origem.latitude};${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson', // <--- Importante para retornar as linhas da rua
    );

    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final double distancia = (route['distance'] as num).toDouble();
          
          // Extrai as coordenadas da geometria (GeoJSON vem em [longitude, latitude])
          final List coordinates = route['geometry']['coordinates'];
          final List<LatLng> pontos = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          return ResultadoRota(distanciaMetros: distancia, pontosRota: pontos);
        }
      }
    } catch (e) {
      debugPrint('Erro na consulta OSRM: $e');
    }
    return null;
  }
}
