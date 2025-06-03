import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurante/modules/home/tela_editar_comanda.dart';
import 'package:restaurante/modules/home/tela_nova_comanda.dart';
import '../../services/db/banco_dados.dart';
import '../../services/db/modelo_comanda.dart';
import '../../app/ui/utils/utilitarios_app.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  _TelaInicialState createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final BancoDados _banco = BancoDados();
  List<Comanda> _comandas = [];

  @override
  void initState() {
    super.initState();
    _carregarComandas();
  }

  Future<void> _carregarComandas() async {
    try {
      final comandas = await _banco.listarComandas();
      if (mounted) {
        setState(() => _comandas = comandas);
      }
    } catch (e) {
      mostrarMensagem(context, 'Erro ao carregar comandas: $e', isError: true);
    }
  }

  void _abrirComanda(Comanda comanda) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TelaEditarComanda(
              comanda: comanda,
              aoSalvar: _carregarComandas,
            ),
      ),
    );
  }

  Future<void> _removerComanda(int id) async {
    try {
      await _banco.removerComanda(id);
      await _carregarComandas();
      mostrarMensagem(context, 'Comanda removida com sucesso!');
    } catch (e) {
      mostrarMensagem(context, 'Erro ao remover comanda: $e', isError: true);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Nenhuma comanda encontrada.\nComece adicionando uma nova comanda!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildComandaItem(Comanda comanda) {
    final dataFormatada = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(comanda.dataCriacao);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        title: Text(
          comanda.nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '$dataFormatada - Total: R\$${comanda.total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _abrirComanda(comanda),
              tooltip: 'Editar Comanda',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removerComanda(comanda.id!),
              tooltip: 'Remover Comanda',
            ),
          ],
        ),
        onTap: () => _abrirComanda(comanda),
      ),
    );
  }

  Widget _buildNewComandaButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TelaNovaComanda(aoSalvar: _carregarComandas),
                ),
              ),
          icon: const Icon(Icons.add),
          label: const Text('Nova Comanda'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Comandas')),
      body: Column(
        children: [
          Expanded(
            child:
                _comandas.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      itemCount: _comandas.length,
                      itemBuilder:
                          (context, index) =>
                              _buildComandaItem(_comandas[index]),
                    ),
          ),
          _buildNewComandaButton(),
        ],
      ),
    );
  }
}
