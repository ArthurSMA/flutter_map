// Modelo de dados (LocalSalvo)

import 'package:latlong2/latlong.dart';

class LocalSalvo {
  final String nome;
  final String descricao;
  final LatLng coordenada;
  double? distanciaMetros; // Para guardar o cálculo da rota viária
  List<LatLng>? rotaPontos; // Lista de coordenadas para desenhar a linha no mapa

  LocalSalvo({
    required this.nome,
    required this.descricao,
    required this.coordenada,
    this.distanciaMetros,
    this.rotaPontos,
  });
}
