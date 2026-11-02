import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';


class RepositorioLocalizacoes {
  static const int limitePadrao = 100;

  final BancoLocalizacoes _banco = BancoLocalizacoes.instancia;

  Future<void> inserir(Localizacao localizacao) async {
    final db = await _banco.banco;
    await db.insert(BancoLocalizacoes.tabela, localizacao.paraMapa());
  }

  
  Future<List<Localizacao>> consultarRecentes({
    int limite = limitePadrao,
  }) async {
    final db = await _banco.banco;
    final linhas = await db.query(
      BancoLocalizacoes.tabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.deMapa).toList();
  }

  
  Future<void> excluirTodos() async {
    final db = await _banco.banco;
    await db.delete(BancoLocalizacoes.tabela);
  }
}
