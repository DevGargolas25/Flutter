// lib/cache/lru.dart
import 'dart:collection';

class LruCache<K, V> {
  final int capacity;
  final _map = LinkedHashMap<K, V>();

  LruCache(this.capacity) : assert(capacity > 0);

  V? get(K key) {
    final val = _map.remove(key);
    if (val != null) _map[key] = val; // move to MRU
    return val;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      _map.remove(_map.keys.first); // evict LRU
    }
    _map[key] = value;
  }

  bool containsKey(K key) => _map.containsKey(key);
  void clear() => _map.clear();
  int get length => _map.length;
}
