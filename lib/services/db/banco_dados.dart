import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'modelo_comanda.dart'; // Assumindo que este arquivo contém as classes Comanda e ItemComanda

class BancoDados {
  // Implementa o padrão Singleton para garantir que haja apenas uma instância da classe BancoDados.
  static final BancoDados _instancia = BancoDados._interno();
  factory BancoDados() => _instancia;
  BancoDados._interno();

  // Variável estática para armazenar a instância do banco de dados.
  static Database? _banco;

  /// Retorna a instância do banco de dados. Se ainda não estiver inicializada, a inicializa.
  Future<Database> get banco async {
    if (_banco != null) return _banco!;
    _banco = await _iniciarBanco();
    return _banco!;
  }

  /// Inicializa o banco de dados, definindo o caminho, a versão e os callbacks para criação e atualização.
  Future<Database> _iniciarBanco() async {
    // Obtém o caminho padrão para bancos de dados no dispositivo.
    final caminhoBanco = await getDatabasesPath();
    // Junta o caminho com o nome do arquivo do banco de dados.
    final localBanco = join(caminhoBanco, 'comandas.db');

    // Abre o banco de dados.
    return await openDatabase(
      localBanco,
      version: 2, // Versão do esquema do banco de dados.
      onCreate:
          _criarTabelas, // Chamado quando o banco de dados é criado pela primeira vez.
      onUpgrade:
          _atualizarTabelas, // Chamado quando a versão do banco de dados é alterada.
    );
  }

  /// Cria as tabelas 'comandas' e 'itens_comanda' no banco de dados.
  ///
  /// [db]: A instância do banco de dados.
  /// [versao]: A versão atual do banco de dados.
  Future<void> _criarTabelas(Database db, int versao) async {
    // Cria a tabela 'comandas'.
    await db.execute('''
      CREATE TABLE comandas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        data_criacao TEXT
      )
    ''');

    // Cria a tabela 'itens_comanda' com uma chave estrangeira para 'comandas'.
    // ON DELETE CASCADE garante que ao deletar uma comanda, seus itens também são deletados.
    await db.execute('''
      CREATE TABLE itens_comanda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comanda_id INTEGER,
        nome TEXT,
        quantidade INTEGER,
        preco REAL,
        caminho_foto TEXT,
        FOREIGN KEY(comanda_id) REFERENCES comandas(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Atualiza o esquema do banco de dados quando a versão muda.
  ///
  /// [db]: A instância do banco de dados.
  /// [versaoAntiga]: A versão anterior do banco de dados.
  /// [versaoNova]: A nova versão do banco de dados.
  Future<void> _atualizarTabelas(
    Database db,
    int versaoAntiga,
    int versaoNova,
  ) async {
    // Se a versão antiga for menor que 2, adiciona a coluna 'caminho_foto' à tabela 'itens_comanda'.
    if (versaoAntiga < 2) {
      await db.execute(
        'ALTER TABLE itens_comanda ADD COLUMN caminho_foto TEXT',
      );
    }
    // Adicione outras migrações aqui para versões futuras (ex: if (versaoAntiga < 3) { ... })
  }

  /// Salva uma nova comanda e seus itens no banco de dados.
  /// Utiliza uma transação para garantir que a comanda e todos os seus itens sejam salvos atomicamente.
  ///
  /// [comanda]: O objeto Comanda a ser salvo.
  /// Retorna o ID da comanda salva.
  Future<int> salvarComanda(Comanda comanda) async {
    final db = await banco;
    return await db.transaction((txn) async {
      // Insere a comanda e obtém o ID gerado.
      final id = await txn.insert('comandas', comanda.paraMapa());

      // Salva os itens da comanda usando o método auxiliar.
      await _salvarItensComanda(txn, id, comanda.itens);

      return id;
    });
  }

  /// Atualiza uma comanda existente e seus itens no banco de dados.
  /// Primeiramente, atualiza a comanda, depois remove todos os itens antigos
  /// e insere os novos itens. Tudo dentro de uma transação.
  ///
  /// [comanda]: O objeto Comanda a ser atualizado.
  /// Retorna o ID da comanda atualizada.
  Future<int> atualizarComanda(Comanda comanda) async {
    final db = await banco;
    if (comanda.id == null) {
      throw Exception("Comanda ID não pode ser nulo para atualização.");
    }

    return await db.transaction((txn) async {
      // Atualiza a comanda principal.
      await txn.update(
        'comandas',
        comanda.paraMapa(),
        where: 'id = ?',
        whereArgs: [comanda.id],
      );

      // Remove todos os itens antigos associados a esta comanda.
      await txn.delete(
        'itens_comanda',
        where: 'comanda_id = ?',
        whereArgs: [comanda.id],
      );

      // Salva os novos itens da comanda usando o método auxiliar.
      await _salvarItensComanda(txn, comanda.id!, comanda.itens);

      return comanda.id!;
    });
  }

  /// Remove uma comanda e todos os seus itens associados (devido ao ON DELETE CASCADE).
  ///
  /// [id]: O ID da comanda a ser removida.
  Future<void> removerComanda(int id) async {
    final db = await banco;
    await db.delete('comandas', where: 'id = ?', whereArgs: [id]);
  }

  /// Lista todas as comandas do banco de dados, incluindo seus itens.
  ///
  /// Retorna uma lista de objetos Comanda.
  Future<List<Comanda>> listarComandas() async {
    final db = await banco;
    // Consulta todas as comandas.
    final List<Map<String, dynamic>> mapasComandas = await db.query('comandas');

    final List<Comanda> comandas = [];

    // Para cada comanda, consulta seus itens.
    for (var mapaComanda in mapasComandas) {
      final comanda = Comanda.doMapa(mapaComanda);

      // Consulta os itens_comanda associados a esta comanda.
      final List<Map<String, dynamic>> mapasItens = await db.query(
        'itens_comanda',
        where: 'comanda_id = ?',
        whereArgs: [comanda.id],
      );

      // Converte os mapas de itens em objetos ItemComanda.
      final List<ItemComanda> itens =
          mapasItens.map((i) => ItemComanda.doMapa(i)).toList();

      // Adiciona a comanda com seus itens à lista final.
      comandas.add(comanda.copiarCom(itens: itens));
    }

    return comandas;
  }

  /// Método auxiliar para salvar uma lista de itens de comanda.
  ///
  /// [txn]: A instância do Database ou Transaction.
  /// [comandaId]: O ID da comanda à qual os itens pertencem.
  /// [itens]: A lista de ItemComanda a ser salva.
  Future<void> _salvarItensComanda(
    DatabaseExecutor txn,
    int comandaId,
    List<ItemComanda> itens,
  ) async {
    for (var item in itens) {
      await txn.insert(
        'itens_comanda',
        _itemParaMapa(item, comandaId: comandaId),
      );
    }
  }

  /// Converte um objeto ItemComanda em um Mapa para inserção no banco de dados.
  ///
  /// [item]: O objeto ItemComanda a ser convertido.
  /// [comandaId]: O ID da comanda associada ao item.
  /// Retorna um Mapa com os dados do item.
  Map<String, dynamic> _itemParaMapa(
    ItemComanda item, {
    required int? comandaId,
  }) {
    return {
      'comanda_id': comandaId,
      'nome': item.nome,
      'quantidade': item.quantidade,
      'preco': item.preco,
      'caminho_foto': item.caminhoFoto,
    };
  }
}
