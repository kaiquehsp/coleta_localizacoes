import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/item_localizacao.dart';


class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({super.key, required this.coletaAtiva});

  
  final bool Function() coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = const [];
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
      final localizacoes = await _repositorio.consultarRecentes();
      if (!mounted) return;
      setState(() {
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

  Future<void> _limparHistorico() async {
    final aviso = widget.coletaAtiva()
        ? '\n\nA coleta está ativa: novos registros continuarão sendo salvos.'
        : '';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: Text(
          'Todos os registros serão excluídos, inclusive os anteriores aos 100 '
          'exibidos. Esta operação é permanente.$aviso',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _repositorio.excluirTodos();
    } catch (_) {
      _mostrarMensagem('Não foi possível limpar o histórico.');
      return;
    }

    if (!mounted) return;
    await _atualizar();
    _mostrarMensagem('Histórico limpo com sucesso.');
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Widget _construirConteudo() {
    if (_carregando && _localizacoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_falhou) {
      return _Aviso(
        mensagem: 'Não foi possível carregar o histórico.',
        acao: _atualizar,
      );
    }
    if (_localizacoes.isEmpty) {
      return _Aviso(mensagem: 'Nenhuma localização salva.', acao: _atualizar);
    }
    return RefreshIndicator(
      onRefresh: _atualizar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _localizacoes.length,
        itemBuilder: (context, indice) {
          return Card(
            child: ItemLocalizacao(localizacao: _localizacoes[indice]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _atualizar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: _carregando || _localizacoes.isEmpty
                ? null
                : _limparHistorico,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _construirConteudo(),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensagem, required this.acao});

  final String mensagem;
  final VoidCallback acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensagem),
          const SizedBox(height: 8),
          TextButton(onPressed: acao, child: const Text('Atualizar')),
        ],
      ),
    );
  }
}
