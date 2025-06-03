import 'package:uuid/uuid.dart'; 

class ItemComanda {
  final int? id; 
  final String nome;
  final int quantidade;
  final double preco;
  final String? caminhoFoto;

  ItemComanda({
    this.id,
    required this.nome,
    required this.quantidade,
    required this.preco,
    this.caminhoFoto,
  });

  double get total => quantidade * preco;

  Map<String, dynamic> paraMapa() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'preco': preco,
      'caminho_foto': caminhoFoto,
    };
  }

  factory ItemComanda.doMapa(Map<String, dynamic> mapa) {
    return ItemComanda(
      id: mapa['id'] as int?, 
      nome: mapa['nome'] ?? '',
      quantidade: mapa['quantidade'] ?? 0,
      preco: (mapa['preco'] is int)
          ? (mapa['preco'] as int).toDouble()
          : (mapa['preco'] as double?) ?? 0.0,
      caminhoFoto: mapa['caminho_foto'] as String?,
    );
  }

  ItemComanda copiarCom({
    int? id, 
    String? nome,
    int? quantidade,
    double? preco,
    String? caminhoFoto,
  }) {
    return ItemComanda(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      preco: preco ?? this.preco,
      caminhoFoto: caminhoFoto ?? this.caminhoFoto,
    );
  }

  @override
  String toString() {
    return 'ItemComanda(id: $id, nome: $nome, quantidade: $quantidade, preco: $preco, caminhoFoto: $caminhoFoto)';
  }
}

class Comanda {
  final int? id;
  String nome;
  final DateTime dataCriacao;
  List<ItemComanda> itens;

  Comanda({
    this.id,
    required this.nome,
    DateTime? dataCriacao,
    List<ItemComanda>? itens,
  })  : dataCriacao = dataCriacao ?? DateTime.now(),
        itens = itens ?? [];

  double get total {
    return itens.fold(0.0, (soma, item) => soma + item.total);
  }

  Map<String, dynamic> paraMapa() {
    return {
      'id': id,
      'nome': nome,
      'data_criacao': dataCriacao.toIso8601String(),
    };
  }

  factory Comanda.doMapa(Map<String, dynamic> mapa) {
    return Comanda(
      id: mapa['id'] as int?,
      nome: mapa['nome'] ?? '',
      dataCriacao: DateTime.parse(mapa['data_criacao']),
      itens: [],
    );
  }

  Comanda copiarCom({
    int? id,
    String? nome,
    DateTime? dataCriacao,
    List<ItemComanda>? itens,
  }) {
    return Comanda(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      itens: itens ?? this.itens,
    );
  }

  @override
  String toString() {
    return 'Comanda(id: $id, nome: $nome, dataCriacao: $dataCriacao, itens: $itens)';
  }
}