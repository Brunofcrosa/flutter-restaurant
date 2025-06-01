// lib/modules/home/tela_editar_comanda.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../../modules/widgets/card_item_comanda.dart';
import '../../services/db/banco_dados.dart';
import '../../services/db/modelo_comanda.dart';

class TelaEditarComanda extends StatefulWidget {
  final Comanda comanda;
  final VoidCallback aoSalvar;

  const TelaEditarComanda({
    super.key,
    required this.comanda,
    required this.aoSalvar,
  });

  @override
  _TelaEditarComandaState createState() => _TelaEditarComandaState();
}

class _TelaEditarComandaState extends State<TelaEditarComanda> {
  late Comanda _comandaSendoEditada;
  final TextEditingController _nomeControle = TextEditingController();

  final BancoDados _banco = BancoDados();

  bool _estaCarregando = false;
  bool _temMudancas = false;

  @override
  void initState() {
    super.initState();
    _comandaSendoEditada = widget.comanda.copiarCom();
    _nomeControle.text = _comandaSendoEditada.nome;

    _nomeControle.addListener(_checarMudancas);
  }

  @override
  void dispose() {
    _nomeControle.removeListener(_checarMudancas);
    _nomeControle.dispose();
    super.dispose();
  }

  void _checarMudancas() {
    final bool nomeMudou = _nomeControle.text.trim() != widget.comanda.nome;
    final bool itensMudar = !_compararItens(_comandaSendoEditada.itens, widget.comanda.itens);

    if (!_temMudancas && (nomeMudou || itensMudar)) {
      setState(() {
        _temMudancas = true;
      });
    } else if (_temMudancas && !nomeMudou && !itensMudar) {
      setState(() {
        _temMudancas = false;
      });
    }
  }

  void _mostrarMensagemErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _validarItem(String nome, int? quantidade, double? preco) {
    return nome.isNotEmpty &&
        quantidade != null &&
        quantidade > 0 &&
        preco != null &&
        preco >= 0;
  }

  Future<void> _adicionarItem(String nomeItem, int quantidade, double preco, String? caminhoFoto) async {
    final novoItem = ItemComanda(
      nome: nomeItem,
      quantidade: quantidade,
      preco: preco,
      caminhoFoto: caminhoFoto,
    );

    setState(() {
      _comandaSendoEditada = _comandaSendoEditada.copiarCom(
        itens: [..._comandaSendoEditada.itens, novoItem],
      );
      _checarMudancas();
    });
  }

  Future<void> _editarItem(int index, String nomeItem, int quantidade, double preco, String? caminhoFoto) async {
    final itemAtualizado = _comandaSendoEditada.itens[index].copiarCom(
      nome: nomeItem,
      quantidade: quantidade,
      preco: preco,
      caminhoFoto: caminhoFoto,
    );

    setState(() {
      final List<ItemComanda> novosItens = List.from(_comandaSendoEditada.itens);
      novosItens[index] = itemAtualizado;
      _comandaSendoEditada = _comandaSendoEditada.copiarCom(
        itens: novosItens,
      );
      _checarMudancas();
    });
  }

  Future<void> _removerItem(int index) async {
    setState(() {
      final List<ItemComanda> novosItens = List.from(_comandaSendoEditada.itens);
      novosItens.removeAt(index);
      _comandaSendoEditada = _comandaSendoEditada.copiarCom(
        itens: novosItens,
      );
      _checarMudancas();
    });
  }

  bool _compararItens(List<ItemComanda> lista1, List<ItemComanda> lista2) {
    if (lista1.length != lista2.length) return false;
    for (int i = 0; i < lista1.length; i++) {
      if (lista1[i].id != lista2[i].id ||
          lista1[i].nome != lista2[i].nome ||
          lista1[i].quantidade != lista2[i].quantidade ||
          lista1[i].preco != lista2[i].preco ||
          lista1[i].caminhoFoto != lista2[i].caminhoFoto) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _salvarComanda() async {
    if (_estaCarregando) return false;

    final String nome = _nomeControle.text.trim();
    if (nome.isEmpty) {
      _mostrarMensagemErro('O nome da comanda não pode ser vazio.');
      return false;
    }

    if (!_temMudancas) {
      return true;
    }

    setState(() => _estaCarregando = true);

    try {
      await _banco.atualizarComanda(_comandaSendoEditada.copiarCom(
        nome: nome,
        itens: _comandaSendoEditada.itens.map((e) => e.copiarCom()).toList(),
      ));
      widget.aoSalvar();

      _comandaSendoEditada = _comandaSendoEditada.copiarCom(
        nome: nome,
        itens: _comandaSendoEditada.itens.map((e) => e.copiarCom()).toList(),
      );
      _temMudancas = false;
      return true;
    } catch (e) {
      _mostrarMensagemErro('Erro ao salvar comanda: $e');
      return false;
    } finally {
      setState(() => _estaCarregando = false);
    }
  }

  void _mostrarModalAdicionarItem() {
    _mostrarModalItem(estaEditando: false);
  }

  void _mostrarModalEditarItem(ItemComanda item, int index) {
    _mostrarModalItem(estaEditando: true, item: item, index: index);
  }

  void _mostrarModalItem({required bool estaEditando, ItemComanda? item, int? index}) {
    final TextEditingController itemControle = TextEditingController(text: estaEditando ? item!.nome : '');
    final TextEditingController quantidadeControle = TextEditingController(text: estaEditando ? item!.quantidade.toString() : '');
    final TextEditingController precoControle = TextEditingController(
        text: estaEditando ? item!.preco.toStringAsFixed(2).replaceAll('.', ',') : '');
    File? imagemSelecionada;

    if (estaEditando && item!.caminhoFoto != null) {
      imagemSelecionada = File(item.caminhoFoto!);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> selecionarFoto() async {
              final ImagePicker seletorImagem = ImagePicker();
              final XFile? imagem = await seletorImagem.pickImage(source: ImageSource.gallery);
              if (imagem != null) {
                setModalState(() {
                  imagemSelecionada = File(imagem.path);
                });
              }
            }

            return AlertDialog(
              title: Text(estaEditando ? 'Editar Item' : 'Adicionar Novo Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: itemControle,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Item',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: quantidadeControle,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: precoControle,
                      decoration: const InputDecoration(
                        labelText: 'Preço (R\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          imagemSelecionada != null
                              ? Image.file(
                                  imagemSelecionada!,
                                  key: ValueKey(imagemSelecionada!.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  key: const ValueKey('no_image_placeholder'),
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                                ),
                          TextButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Selecionar Foto'),
                            onPressed: selecionarFoto,
                          ),
                          if (imagemSelecionada != null)
                            TextButton.icon(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              label: const Text('Remover Foto'),
                              onPressed: () {
                                setModalState(() {
                                  imagemSelecionada = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(estaEditando ? 'Salvar Alterações' : 'Adicionar'),
                  onPressed: () {
                    final String nomeItem = itemControle.text.trim();
                    final int? quantidade = int.tryParse(quantidadeControle.text.trim());
                    final double? preco = double.tryParse(precoControle.text.replaceAll(',', '.').trim());

                    if (!_validarItem(nomeItem, quantidade, preco)) {
                      _mostrarMensagemErro('Preencha todos os campos corretamente (quantidade > 0, preço >= 0).');
                      return;
                    }

                    if (estaEditando) {
                      _editarItem(index!, nomeItem, quantidade!, preco!, imagemSelecionada?.path);
                    } else {
                      _adicionarItem(nomeItem, quantidade!, preco!, imagemSelecionada?.path);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      itemControle.dispose();
      quantidadeControle.dispose();
      precoControle.dispose();
    });
  }

  double get _total {
    return _comandaSendoEditada.itens.fold(0.0, (soma, item) => soma + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          if (_temMudancas) {
            await _salvarComanda();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Comanda'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _estaCarregando ? null : () async {
                final salvo = await _salvarComanda();
                if (salvo) {
                  Navigator.pop(context);
                }
              },
              tooltip: 'Salvar Alterações',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _nomeControle,
                decoration: const InputDecoration(
                  labelText: 'Nome da Comanda',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                onChanged: (valor) {
                  setState(() {
                    _comandaSendoEditada = _comandaSendoEditada.copiarCom(nome: valor);
                    _checarMudancas();
                  });
                },
              ),
            ),
            Expanded(
              child: _comandaSendoEditada.itens.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum item adicionado ainda.\nClique no botão "+" para adicionar itens.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _comandaSendoEditada.itens.length,
                      itemBuilder: (context, index) {
                        final itemAtual = _comandaSendoEditada.itens[index];
                        return CardItemComanda(
                          key: ValueKey(itemAtual.id),
                          item: itemAtual,
                          aoRemover: () => _removerItem(index),
                          aoTocar: () => _mostrarModalEditarItem(itemAtual, index),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total da Comanda:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'R\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            if (_estaCarregando)
              const LinearProgressIndicator(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _mostrarModalAdicionarItem,
          tooltip: 'Adicionar Item',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}