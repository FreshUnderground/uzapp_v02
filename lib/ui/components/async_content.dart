import 'package:flutter/material.dart';

import '../../core/l10n/tr.dart';
import 'empty_state.dart';
import 'error_boundary.dart';

/// Shared loading / error / empty handling for [StreamBuilder] and
/// [FutureBuilder] snapshots (Drift streams often emit cached data immediately).
class AsyncContent<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) builder;
  final Widget? loading;
  final bool Function(T data)? isEmpty;
  final Widget Function()? empty;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const AsyncContent({
    super.key,
    required this.snapshot,
    required this.builder,
    this.loading,
    this.isEmpty,
    this.empty,
    this.onRetry,
    this.errorMessage,
  });

  static bool isLoading(AsyncSnapshot<dynamic> snapshot) {
    return snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading(snapshot)) {
      return loading ??
          const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return ErrorFallback(
        message: errorMessage ?? tr(context, 'load_error'),
        onRetry: onRetry,
      );
    }

    if (!snapshot.hasData) {
      return empty?.call() ??
          Center(child: Text(tr(context, 'load_error')));
    }

    final data = snapshot.data as T;
    if (isEmpty != null && isEmpty!(data)) {
      return empty?.call() ?? const SizedBox.shrink();
    }

    return builder(data);
  }
}

/// Resolves a deep-link or push route from a one-shot [Future].
class FutureRouteContent<T> extends StatefulWidget {
  final Future<T?> Function() load;
  final Widget Function(T data) builder;
  final Widget notFound;
  final bool Function(T? data) isNotFound;

  const FutureRouteContent({
    super.key,
    required this.load,
    required this.builder,
    required this.notFound,
    required this.isNotFound,
  });

  @override
  State<FutureRouteContent<T>> createState() => _FutureRouteContentState<T>();
}

class _FutureRouteContentState<T> extends State<FutureRouteContent<T>> {
  late Future<T?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: _future,
      builder: (context, snapshot) {
        if (AsyncContent.isLoading(snapshot)) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: ErrorFallback(
              message: tr(context, 'load_error'),
              onRetry: _retry,
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || widget.isNotFound(data)) {
          return widget.notFound;
        }

        return widget.builder(data);
      },
    );
  }
}

/// Standard empty state for list screens backed by a stream.
class AsyncListEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AsyncListEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
