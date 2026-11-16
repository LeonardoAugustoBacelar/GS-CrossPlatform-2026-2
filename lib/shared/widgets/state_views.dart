import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';

/// Estados padrão de carregamento, erro e lista vazia.
///
/// Toda tela que carrega dados usa [AsyncValueView] (ou estes widgets
/// diretamente) para que os três estados tenham a mesma aparência no app.

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Carregando dados…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              ExcludeSemantics(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.scrollable = true,
  });

  final String message;
  final VoidCallback? onRetry;

  /// Use `false` quando o widget já estiver dentro de uma lista rolável.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.cloud_off_outlined,
      iconColor: Theme.of(context).colorScheme.error,
      message: message,
      scrollable: scrollable,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.scrollable = true,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  /// Use `false` quando o widget já estiver dentro de uma lista rolável.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: icon,
      iconColor: Theme.of(context).colorScheme.outline,
      message: message,
      action: action,
      scrollable: scrollable,
    );
  }
}

/// Mapeia um [AsyncValue] do Riverpod para carregamento, erro, vazio ou dados,
/// com uma transição curta entre os estados.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = 'Nada por aqui ainda.',
    this.errorMessage = 'Não foi possível carregar os dados.',
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final String errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (key, child) = switch (value) {
      AsyncData(:final value) when isEmpty?.call(value) ?? false => (
        'empty',
        EmptyView(message: emptyMessage),
      ),
      AsyncData(:final value) => ('data', builder(value)),
      AsyncError() => (
        'error',
        ErrorView(message: errorMessage, onRetry: onRetry),
      ),
      _ => ('loading', const LoadingView()),
    };
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.scrollable,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String message;
  final bool scrollable;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 56, color: iconColor)),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
    if (!scrollable) return Center(child: content);
    return Center(child: SingleChildScrollView(child: content));
  }
}
