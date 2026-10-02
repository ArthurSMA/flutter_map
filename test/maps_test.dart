import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_flutter/models/local.dart';
import 'package:map_flutter/pages/maps.dart';
import 'package:map_flutter/services/osrm_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  testWidgets('clique no mapa abre o formulário e salva um marcador',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: MapScreen()));

    await tester.tap(find.byType(FlutterMap));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar Local'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Casa');
    await tester.enterText(find.byType(TextField).last, 'Ponto inicial');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers, hasLength(1));
    expect(find.text('Cadastrar Local'), findsNothing);
  });

  testWidgets('renderiza PolylineLayer ao selecionar uma rota', (tester) async {
    final client = MockHttpClient();
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response(
        '{"routes":[{"distance":1000,"geometry":{"coordinates":[[-46.63,-23.55],[-46.62,-23.54]]}}]}',
        200,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: MapScreen(osrmService: OSRMService(client: client))),
    );

    await _cadastrarLocal(tester, 'Origem');
    await _cadastrarLocal(tester, 'Destino');
    await tester.tap(find.byTooltip('Calcular mais próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Calcular Ponto Mais Próximo'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<LocalSalvo>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Origem').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Destino'));
    await tester.pumpAndSettle();

    final polylineLayer = tester.widget<PolylineLayer>(
      find.byType(PolylineLayer),
    );
    expect(polylineLayer.polylines, hasLength(1));
    expect(polylineLayer.polylines.single.points, hasLength(2));
  });
}

Future<void> _cadastrarLocal(WidgetTester tester, String nome) async {
  await tester.tap(find.byType(FlutterMap));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, nome);
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();
}