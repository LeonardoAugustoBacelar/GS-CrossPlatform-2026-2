import 'package:flutter/material.dart';

/// Mostra uma mensagem curta, substituindo a anterior (nunca empilha).
///
/// Com leitor de tela ativo o Flutter não fecha a mensagem sozinho; por isso
/// ela é flutuante e tem botão de fechar (veja `snackBarTheme` em AppTheme).
void showFeedback(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
}
