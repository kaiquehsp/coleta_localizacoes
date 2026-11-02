import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/mapa_localizacoes.dart';


class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();
  final CacheMapa _cacheMapa = CacheMapa();

  List<Localizacao> _localizacoes = const [];
  MapCachingProvider? _cache;
  bool _carregando = true;
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _atualizar() {
    setState(() {
      _carregando = true;
      _falhou = false;
    });
    return _carregar();
  }

  Future<void> _carregar() async {
    try {
      final cache = _cache ?? await _cacheMapa.preparar();
      final localizacoes = await _repositorio.consultarRecentes();
      if (!mounted) return;
      setState(() {
        _cache = cache;
        _localizacoes = localizacoes;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _falhou = true;
        _carregando = false;
      });
    }
  }

  Widget _construirConteudo() {
    final cache = _cache;

    if (_falhou) {
      return const Center(child: Text('Não foi possível carregar o mapa.'));
    }
    if (_carregando && (cache == null || _localizacoes.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cache == null || _localizacoes.isEmpty) {
      return const Center(child: Text('Nenhuma localização salva.'));
    }
    return MapaLocalizacoes(localizacoes: _localizacoes, cache: cache);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Atualizar registros',
            onPressed: _carregando ? null : _atualizar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _construirConteudo(),
    );
  }
}
