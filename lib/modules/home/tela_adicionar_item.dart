import 'package:flutter/material.dart';
import '../../services/db/modelo_comanda.dart';
import '../../app/ui/utils/utilitarios_app.dart';

class TelaAdicionarItem extends StatefulWidget {
  const TelaAdicionarItem({super.key});

  @override
  _TelaAdicionarItemState createState() => _TelaAdicionarItemState();
}

class _TelaAdicionarItemState extends State<TelaAdicionarItem> {
  final TextEditingController _nomeItemControle = TextEditingController();
  final TextEditingController _quantidadeItemControle = TextEditingController();
  final TextEditingController _precoItemControle = TextEditingController();
  final TextEditingController _caminhoFotoItemControle =
      TextEditingController();

  @override
  void dispose() {
    _nomeItemControle.dispose();
    _quantidadeItemControle.dispose();
    _precoItemControle.dispose();
    _caminhoFotoItemControle.dispose();
    super.dispose();
  }

  void _salvarItem() {
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
        'Por favor, preencha nome, quantidade e preço válidos.',
        isError: true,
      );
      return;
    }

    final newItem = ItemComanda(
      nome: nome,
      quantidade: quantidade,
      preco: preco,
      caminhoFoto: caminhoFoto,
    );

    Navigator.of(context).pop(newItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Novo Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nomeItemControle,
              decoration: const InputDecoration(
                labelText: 'Nome do Item',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _quantidadeItemControle,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _precoItemControle,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Preço Unitário',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _caminhoFotoItemControle,
              decoration: const InputDecoration(
                labelText: 'Caminho da Foto (URL opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _salvarItem,
              icon: const Icon(Icons.check),
              label: const Text('Salvar Item'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
