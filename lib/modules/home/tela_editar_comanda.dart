import 'package:flutter/material.dart';
import '../../services/db/banco_dados.dart';
import '../../services/db/modelo_comanda.dart';
import '../../app/ui/utils/utilitarios_app.dart'; // Importa a função utilitária para mensagens

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
  final TextEditingController _nomeComandaControle = TextEditingController();
  final BancoDados _banco = BancoDados();
  bool _estaCarregando = false;

  // Controladores para adicionar novo item
  final TextEditingController _nomeItemControle = TextEditingController();
  final TextEditingController _quantidadeItemControle = TextEditingController();
  final TextEditingController _precoItemControle = TextEditingController();
  final TextEditingController _caminhoFotoItemControle =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _comandaEmEdicao = widget.comanda.copiarCom(); // Cria uma cópia para edição
    _nomeComandaControle.text = _comandaEmEdicao.nome;
  }

  @override
  void dispose() {
    _nomeComandaControle.dispose();
    _nomeItemControle.dispose();
    _quantidadeItemControle.dispose();
    _precoItemControle.dispose();
    _caminhoFotoItemControle.dispose();
    super.dispose();
  }

  /// Salva as alterações da comanda e seus itens no banco de dados.
  Future<void> _salvarComanda() async {
    if (_estaCarregando || !mounted) return;

    final String nome = _nomeComandaControle.text.trim();

    if (nome.isEmpty) {
      mostrarMensagem(
        context,
        'O nome da comanda não pode ser vazio.',
        isError: true,
      );
      return;
    }

    setState(() => _estaCarregando = true);

    try {
      // Atualiza o nome da comanda em edição
      _comandaEmEdicao = _comandaEmEdicao.copiarCom(nome: nome);

      await _banco.atualizarComanda(_comandaEmEdicao);

      if (!mounted) return;

      widget.aoSalvar(); // Notifica a tela anterior para recarregar
      Navigator.of(context).pop(); // Volta para a tela anterior
      mostrarMensagem(context, 'Comanda atualizada com sucesso!');
    } catch (e) {
      mostrarMensagem(context, 'Erro ao atualizar comanda: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _estaCarregando = false);
      }
    }
  }

  /// Adiciona um novo item à comanda.
  void _adicionarItem() {
    final String nome = _nomeItemControle.text.trim();
    final int? quantidade = int.tryParse(_quantidadeItemControle.text.trim());
    final double? preco = double.tryParse(_precoItemControle.text.trim());
    final String? caminhoFoto =
        _caminhoFotoItemControle.text.trim().isEmpty
            ? null
            : _caminhoFotoItemControle.text.trim();

    if (nome.isEmpty ||
        quantidade == null ||
        quantidade <= 0 ||
        preco == null ||
        preco <= 0) {
      mostrarMensagem(
        context,
        'Por favor, preencha nome, quantidade e preço válidos para o item.',
        isError: true,
      );
      return;
    }

    setState(() {
      _comandaEmEdicao.itens.add(
        ItemComanda(
          nome: nome,
          quantidade: quantidade,
          preco: preco,
          caminhoFoto: caminhoFoto,
        ),
      );
      // Limpa os campos do formulário de item
      _nomeItemControle.clear();
      _quantidadeItemControle.clear();
      _precoItemControle.clear();
      _caminhoFotoItemControle.clear();
    });
    mostrarMensagem(
      context,
      'Item adicionado temporariamente. Salve a comanda para persistir.',
    );
  }

  /// Remove um item da comanda.
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
        title: const Text('Editar Comanda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _estaCarregando ? null : _salvarComanda,
            tooltip: 'Salvar Comanda',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nomeComandaControle,
                decoration: const InputDecoration(
                  labelText: 'Nome da Comanda',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                onChanged: (valor) {
                  // O nome será pego do controlador no momento de salvar,
                  // não é necessário atualizar o estado da comanda aqui.
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Itens da Comanda (Total: R\$${_comandaEmEdicao.total.toStringAsFixed(2)})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Lista de itens da comanda
              _comandaEmEdicao.itens.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Nenhum item adicionado ainda.'),
                  )
                  : ListView.builder(
                    shrinkWrap:
                        true, // Importante para ListView dentro de SingleChildScrollView
                    physics:
                        const NeverScrollableScrollPhysics(), // Desabilita o scroll da lista
                    itemCount: _comandaEmEdicao.itens.length,
                    itemBuilder: (context, index) {
                      final item = _comandaEmEdicao.itens[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                                      // Fallback para imagem de placeholder em caso de erro
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
              const SizedBox(height: 20),
              const Text(
                'Adicionar Novo Item:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nomeItemControle,
                decoration: const InputDecoration(
                  labelText: 'Nome do Item',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _quantidadeItemControle,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _precoItemControle,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço Unitário',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _caminhoFotoItemControle,
                decoration: const InputDecoration(
                  labelText: 'Caminho da Foto (URL opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _adicionarItem,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Adicionar Item'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              if (_estaCarregando) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
