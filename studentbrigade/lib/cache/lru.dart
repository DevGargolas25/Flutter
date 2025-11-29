// lib/cache/lru.dart
import 'dart:collection';

class LruCache<K, V> {
  final int capacity;
  final _cache = LinkedHashMap<K, V>();

  LruCache(this.capacity) : assert(capacity > 0);

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;

    // Mover el elemento al final (más reciente)
    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= capacity) {
      _cache.remove(_cache.keys.first); // evict LRU (primer elemento)
    }
    _cache[key] = value;
  }

  bool containsKey(K key) => _cache.containsKey(key);
  void clear() => _cache.clear();
  int get length => _cache.length;

  // Exponer el mapa interno para acceso al orden
  LinkedHashMap<K, V> get cache => _cache;
}
