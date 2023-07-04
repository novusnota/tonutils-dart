import 'dart:typed_data';

/// CRC32C
sealed class Crc32c {
  static final _poly = 0x82f63b78;

  /// Returns Uint8List after applying CRC32C to passed Uint8List
  static Uint8List ofUint8List(Uint8List data) {
    var crc = 0 ^ 0xffffffff;

    for (var i = 0; i < data.length; i += 1) {
      crc ^= data[i];
      for (var j = 0; j < 8; j += 1) {
        crc = (crc & 1) == 1 ? (crc >>> 1) ^ _poly : crc >>> 1;
      }
    }
    crc = crc ^ 0xffffffff;

    var res = Uint8List(4);
    ByteData.view(res.buffer)
        .setInt32(0, crc, Endian.little); // Endian.big by default

    return res;
  }
}
