int bitsForNumber(BigInt src, String mode) {
  switch (mode) {
    case 'int':
      if (src == BigInt.zero || src == -BigInt.one) {
        return 1;
      }
      var res = src > BigInt.zero ? src : -src;
      return (res.toRadixString(2).length + 1);

    case 'uint':
      if (src < BigInt.zero) {
        throw 'Value $src is negative, but uint mode works only with non-negative values';
      }
      return (src.toRadixString(2).length);

    case _:
      throw 'Invalid mode $mode';
  }
}
