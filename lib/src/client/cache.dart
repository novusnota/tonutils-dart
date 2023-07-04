abstract class TonCache {
  void set(String namespace, String key, String value);
  void unset(String namespace, String key);
  String? get(String namespace, String key);
}

class InMemoryCache extends TonCache {
  final Map<String, String> _cache = <String, String>{};

  @override
  String? get(String namespace, String key) {
    var formedKey = _formKey(namespace, key);
    if (_cache.containsKey(formedKey)) {
      return _cache[formedKey];
    }
    return null;
  }

  @override
  void set(String namespace, String key, String value) {
    var formedKey = _formKey(namespace, key);
    _cache[formedKey] = value;
  }

  @override
  void unset(String namespace, String key) {
    var formedKey = _formKey(namespace, key);
    if (_cache.containsKey(formedKey)) {
      _cache.remove(formedKey);
    }
  }

  String _formKey(String namespace, String key) {
    return '$namespace\$\$$key';
  }
}
