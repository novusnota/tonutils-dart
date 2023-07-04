class LevelMask {
  final int _mask;
  late final int _hashIndex;
  late final int _hashCount;

  LevelMask([this._mask = 0]) {
    _hashIndex = _countSetBits(_mask);
    _hashCount = _hashIndex + 1;
  }

  int get value => _mask;
  int get level => _mask.bitLength;
  int get hashIndex => _hashIndex;
  int get hashCount => _hashCount;

  LevelMask apply(int level) {
    return LevelMask(_mask & ((1 << level) - 1));
  }

  bool isSignificant(int level) {
    return level == 0 || (_mask >> (level - 1)) % 2 != 0;
  }

  static int _countSetBits(int n) {
    n -= ((n >> 1) & 0x55555555);
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333);

    return ((n + (n >> 4) & 0xf0f0f0f) * 0x1010101) >> 24;
  }
}
