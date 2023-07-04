import 'dart:typed_data';

import 'package:test/test.dart' show expect, group, test;
import 'package:tonutils/tonutils.dart' show BitString, Cell, CellType;

void main() {
  group('dataformat/cell/cell', () {
    test('Constructing empty cell', () {
      var cell = Cell();

      expect(cell.type, CellType.ordinary);
      expect(cell.bits.equals(BitString(Uint8List(0), 0, 0)), true);
      expect(cell.refs, <Cell>[]);
    });
  });
}
