import 'package:flutter/material.dart';

void mostrarMensagem(
  BuildContext context,
  String mensagem, {
  bool isError = false,
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensagem),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}
