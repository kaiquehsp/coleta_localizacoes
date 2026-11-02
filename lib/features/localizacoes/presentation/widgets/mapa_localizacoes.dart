import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';




class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    required this.cache,
  });

  final List<Localizacao> localizacoes;
  final MapCachingProvider cache;

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final MapController _controlador = MapController();
  late final NetworkTileProvider _provedorImagens = NetworkTileProvider(
    cachingProvider: widget.cache,
  );

  CameraFit get _enquadramento {
    return CameraFit.coordinates(
      coordinates: [
        for (final item in widget.localizacoes)
          LatLng(item.latitude, item.longitude),
      ],
      padding: const EdgeInsets.all(56),
      maxZoom: 17,
    );
  }

  @override
  void didUpdateWidget(MapaLocalizacoes anterior) {
    super.didUpdateWidget(anterior);
    if (!identical(anterior.localizacoes, widget.localizacoes)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enquadrar();
      });
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _enquadrar() => _controlador.fitCamera(_enquadramento);

  void _mostrarDetalhes(Localizacao localizacao, bool maisRecente) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (maisRecente)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Localização mais recente'),
              ),
            ItemLocalizacao(localizacao: localizacao),
          ],
        ),
      ),
    );
  }

  Marker _criarMarcador(Localizacao localizacao, bool maisRecente) {
    return Marker(
      point: LatLng(localizacao.latitude, localizacao.longitude),
      width: 40,
      height: 40,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _mostrarDetalhes(localizacao, maisRecente),
        child: Icon(
          Icons.location_on,
          size: 40,
          color: maisRecente ? Colors.red : Colors.blue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maisRecente = widget.localizacoes.first;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(initialCameraFit: _enquadramento, maxZoom: 19),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.kaiquematheus.coleta_localizacoes',
              tileProvider: _provedorImagens,
            ),
            MarkerLayer(
              
              markers: [
                for (final item in widget.localizacoes.reversed)
                  _criarMarcador(item, identical(item, maisRecente)),
              ],
            ),
            SimpleAttributionWidget(
              source: const Text('© OpenStreetMap contributors'),
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 48,
          child: FloatingActionButton(
            tooltip: 'Enquadrar todos os pontos',
            onPressed: _enquadrar,
            child: const Icon(Icons.fit_screen),
          ),
        ),
      ],
    );
  }
}
