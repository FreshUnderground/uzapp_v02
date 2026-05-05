import 'dart:async';
import 'package:flutter/foundation.dart';

/// Generic lazy loader that defers computation until first access.
///
/// Useful for loading shop details only when a product detail is viewed,
/// avoiding upfront cost on low-end devices.
class LazyLoader<T> {
  final Future<T> Function() _loader;
  final List<void Function(T)> _onLoadedCallbacks = [];

  T? _value;
  bool _isLoading = false;
  bool _isLoaded = false;
  Object? _lastError;

  LazyLoader(this._loader);

  /// Whether the value has been successfully loaded at least once.
  bool get isLoaded => _isLoaded;

  /// The current value, or `null` if not yet loaded.
  T? get valueOrNull => _value;

  /// The last error encountered while loading, or `null`.
  Object? get lastError => _lastError;

  /// Whether a load operation is currently in progress.
  bool get isLoading => _isLoading;

  /// Retrieves the value, loading it on first access.
  ///
  /// If a load is already in progress, the caller waits for it to complete
  /// instead of triggering a duplicate request.
  Future<T> get value async {
    if (_isLoaded && _value != null) return _value!;

    if (_isLoading) {
      // Wait for the current load to finish
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_value != null) return _value!;
      // If load failed, retry once
      return _load();
    }

    return _load();
  }

  Future<T> _load() async {
    _isLoading = true;
    _lastError = null;
    try {
      _value = await _loader();
      _isLoaded = true;
      _notifyLoaded(_value as T);
    } catch (e) {
      _lastError = e;
      debugPrint('LazyLoader: failed to load – $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
    return _value!;
  }

  /// Register a callback to be invoked when the value is first loaded.
  void onLoaded(void Function(T) callback) {
    _onLoadedCallbacks.add(callback);
  }

  void _notifyLoaded(T value) {
    for (final cb in _onLoadedCallbacks) {
      try {
        cb(value);
      } catch (e) {
        debugPrint('LazyLoader: onLoaded callback error – $e');
      }
    }
  }

  /// Mark the value as stale so the next access triggers a fresh load.
  void invalidate() {
    _value = null;
    _isLoaded = false;
    _lastError = null;
  }
}

/// Cached list with pagination support.
///
/// Loads items page by page as needed, making it suitable for large
/// product catalogues on devices with limited memory.
class PaginatedLazyList<T> extends ChangeNotifier {
  final Future<List<T>> Function(int page, int perPage) _fetcher;
  final int perPage;

  final List<T> _items = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  Object? _lastError;

  /// An unmodifiable view of the currently loaded items.
  List<T> get items => List.unmodifiable(_items);

  /// Whether more pages may be available on the server.
  bool get hasMore => _hasMore;

  /// Whether a load operation is currently in progress.
  bool get isLoading => _isLoading;

  /// The total number of items currently loaded.
  int get length => _items.length;

  /// The last error encountered, or `null`.
  Object? get lastError => _lastError;

  PaginatedLazyList(this._fetcher, {this.perPage = 20});

  /// Load the next page of items.
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final newItems = await _fetcher(_currentPage + 1, perPage);
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length >= perPage;
      }
    } catch (e) {
      _lastError = e;
      debugPrint('PaginatedLazyList: load failed – $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset and reload from scratch.
  Future<void> refresh() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    _lastError = null;
    notifyListeners();
    await loadMore();
  }

  /// Preload up to [count] items, fetching additional pages as needed.
  Future<void> preload(int count) async {
    while (_items.length < count && _hasMore && !_isLoading) {
      await loadMore();
    }
  }
}
