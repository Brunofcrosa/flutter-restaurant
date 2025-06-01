// lib/modules/home/tela_nova_comanda.dart
import 'package:flutter/material.dart';

import '../../services/db/banco_dados.dart';
import '../../services/db/modelo_comanda.dart';

class TelaNovaComanda extends StatefulWidget {
  final VoidCallback aoSalvar;

  const TelaNovaComanda({super.key, required this.aoSalvar});

  @override
  _TelaNovaComandaState createState() => _TelaNovaComandaState();
}

class _TelaNovaComandaState extends State<TelaNovaComanda> {
  late Comanda _novaComanda;
  final TextEditingController _nomeControle = TextEditingController();

  final BancoDados _banco = BancoDados();

  bool _estaCarregando = false;

  @override
  void initState() {
    super.initState();
    _novaComanda = Comanda(nome: 'Nova Comanda');
    _nomeControle.text = _novaComanda.nome;
  }

  @override
  void dispose() {
    _nomeControle.dispose();
    super.dispose();
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _salvarComanda() async {
    final String nome = _nomeControle.text.trim();

    if (nome.isEmpty) {
      _mostrarErro('O nome da comanda não pode ser vazio.');
      return;
    }

    setState(() => _estaCarregando = true);

    try {
      await _banco.salvarComanda(_novaComanda.copiarCom(nome: nome, itens: []));
      widget.aoSalvar();
      _mostrarMensagem('Comanda salva com sucesso!');
      Navigator.pop(context);
    } catch (e) {
      _mostrarErro('Erro ao salvar comanda: $e');
    } finally {
      setState(() => _estaCarregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Comanda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _estaCarregando ? null : _salvarComanda,
            tooltip: 'Salvar Comanda',
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
                  _novaComanda = _novaComanda.copiarCom(nome: valor);
                });
              },
            ),
          ),
          const Spacer(),
          if (_estaCarregando)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }
}