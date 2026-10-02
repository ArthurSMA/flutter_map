import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/local.dart';
import '../services/osrm_service.dart';
import '../widgets/comparador_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  final OSRMService osrmService;

    MapScreen({super.key, OSRMService? osrmService})
      : osrmService = osrmService ?? OSRMService();

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<LocalSalvo> _locais = [];
  List<LatLng> _rotaParaExibir = []; // <--- Guarda os pontos da rota ativa

  void _exibirDialogoCadastro(LatLng coordenada) {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cadastrar Local'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Título/Nome'),
            ),
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isNotEmpty) {
                setState(() {
                  _locais.add(
                    LocalSalvo(
                      nome: nomeController.text,
                      descricao: descricaoController.text,
                      coordenada: coordenada,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _abrirComparadorMaisProximo() {
    if (_locais.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre pelo menos 2 locais para comparar!'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ComparadorBottomSheet(
        locais: _locais,
          osrmService: widget.osrmService,
        onSelectRota: (localSelecionado) {
          if (localSelecionado.rotaPontos != null) {
            setState(() {
              _rotaParaExibir = localSelecionado.rotaPontos!; // Atualiza os pontos da linha
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Mapa de Locais'),
        actions: [
          if (_rotaParaExibir.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar Rota',
              onPressed: () => setState(() => _rotaParaExibir.clear()),
            ),
          IconButton(
            icon: const Icon(Icons.near_me),
            tooltip: 'Calcular mais próximo',
            onPressed: _abrirComparadorMaisProximo,
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(-23.55052, -46.633309),
          initialZoom: 13.0,
          onTap: (tapPosition, point) => _exibirDialogoCadastro(point),
        ),
        children: [
          // 1. Mosaico do mapa
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.seupacote.app',
          ),

          // 2. CAMADA DE LINHAS (Desenha o Trajeto da Rota)[cite: 1]
          if (_rotaParaExibir.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _rotaParaExibir,
                  strokeWidth: 5.0,
                  color: Colors.blue,
                ),
              ],
            ),

          // 3. Marcadores dos pinos
          MarkerLayer(
            markers: _locais.map((local) {
              return Marker(
                point: local.coordenada,
                width: 40,
                height: 40,
                child: Tooltip(
                  message: '${local.nome}\n${local.descricao}',
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
