// lib/services/db/banco_dados.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'modelo_comanda.dart';

class BancoDados {
  static final BancoDados _instancia = BancoDados._interno();
  factory BancoDados() => _instancia;
  BancoDados._interno();

  static Database? _banco;

  Future<Database> get banco async {
    if (_banco != null) return _banco!;
    _banco = await _iniciarBanco();
    return _banco!;
  }

  Future<Database> _iniciarBanco() async {
    final caminhoBanco = await getDatabasesPath();
    final localBanco = join(caminhoBanco, 'comandas.db');

    return await openDatabase(
      localBanco,
      version: 2,
      onCreate: _criarTabelas,
      onUpgrade: _atualizarTabelas,
    );
  }

  Future<void> _criarTabelas(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE comandas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        data_criacao TEXT
      )
    ''');

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

  Future<void> _atualizarTabelas(Database db, int versaoAntiga, int versaoNova) async {
    if (versaoAntiga < 2) {
      await db.execute('ALTER TABLE itens_comanda ADD COLUMN caminho_foto TEXT');
    }
  }

  Future<int> salvarComanda(Comanda comanda) async {
    final db = await banco;

    final id = await db.insert('comandas', comanda.paraMapa());

    for (var item in comanda.itens) {
      await db.insert('itens_comanda', _itemParaMapa(item, comandaId: id));
    }

    return id;
  }

  Future<int> atualizarComanda(Comanda comanda) async {
    final db = await banco;

    await db.update(
      'comandas',
      comanda.paraMapa(),
      where: 'id = ?',
      whereArgs: [comanda.id],
    );

    await db.delete(
      'itens_comanda',
      where: 'comanda_id = ?',
      whereArgs: [comanda.id],
    );

    for (var item in comanda.itens) {
      await db.insert('itens_comanda', _itemParaMapa(item, comandaId: comanda.id));
    }

    return comanda.id!;
  }

  Future<void> removerComanda(int id) async {
    final db = await banco;
    await db.delete(
      'comandas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Comanda>> listarComandas() async {
    final db = await banco;
    final List<Map<String, dynamic>> mapasComandas = await db.query('comandas');

    final List<Comanda> comandas = [];

    for (var mapaComanda in mapasComandas) {
      final comanda = Comanda.doMapa(mapaComanda);

      final List<Map<String, dynamic>> mapasItens = await db.query(
        'itens_comanda',
        where: 'comanda_id = ?',
        whereArgs: [comanda.id],
      );

      final List<ItemComanda> itens = mapasItens.map((i) => ItemComanda.doMapa(i)).toList();

      comandas.add(comanda.copiarCom(itens: itens));
    }

    return comandas;
  }

  Map<String, dynamic> _itemParaMapa(ItemComanda item, {required int? comandaId}) {
    return {
      'comanda_id': comandaId,
      'nome': item.nome,
      'quantidade': item.quantidade,
      'preco': item.preco,
      'caminho_foto': item.caminhoFoto,
    };
  }
}