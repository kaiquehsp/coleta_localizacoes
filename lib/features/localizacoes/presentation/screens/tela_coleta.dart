import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';





class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final ServicoLocalizacao _servico = ServicoLocalizacao();
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();

  StreamSubscription<Localizacao>? _assinatura;
  Localizacao? _ultimaSalva;

  
  bool _ocupado = false;

  
  bool _gravando = false;

  bool get _coletando => _assinatura != null;

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  Future<void> _iniciarColeta() async {
    if (_ocupado || _coletando) return;
    setState(() => _ocupado = true);

    try {
      final resultado = await _servico.verificar();
      if (!mounted) return;

      if (resultado != ResultadoVerificacao.permitido) {
        await _orientarUsuario(resultado);
        return;
      }

      final notificacaoPermitida = await _servico
          .solicitarPermissaoNotificacao();
      if (!mounted) return;

      setState(() {
        _assinatura = _servico.posicoes().listen(
          _salvarPosicao,
          onError: _tratarErroDoStream,
        );
      });

      if (!notificacaoPermitida) {
        _mostrarMensagem(
          'Coleta iniciada. Permita as notificações nas configurações para '
          'ver o aviso de coleta ativa.',
        );
      }
    } catch (_) {
      _mostrarMensagem('Não foi possível iniciar a coleta.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _pararColeta() async {
    final assinatura = _assinatura;
    if (_ocupado || assinatura == null) return;

    setState(() {
      _ocupado = true;
      _assinatura = null;
    });

    try {
      await assinatura.cancel();
    } catch (_) {
      _mostrarMensagem('Ocorreu um erro ao parar a coleta.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _salvarPosicao(Localizacao localizacao) async {
    
    if (_gravando) return;
    _gravando = true;

    try {
      await _repositorio.inserir(localizacao);
      if (mounted) setState(() => _ultimaSalva = localizacao);
    } catch (_) {
      _mostrarMensagem('Não foi possível salvar a localização.');
    } finally {
      _gravando = false;
    }
  }

  void _tratarErroDoStream(Object erro) {
    _assinatura?.cancel();
    if (!mounted) return;
    setState(() => _assinatura = null);
    _mostrarMensagem(
      'A coleta foi interrompida porque a localização ficou indisponível. '
      'Verifique o GPS e as permissões e inicie novamente.',
    );
  }

  Future<void> _orientarUsuario(ResultadoVerificacao resultado) async {
    switch (resultado) {
      case ResultadoVerificacao.permitido:
        return;
      case ResultadoVerificacao.permissaoNegada:
        _mostrarMensagem(
          'A coleta precisa da permissão de localização. Toque em Iniciar '
          'coleta e permita o acesso.',
        );
      case ResultadoVerificacao.servicoDesabilitado:
        await _mostrarDialogoConfiguracoes(
          titulo: 'Localização desativada',
          mensagem: 'Ative a localização do aparelho para iniciar a coleta.',
          abrir: _servico.abrirConfiguracoesLocalizacao,
        );
      case ResultadoVerificacao.permissaoNegadaPermanentemente:
        await _mostrarDialogoConfiguracoes(
          titulo: 'Permissão necessária',
          mensagem:
              'A permissão de localização foi negada. Habilite-a nas '
              'configurações do aplicativo para iniciar a coleta.',
          abrir: _servico.abrirConfiguracoesPermissao,
        );
    }
  }

  Future<void> _mostrarDialogoConfiguracoes({
    required String titulo,
    required String mensagem,
    required Future<bool> Function() abrir,
  }) async {
    final abrirConfiguracoes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
    );

    if (abrirConfiguracoes == true) await abrir();
  }

  Future<void> _abrirConfiguracoesPermissao() async {
    try {
      final abriu = await _servico.abrirConfiguracoesPermissao();
      if (!abriu) _mostrarMensagem('Não foi possível abrir as configurações.');
    } catch (_) {
      _mostrarMensagem('Não foi possível abrir as configurações.');
    }
  }

  void _abrirTela(Widget tela) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => tela),
    );
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final ultimaSalva = _ultimaSalva;

    return PopScope(
      
      canPop: !_coletando,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) {
          _mostrarMensagem(
            'Pare a coleta antes de sair ou use o botão início para minimizar.',
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Coleta de localização')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  _coletando ? Icons.gps_fixed : Icons.gps_off,
                  color: _coletando ? Colors.green : null,
                ),
                title: Text(_coletando ? 'Coleta ativa' : 'Coleta parada'),
                subtitle: const Text('Intervalo solicitado: 20 segundos'),
              ),
            ),
            if (ultimaSalva != null)
              Card(child: ItemLocalizacao(localizacao: ultimaSalva)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _ocupado || _coletando ? null : _iniciarColeta,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar coleta'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _ocupado || !_coletando ? null : _pararColeta,
              icon: const Icon(Icons.stop),
              label: const Text('Parar coleta'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  _abrirTela(TelaLocalizacoes(coletaAtiva: () => _coletando)),
              icon: const Icon(Icons.history),
              label: const Text('Consultar histórico'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _abrirTela(const TelaMapa()),
              icon: const Icon(Icons.map),
              label: const Text('Ver mapa'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _abrirConfiguracoesPermissao,
              icon: const Icon(Icons.settings),
              label: const Text('Configurações de permissão'),
            ),
          ],
        ),
      ),
    );
  }
}
