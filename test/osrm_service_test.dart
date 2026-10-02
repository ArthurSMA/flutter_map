import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_flutter/services/osrm_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  test('calcula a distância e converte GeoJSON para LatLng', () async {
    final client = MockHttpClient();
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response(
        '{"routes":[{"distance":1234.5,"geometry":{"coordinates":[[-46.63,-23.55],[-46.62,-23.54]]}}]}',
        200,
      ),
    );

    final resultado = await OSRMService(client: client).obterRotaViaria(
      const LatLng(-23.55, -46.63),
      const LatLng(-23.54, -46.62),
    );

    expect(resultado, isNotNull);
    expect(resultado!.distanciaMetros, 1234.5);
    expect(resultado.pontosRota, [
      const LatLng(-23.55, -46.63),
      const LatLng(-23.54, -46.62),
    ]);
    verify(() => client.get(any())).called(1);
  });

  test('retorna null quando a API não encontra rotas', () async {
    final client = MockHttpClient();
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response('{"routes":[]}', 200),
    );

    final resultado = await OSRMService(client: client).obterRotaViaria(
      const LatLng(-23.55, -46.63),
      const LatLng(-23.54, -46.62),
    );

    expect(resultado, isNull);
  });
}