import 'package:flutter/material.dart';
import '../../services/db/banco_dados.dart';
import '../../services/db/modelo_comanda.dart';
import '../../app/ui/utils/utilitarios_app.dart'; // Importa a função utilitária para mensagens

class TelaNovaComanda extends StatefulWidget {
  final VoidCallback aoSalvar;

  const TelaNovaComanda({super.key, required this.aoSalvar});

  @override
  _TelaNovaComandaState createState() => _TelaNovaComandaState();
}

class _TelaNovaComandaState extends State<TelaNovaComanda> {
  final TextEditingController _nomeControle = TextEditingController();
  final BancoDados _banco = BancoDados();
  bool _estaCarregando = false; // Controla o estado de carregamento

  @override
  void initState() {
    super.initState();
    // Você pode iniciar o campo de texto com um valor padrão, se desejar.
    // _nomeControle.text = 'Nova Comanda';
  }

  @override
  void dispose() {
    _nomeControle
        .dispose(); // Libera o controlador quando o widget é descartado
    super.dispose();
  }

  /// Tenta salvar a nova comanda no banco de dados.
  Future<void> _salvarComanda() async {
    // Impede múltiplas chamadas enquanto já está carregando ou se o widget não está montado.
    if (_estaCarregando || !mounted) return;

    final String nome =
        _nomeControle.text.trim(); // Obtém o nome e remove espaços extras.

    // Validação: o nome da comanda não pode ser vazio.
    if (nome.isEmpty) {
      mostrarMensagem(
        context,
        'O nome da comanda não pode ser vazio.',
        isError: true,
      ); // Passa o context
      return;
    }

    // Define o estado de carregamento para true para exibir um indicador e desabilitar o botão.
    setState(() => _estaCarregando = true);

    try {
      // Cria uma nova instância de Comanda com o nome digitado.
      // O 'id' é null para que o banco de dados atribua um novo.
      // 'itens' é uma lista vazia, pois uma nova comanda não tem itens inicialmente.
      final novaComandaParaSalvar = Comanda(
        nome: nome,
        itens: [], // Nova comanda começa sem itens
      );

      // Salva a comanda no banco de dados.
      await _banco.salvarComanda(novaComandaParaSalvar);

      // Verifica novamente se o widget está montado antes de continuar após a operação assíncrona.
      if (!mounted) return;

      // Chama o callback para notificar a tela anterior que a comanda foi salva.
      widget.aoSalvar();

      // Agenda a navegação e a mensagem para depois que o frame atual for construído.
      // Isso evita problemas se o contexto for alterado rapidamente.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(); // Fecha a tela atual
          mostrarMensagem(
            context,
            'Comanda salva com sucesso!',
          ); // Passa o context
        }
      });
    } catch (e) {
      // Em caso de erro, exibe uma mensagem.
      mostrarMensagem(
        context,
        'Erro ao salvar comanda: $e',
        isError: true,
      ); // Passa o context
    } finally {
      // Garante que o estado de carregamento seja redefinido para false, mesmo em caso de erro.
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
            // Desabilita o botão se estiver carregando para evitar cliques múltiplos.
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
              controller: _nomeControle, // Controla o texto do campo
              decoration: const InputDecoration(
                labelText: 'Nome da Comanda',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
              // Não é necessário chamar setState aqui, pois o nome é pego do _nomeControle.text
              // diretamente no _salvarComanda().
              // onChanged: (valor) { /* Sem necessidade de setState aqui */ },
            ),
          ),
          const Spacer(), // Ocupa o espaço restante
          // Exibe um indicador de progresso linear quando estiver carregando.
          if (_estaCarregando) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
