import 'package:flutter/material.dart';

/// Exibe uma mensagem (SnackBar) na parte inferior da tela.
/// Esta é uma função utilitária para ser reutilizada em diferentes telas.
///
/// [context]: O BuildContext do widget atual, necessário para acessar o ScaffoldMessenger.
/// [mensagem]: O texto a ser exibido na SnackBar.
/// [isError]: Se verdadeiro, a cor de fundo da SnackBar será vermelha (indicando erro),
///            caso contrário, será verde.
void mostrarMensagem(
  BuildContext context,
  String mensagem, {
  bool isError = false,
}) {
  // Verifica se o widget ainda está montado antes de tentar exibir a SnackBar.
  // Embora esta função seja externa, é uma boa prática manter a verificação de `mounted`
  // se o contexto for de um StatefulWidget.
  // No entanto, para uma função utilitária pura, o `mounted` geralmente seria verificado
  // antes de chamar esta função, ou a função poderia ser chamada apenas em contextos seguros.
  // Para simplificar e manter a robustez, mantemos aqui.
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensagem),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}
