import 'package:flutter/material.dart';
import '../../services/db/banco_dados.dart';
import '../../services/db/modelo_comanda.dart';
import '../../app/ui/utils/utilitarios_app.dart';
import 'tela_adicionar_item.dart';

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
  late Comanda _comandaEmEdicao;
  final BancoDados _banco = BancoDados();
  bool _estaCarregando = false;

  @override
  void initState() {
    super.initState();
    _comandaEmEdicao = widget.comanda.copiarCom();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _salvarComanda() async {
    if (_estaCarregando || !mounted) return;

    setState(() => _estaCarregando = true);

    try {
      await _banco.atualizarComanda(_comandaEmEdicao);

      if (!mounted) return;

      widget.aoSalvar();
      Navigator.of(context).pop();
      mostrarMensagem(context, 'Comanda atualizada com sucesso!');
    } catch (e) {
      mostrarMensagem(context, 'Erro ao atualizar comanda: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _estaCarregando = false);
      }
    }
  }

  Future<void> _abrirTelaAdicionarItem() async {
    final ItemComanda? novoItem = await Navigator.push<ItemComanda>(
      context,
      MaterialPageRoute(builder: (context) => const TelaAdicionarItem()),
    );

    if (novoItem != null) {
      setState(() {
        _comandaEmEdicao.itens.add(novoItem);
      });
      mostrarMensagem(
        context,
        'Item adicionado temporariamente. Salve a comanda para persistir.',
      );
    }
  }

  Future<void> _mostrarModalEditarNomeComanda() async {
    final TextEditingController nomeComandaControle = TextEditingController(
      text: _comandaEmEdicao.nome,
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Editar Nome da Comanda'),
            content: TextField(
              controller: nomeComandaControle,
              decoration: const InputDecoration(
                labelText: 'Nome da Comanda',
                border: OutlineInputBorder(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Salvar'),
                onPressed: () {
                  final String novoNome = nomeComandaControle.text.trim();
                  if (novoNome.isEmpty) {
                    mostrarMensagem(
                      dialogContext,
                      'O nome da comanda não pode ser vazio.',
                      isError: true,
                    );
                    return;
                  }
                  setState(() {
                    _comandaEmEdicao = _comandaEmEdicao.copiarCom(
                      nome: novoNome,
                    );
                  });
                  mostrarMensagem(
                    context,
                    'Nome da comanda atualizado temporariamente. Salve a comanda para persistir.',
                  );
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    } finally {
      nomeComandaControle.dispose();
    }
  }

  void _removerItem(int index) {
    setState(() {
      _comandaEmEdicao.itens.removeAt(index);
    });
    mostrarMensagem(
      context,
      'Item removido temporariamente. Salve a comanda para persistir.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comanda: ${_comandaEmEdicao.nome}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _mostrarModalEditarNomeComanda,
            tooltip: 'Editar Nome da Comanda',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _estaCarregando ? null : _salvarComanda,
            tooltip: 'Salvar Comanda',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total da Comanda: R\$${_comandaEmEdicao.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child:
                _comandaEmEdicao.itens.isEmpty
                    ? const Center(
                      child: Text(
                        'Nenhum item adicionado ainda.\nClique em "Adicionar Item" para começar!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _comandaEmEdicao.itens.length,
                      itemBuilder: (context, index) {
                        final item = _comandaEmEdicao.itens[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          elevation: 1,
                          child: ListTile(
                            title: Text('${item.nome} (x${item.quantidade})'),
                            subtitle: Text(
                              'R\$${item.preco.toStringAsFixed(2)} cada - Total: R\$${item.total.toStringAsFixed(2)}',
                            ),
                            leading:
                                item.caminhoFoto != null &&
                                        item.caminhoFoto!.isNotEmpty
                                    ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        item.caminhoFoto!,
                                      ),
                                      onBackgroundImageError: (
                                        exception,
                                        stackTrace,
                                      ) {
                                        mostrarMensagem(
                                          context,
                                          'Erro ao carregar imagem para ${item.nome}',
                                          isError: true,
                                        );
                                      },
                                    )
                                    : const CircleAvatar(
                                      child: Icon(Icons.fastfood),
                                    ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _removerItem(index),
                              tooltip: 'Remover Item',
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _abrirTelaAdicionarItem,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Adicionar Item'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          if (_estaCarregando) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
