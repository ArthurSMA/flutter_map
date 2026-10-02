// Modal/Componente de comparação de distâncias

import 'package:flutter/material.dart';
import '../models/local.dart';
import '../services/osrm_service.dart';

class ComparadorBottomSheet extends StatefulWidget {
  final List<LocalSalvo> locais;
  final OSRMService osrmService;
  final Function(LocalSalvo localSelecionado) onSelectRota; // <--- NOVO: Callback para desenhar a rota

  ComparadorBottomSheet({
    super.key,
    required this.locais,
    required this.onSelectRota,
    OSRMService? osrmService,
  }) : osrmService = osrmService ?? OSRMService();

  @override
  State<ComparadorBottomSheet> createState() => _ComparadorBottomSheetState();
}

class _ComparadorBottomSheetState extends State<ComparadorBottomSheet> {
  LocalSalvo? _pontoOrigem;
  bool _carregando = false;
  List<LocalSalvo> _locaisOrdenados = [];

  void _calcularEOrdenar() async {
    if (_pontoOrigem == null) return;

    setState(() => _carregando = true);

    final resultados = <LocalSalvo>[];

    for (var destino in widget.locais) {
      if (destino == _pontoOrigem) continue;

      final resultado = await widget.osrmService.obterRotaViaria(
        _pontoOrigem!.coordenada,
        destino.coordenada,
      );

      if (resultado != null) {
        destino.distanciaMetros = resultado.distanciaMetros;
        destino.rotaPontos = resultado.pontosRota; // Salva o caminho
        resultados.add(destino);
      }
    }

    resultados.sort((a, b) {
      if (a.distanciaMetros == null) return 1;
      if (b.distanciaMetros == null) return -1;
      return a.distanciaMetros!.compareTo(b.distanciaMetros!);
    });

    setState(() {
      _locaisOrdenados = resultados;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calcular Ponto Mais Próximo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<LocalSalvo>(
            decoration: const InputDecoration(
              labelText: 'Selecione a sua Origem (Ponto A)',
              border: OutlineInputBorder(),
            ),
            value: _pontoOrigem,
            items: widget.locais.map((local) {
              return DropdownMenuItem(
                value: local,
                child: Text(local.nome),
              );
            }).toList(),
            onChanged: (novo) {
              setState(() {
                _pontoOrigem = novo;
                _locaisOrdenados.clear();
              });
              _calcularEOrdenar();
            },
          ),
          const SizedBox(height: 16),
          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_locaisOrdenados.isNotEmpty) ...[
            const Text(
              'Clique em um destino para exibir o trajeto no mapa:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _locaisOrdenados.length,
              itemBuilder: (context, index) {
                final item = _locaisOrdenados[index];
                final km = item.distanciaMetros != null
                    ? (item.distanciaMetros! / 1000).toStringAsFixed(2)
                    : 'N/A';

                return ListTile(
                  onTap: () {
                    widget.onSelectRota(item); // Envia o local com a rota gravada
                    Navigator.pop(context); // Fecha o BottomSheet
                  },
                  leading: CircleAvatar(
                    backgroundColor: index == 0 ? Colors.green : Colors.grey[300],
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index == 0 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  title: Text(item.nome),
                  subtitle: Text(item.descricao),
                  trailing: Text(
                    '$km km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
