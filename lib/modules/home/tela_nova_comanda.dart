import 'package:flutter/material.dart';
import '../../services/db/banco_dados.dart';
import '../../services/db/modelo_comanda.dart';
import '../../app/ui/utils/utilitarios_app.dart';

class TelaNovaComanda extends StatefulWidget {
  final VoidCallback aoSalvar;

  const TelaNovaComanda({super.key, required this.aoSalvar});

  @override
  _TelaNovaComandaState createState() => _TelaNovaComandaState();
}

class _TelaNovaComandaState extends State<TelaNovaComanda> {
  final TextEditingController _nomeControle = TextEditingController();
  final BancoDados _banco = BancoDados();
  bool _estaCarregando = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nomeControle.dispose();
    super.dispose();
  }

  Future<void> _salvarComanda() async {
    if (_estaCarregando || !mounted) return;

    final String nome = _nomeControle.text.trim();

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
      final novaComandaParaSalvar = Comanda(nome: nome, itens: []);

      await _banco.salvarComanda(novaComandaParaSalvar);

      if (!mounted) return;

      widget.aoSalvar();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          mostrarMensagem(context, 'Comanda salva com sucesso!');
        }
      });
    } catch (e) {
      mostrarMensagem(context, 'Erro ao salvar comanda: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _estaCarregando = false);
      }
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
            tooltip: _estaCarregando ? 'Salvando...' : 'Salvar Comanda',
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
            ),
          ),
          const Spacer(),
          if (_estaCarregando) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
