import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatação de datas
import 'package:restaurante/modules/home/tela_editar_comanda.dart'; // Importa a tela de edição
import 'package:restaurante/modules/home/tela_nova_comanda.dart'; // Importa a tela de nova comanda
import '../../services/db/banco_dados.dart'; // Importa o serviço de banco de dados
import '../../services/db/modelo_comanda.dart'; // Importa os modelos de dados
import '../../app/ui/utils/utilitarios_app.dart'; // Importa a função utilitária para mensagens

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  _TelaInicialState createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final BancoDados _banco =
      BancoDados(); // Instância do serviço de banco de dados
  List<Comanda> _comandas = []; // Lista de comandas a ser exibida

  @override
  void initState() {
    super.initState();
    _carregarComandas(); // Carrega as comandas ao inicializar a tela
  }

  /// Carrega a lista de comandas do banco de dados.
  Future<void> _carregarComandas() async {
    try {
      final comandas = await _banco.listarComandas(); // Busca as comandas
      // Verifica se o widget ainda está montado antes de atualizar o estado.
      if (mounted) {
        setState(
          () => _comandas = comandas,
        ); // Atualiza a lista de comandas no estado
      }
    } catch (e) {
      // Em caso de erro, exibe uma mensagem usando a função utilitária.
      mostrarMensagem(
        context,
        'Erro ao carregar comandas: $e',
        isError: true,
      ); // Passa o context
    }
  }

  /// Abre a tela de edição de uma comanda existente.
  ///
  /// [comanda]: A comanda a ser editada.
  void _abrirComanda(Comanda comanda) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TelaEditarComanda(
              comanda: comanda,
              aoSalvar:
                  _carregarComandas, // Callback para recarregar as comandas após salvar
            ),
      ),
    );
  }

  /// Remove uma comanda do banco de dados.
  ///
  /// [id]: O ID da comanda a ser removida.
  Future<void> _removerComanda(int id) async {
    try {
      await _banco.removerComanda(id); // Remove a comanda do banco
      await _carregarComandas(); // Recarrega a lista para refletir a remoção
      mostrarMensagem(
        context,
        'Comanda removida com sucesso!',
      ); // Passa o context
    } catch (e) {
      // Em caso de erro, exibe uma mensagem usando a função utilitária.
      mostrarMensagem(
        context,
        'Erro ao remover comanda: $e',
        isError: true,
      ); // Passa o context
    }
  }

  /// Constrói o widget a ser exibido quando não há comandas.
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Nenhuma comanda encontrada.\nComece adicionando uma nova comanda!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  /// Constrói um item individual da lista de comandas.
  ///
  /// [comanda]: A comanda a ser exibida.
  Widget _buildComandaItem(Comanda comanda) {
    // Formata a data de criação da comanda.
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
              onPressed:
                  () => _removerComanda(comanda.id!), // O ID não será nulo aqui
              tooltip: 'Remover Comanda',
            ),
          ],
        ),
        onTap: () => _abrirComanda(comanda), // Abre a comanda ao tocar no item
      ),
    );
  }

  /// Constrói o botão para adicionar uma nova comanda.
  Widget _buildNewComandaButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity, // Ocupa a largura máxima disponível
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
                    ? _buildEmptyState() // Exibe estado vazio se não houver comandas
                    : ListView.builder(
                      itemCount: _comandas.length,
                      itemBuilder:
                          (context, index) => _buildComandaItem(
                            _comandas[index],
                          ), // Constrói cada item da lista
                    ),
          ),
          _buildNewComandaButton(), // Botão para adicionar nova comanda
        ],
      ),
    );
  }
}
