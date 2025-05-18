import 'package:flutter/material.dart';
import '../../db/database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _comanda = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  Future<void> _carregarItens() async {
    final dados = await _dbHelper.getAllItems();
    if (!mounted) return;
    setState(() {
      _comanda = dados;
    });
  }

  Future<void> _adicionarItem() async {
    final nome = _itemController.text.trim();
    final preco = _priceController.text.trim();

    if (nome.isNotEmpty && preco.isNotEmpty) {
      try {
        await _dbHelper.insertItem({
          'nome': nome,
          'valor': double.parse(preco),
          'quantidade': 1,
        });
        
        _itemController.clear();
        _priceController.clear();
        FocusScope.of(context).unfocus();
        await _carregarItens();
        
      } catch (e) {
        _showError('Erro ao adicionar: ${e.toString()}');
      }
    } else {
      _showError('Preencha nome e preço!');
    }
  }

  void _editarItem(int index) {
    final item = _comanda[index];
    final TextEditingController nomeController = TextEditingController(text: item['nome']);
    final TextEditingController precoController = TextEditingController(text: item['valor'].toString());
    final TextEditingController qtdController = TextEditingController(text: item['quantidade'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: precoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Preço (R\$)'),
              ),
              TextField(
                controller: qtdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbHelper.updateItem(item['id'], {
                  'nome': nomeController.text,
                  'valor': double.parse(precoController.text),
                  'quantidade': int.parse(qtdController.text),
                });
                Navigator.pop(context);
                await _carregarItens();
              } catch (e) {
                _showError('Erro ao editar: ${e.toString()}');
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmarExcluirItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Excluir "${_comanda[index]['nome']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _excluirItem(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirItem(int index) async {
    try {
      await _dbHelper.deleteItem(_comanda[index]['id']);
      await _carregarItens();
    } catch (e) {
      _showError('Erro ao excluir: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  double _calcularTotal() {
    return _comanda.fold(0.0, (total, item) {
      return total + (item['valor'] * item['quantidade']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comanda Digital'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulário para adicionar itens
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _itemController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Item',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preço (R\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _adicionarItem,
                      child: const Text('Adicionar à Comanda'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Lista de itens e total
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'ITENS DA COMANDA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: _comanda.isEmpty
                        ? const Center(child: Text('Nenhum item na comanda'))
                        : ListView.builder(
                            itemCount: _comanda.length,
                            itemBuilder: (context, index) {
                              final item = _comanda[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(item['nome']),
                                  subtitle: Text(
                                    '${item['quantidade']} x R\$${item['valor'].toStringAsFixed(2)}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _editarItem(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmarExcluirItem(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'TOTAL: R\$${_calcularTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}