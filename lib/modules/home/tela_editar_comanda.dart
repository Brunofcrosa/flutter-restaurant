import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restaurante/services/db/banco_dados.dart';
import 'package:restaurante/services/db/modelo_comanda.dart';
import 'package:uuid/uuid.dart';

class TelaEditarComanda extends StatefulWidget {
  final Comanda comanda;
  final VoidCallback aoSalvar;

  const TelaEditarComanda({
    super.key, 
    required this.comanda,
    required this.aoSalvar,
  });

  @override
  State<TelaEditarComanda> createState() => _TelaEditarComandaState();
}

class _TelaEditarComandaState extends State<TelaEditarComanda> {
  late Comanda _comandaSendoEditada;
  final TextEditingController _nomeControle = TextEditingController();
  final BancoDados _banco = BancoDados();
  bool _estaCarregando = false;
  bool _temMudancas = false;
  double _total = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _comandaSendoEditada = widget.comanda.copiarCom();
    _nomeControle.text = _comandaSendoEditada.nome;
    _calcularTotal();
    _nomeControle.addListener(_checarMudancas);
  }

  @override
  void dispose() {
    _nomeControle.removeListener(_checarMudancas);
    _nomeControle.dispose();
    super.dispose();
  }

  void _checarMudancas() {
    if (!mounted) return;
    
    final bool nomeMudou = _nomeControle.text.trim() != widget.comanda.nome;
    final bool itensMudaram = !_compararItens(
      _comandaSendoEditada.itens, 
      widget.comanda.itens
    );

    setState(() {
      _temMudancas = nomeMudou || itensMudaram;
    });
  }

  void _mostrarMensagemErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validarItem(String nome, int? quantidade, double? preco) {
    return nome.isNotEmpty &&
        quantidade != null &&
        quantidade > 0 &&
        preco != null &&
        preco >= 0;
  }

  void _removerItem(int index) {
    if (!mounted) return;
    
    setState(() {
      final novosItens = List<ItemComanda>.from(_comandaSendoEditada.itens);
      novosItens.removeAt(index);
      _comandaSendoEditada = _comandaSendoEditada.copiarCom(
        itens: novosItens,
      );
      _calcularTotal();
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
    if (_isSaving || !mounted) return false;
    _isSaving = true;

    final String nome = _nomeControle.text.trim();
    if (nome.isEmpty) {
      _mostrarMensagemErro('O nome da comanda não pode ser vazio.');
      _isSaving = false;
      return false;
    }

    if (!_temMudancas) {
      _isSaving = false;
      return true;
    }

    setState(() => _estaCarregando = true);

    try {
      await _banco.atualizarComanda(_comandaSendoEditada.copiarCom(
        nome: nome,
        itens: _comandaSendoEditada.itens.map((e) => e.copiarCom()).toList(),
      ));

      if (!mounted) return false;

      setState(() {
        _comandaSendoEditada = _comandaSendoEditada.copiarCom(
          nome: nome,
          itens: _comandaSendoEditada.itens.map((e) => e.copiarCom()).toList(),
        );
        _temMudancas = false;
      });
      
      return true;
    } catch (e) {
      if (mounted) {
        _mostrarMensagemErro('Erro ao salvar comanda: $e');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _estaCarregando = false);
      }
      _isSaving = false;
    }
  }

  void _mostrarModalAdicionarItem() {
    _mostrarModalItem(estaEditando: false);
  }

  void _mostrarModalEditarItem(ItemComanda item, int index) {
    _mostrarModalItem(estaEditando: true, item: item, index: index);
  }

  Future<void> _mostrarModalItem({
    required bool estaEditando, 
    ItemComanda? item, 
    int? index
  }) async {
    final itemControle = TextEditingController(
      text: estaEditando ? item!.nome : ''
    );
    final quantidadeControle = TextEditingController(
      text: estaEditando ? item!.quantidade.toString() : ''
    );
    final precoControle = TextEditingController(
      text: estaEditando ? item!.preco.toStringAsFixed(2).replaceAll('.', ',') : ''
    );
    File? imagemSelecionada;

    if (estaEditando && item!.caminhoFoto != null && item.caminhoFoto!.isNotEmpty) {
      imagemSelecionada = File(item.caminhoFoto!);
    }

    final result = await showDialog<ItemComanda>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> selecionarFoto() async {
              final imagem = await ImagePicker().pickImage(source: ImageSource.gallery);
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
                          if (imagemSelecionada != null)
                            Image.file(
                              imagemSelecionada!,
                              key: ValueKey(imagemSelecionada!.path), 
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(estaEditando ? 'Salvar Alterações' : 'Adicionar'),
                  onPressed: () {
                    final nomeItem = itemControle.text.trim();
                    final quantidade = int.tryParse(quantidadeControle.text.trim());
                    final preco = double.tryParse(precoControle.text.replaceAll(',', '.').trim());

                    if (!_validarItem(nomeItem, quantidade, preco)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Preencha todos os campos corretamente'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop(
                      ItemComanda(
                        id: estaEditando ? item!.id : null,
                        nome: nomeItem,
                        quantidade: quantidade!,
                        preco: preco!,
                        caminhoFoto: imagemSelecionada?.path,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        if (estaEditando && index != null) {
          _comandaSendoEditada.itens[index] = result;
        } else {
          _comandaSendoEditada.itens.add(result);
        }
        _calcularTotal();
        _checarMudancas();
      });
    }
    
    itemControle.dispose();
    quantidadeControle.dispose();
    precoControle.dispose();
  }

  void _calcularTotal() {
    if (!mounted) return;
    
    setState(() {
      _total = _comandaSendoEditada.itens.fold(
        0.0, 
        (soma, item) => soma + (item.preco * item.quantidade)
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        if (_temMudancas) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Salvar alterações?'),
              content: const Text('Existem alterações não salvas. Deseja salvar antes de sair?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sair sem salvar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final saved = await _salvarComanda();
                    Navigator.of(context).pop(saved);
                  },
                  child: const Text('Salvar e sair'),
                ),
              ],
            ),
          );

          if (shouldPop ?? false) {
            if (mounted) {
              widget.aoSalvar();
              Navigator.of(context).pop();
            }
          }
        } else {
          if (mounted) {
            widget.aoSalvar();
            Navigator.of(context).pop();
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
                setState(() => _estaCarregando = true);
                final salvo = await _salvarComanda();
                if (mounted) {
                  setState(() => _estaCarregando = false);
                  if (salvo) {
                    Navigator.pop(context);
                    widget.aoSalvar();
                  }
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
                        return Card(
                          child: ListTile(
                            title: Text(itemAtual.nome),
                            subtitle: Text(
                              '${itemAtual.quantidade}x R\$${itemAtual.preco.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _mostrarModalEditarItem(itemAtual, index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removerItem(index),
                                ),
                              ],
                            ),
                            onTap: () => _mostrarModalEditarItem(itemAtual, index),
                          ),
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