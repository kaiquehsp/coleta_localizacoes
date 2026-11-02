import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  BancoLocalizacoes._();

  static final BancoLocalizacoes instancia = BancoLocalizacoes._();

  static const String tabela = 'localizacoes';
  static const String _arquivo = 'localizacoes.db';
  static const int _versao = 1;

  Future<Database>? _abertura;

  Future<Database> get banco {
    return _abertura ??= _abrir().catchError((Object erro, StackTrace pilha) {
      _abertura = null;
      Error.throwWithStackTrace(erro, pilha);
    });
  }

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    return openDatabase(
      join(pasta, _arquivo),
      version: _versao,
      onCreate: (db, versao) {
        return db.execute('''
          CREATE TABLE $tabela (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
