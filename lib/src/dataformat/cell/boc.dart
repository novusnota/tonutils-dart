import 'dart:math' show max;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:tonutils/src/_utils/bits_for_number.dart';

import '../bitstring/api.dart' show BitReader, BitString, BitBuilder;
import 'api.dart' show Cell;
import 'utils/api.dart'
    show getRefsDescriptor, getBitsDescriptor, topologicalSort;
import '../../crypto/crc/api.dart' show Crc32c;

/// BoC parsing and (de)serialization
sealed class Boc {
  static int _getHashesCount(int levelMask) {
    return _getHashesCountFromMask(levelMask & 7);
  }

  static int _getHashesCountFromMask(int mask) {
    var n = 0;
    for (var i = 0; i < 3; i += 1) {
      n += (mask & 1);
      mask >>= 1;
    }
    return n + 1; // 1 repr + up to 3 higher hashes
  }

  static ({
    BitString bits,
    List<int> refs,
    bool exotic,
  }) _readCell(
    BitReader reader,
    int sizeBytes,
  ) {
    final d1 = reader.loadUint(8);
    final refsCount = d1 % 8;
    final isExotic = (d1 & 8) != 0;

    final d2 = reader.loadUint(8);
    final dataByteSize = (d2 / 2).ceil();
    final paddingAdded = (d2 % 2) != 0;

    final levelMask = d1 >> 5;
    final hasHashes = (d1 & 16) != 0;
    final hashBytes = 32;

    final hashesSize = hasHashes ? _getHashesCount(levelMask) * hashBytes : 0;
    final depthSize = hasHashes ? _getHashesCount(levelMask) * 2 : 0;

    reader.skip(hashesSize * 8);
    reader.skip(depthSize * 8);

    var bits = BitString.empty;
    if (dataByteSize > 0) {
      if (paddingAdded == true) {
        bits = reader.loadPaddedBits(dataByteSize * 8);
      } else {
        bits = reader.loadBits(dataByteSize * 8);
      }
    }

    var refs = <int>[];
    for (var i = 0; i < refsCount; i += 1) {
      refs.add(reader.loadUint(sizeBytes * 8));
    }

    return (
      bits: bits,
      refs: refs,
      exotic: isExotic,
    );
  }

  static int _calcCellSize(Cell cell, int sizeBytes) {
    // D1 + D2
    return 2 + (cell.bits.length / 8).ceil() + cell.refs.length * sizeBytes;
  }

  /// Returns parsed BoC from a passed Uint8List
  static ({
    int size,
    int offBytes,
    int cells,
    int roots,
    int absent,
    int totalCellSize,
    Uint8List? index,
    Uint8List cellData,
    List<int> root,
  }) parse(Uint8List src) {
    var reader = BitReader(BitString(src, 0, src.length * 8));
    var magic = reader.loadUint(32);

    switch (magic) {
      case 0x68ff65f3:
        var size = reader.loadUint(8);
        var offBytes = reader.loadUint(8);

        var cells = reader.loadUint(size * 8);
        var roots = reader.loadUint(size * 8);
        // assert(roots == 1); // Must be 1
        var absent = reader.loadUint(size * 8);

        var totalCellSize = reader.loadUint(offBytes * 8);

        var index = reader.loadList(cells * offBytes);
        var cellData = reader.loadList(totalCellSize);

        return (
          size: size,
          offBytes: offBytes,
          cells: cells,
          roots: roots,
          absent: absent,
          totalCellSize: totalCellSize,
          index: index,
          cellData: cellData,
          root: <int>[0],
        );
      case 0xacc3a728:
        var size = reader.loadUint(8);
        var offBytes = reader.loadUint(8);

        var cells = reader.loadUint(size * 8);
        var roots = reader.loadUint(size * 8);
        // assert(roots == 1); // Must be 1
        var absent = reader.loadUint(size * 8);

        var totalCellSize = reader.loadUint(offBytes * 8);

        var index = reader.loadList(cells * offBytes);
        var cellData = reader.loadList(totalCellSize);

        var crc32 = reader.loadList(4);
        if (Crc32c.ofUint8List(src.sublist(0, src.length - 4)).equals(crc32) ==
            false) {
          throw 'Invalid CRC32C';
        }

        return (
          size: size,
          offBytes: offBytes,
          cells: cells,
          roots: roots,
          absent: absent,
          totalCellSize: totalCellSize,
          index: index,
          cellData: cellData,
          root: <int>[0],
        );
      case 0xb5ee9c72:
        var hasIdx = reader.loadUint(1);
        var hasCrc32c = reader.loadUint(1);
        reader.loadUint(1); // hasCacheBits
        reader.loadUint(2); // flags, must be 0

        var size = reader.loadUint(3);
        var offBytes = reader.loadUint(8);

        var cells = reader.loadUint(size * 8);
        var roots = reader.loadUint(size * 8);
        var absent = reader.loadUint(size * 8);

        var totalCellSize = reader.loadUint(offBytes * 8);

        var root = <int>[];
        for (var i = 0; i < roots; i += 1) {
          root.add(reader.loadUint(size * 8));
        }

        Uint8List? index;
        if (hasIdx != 0) {
          index = reader.loadList(cells * offBytes);
        }

        var cellData = reader.loadList(totalCellSize);
        if (hasCrc32c != 0) {
          var crc32 = reader.loadList(4);
          if (Crc32c.ofUint8List(src.sublist(0, src.length - 4))
                  .equals(crc32) ==
              false) {
            throw 'Invalid CRC32C';
          }
        }

        return (
          size: size,
          offBytes: offBytes,
          cells: cells,
          roots: roots,
          absent: absent,
          totalCellSize: totalCellSize,
          index: index,
          cellData: cellData,
          root: root,
        );
      case _:
        throw 'Invalid magic value!';
    }
  }

  /// Returns a List<Cell> from a Uint8List
  static List<Cell> deserialize(Uint8List src) {
    // Parse BoC
    var boc = parse(src);
    var reader = BitReader(BitString(boc.cellData, 0, boc.cellData.length * 8));

    // Load cells
    var cells = <ExtendedCell>[];
    for (var i = 0; i < boc.cells; i += 1) {
      var cll = _readCell(reader, boc.size);
      cells.add(ExtendedCell(
        bits: cll.bits,
        refs: cll.refs,
        exotic: cll.exotic,
        result: null,
      ));
    }

    // Build cells
    for (var i = cells.length - 1; i >= 0; i -= 1) {
      if (cells[i].result != null) {
        throw 'Impossible cell!';
      }
      var refs = <Cell>[];
      for (var j = 0; j < cells[i].refs.length; j += 1) {
        var r = cells[i].refs[j];
        if (cells[r].result == null) {
          throw 'Invalid BoC file!';
        }
        refs.add(cells[r].result!);
      }
      cells[i].result = Cell(
        bits: cells[i].bits,
        refs: refs,
        exotic: cells[i].exotic,
      );
    }

    // Load roots
    var roots = <Cell>[];
    for (var i = 0; i < boc.root.length; i += 1) {
      assert(cells[boc.root[i]].result != null);
      roots.add(cells[boc.root[i]].result!);
    }

    // Return roots
    return roots;
  }

  static void _writeCellToBuilder(
    Cell cell,
    List<int> refs,
    int sizeBytes,
    BitBuilder to,
  ) {
    var d1 = getRefsDescriptor(cell.refs, cell.level(), cell.type);
    var d2 = getBitsDescriptor(cell.bits);

    to.writeUint(BigInt.from(d1), 8);
    to.writeUint(BigInt.from(d2), 8);
    to.writeList(cell.bits.toPaddedList());

    for (var i = 0; i < refs.length; i += 1) {
      to.writeUint(BigInt.from(refs[i]), sizeBytes * 8);
    }
  }

  /// Returns a Uint8List from a passed root Cell
  static Uint8List serialize(
    Cell root, {
    required bool idx,
    required bool crc32,
  }) {
    var allCells = topologicalSort(root);

    var cellsNum = allCells.length;
    var hasIdx = idx;
    var hasCrc32c = crc32;
    var hasCacheBits = false;
    var flags = 0;
    var sizeBytes =
        max(1, (bitsForNumber(BigInt.from(cellsNum), 'uint') / 8).ceil());
    var totalCellSize = 0;
    var index = <int>[];
    for (var i = 0; i < cellsNum; i += 1) {
      var sz = _calcCellSize(allCells[i].cell, sizeBytes);
      index.add(totalCellSize);
      totalCellSize += sz;
    }

    var offsetBytes =
        max(1, (bitsForNumber(BigInt.from(totalCellSize), 'uint') / 8).ceil());
    var totalSize = 8 *
        (4 + // magic
            1 + // flags and s_bytes
            1 + // offset_bytes
            3 * sizeBytes + // cells_num, roots, complete
            offsetBytes + // full_size
            1 * sizeBytes + // root_idx
            (hasIdx ? cellsNum * offsetBytes : 0) +
            totalCellSize +
            (hasCrc32c ? 4 : 0));

    var builder = BitBuilder(totalSize);
    builder.writeUint(BigInt.from(0xb5ee9c72), 32); // Magic
    builder.writeBool(hasIdx);
    builder.writeBool(hasCrc32c);
    builder.writeBool(hasCacheBits);
    builder.writeUint(BigInt.from(flags), 2);
    builder.writeUint(BigInt.from(sizeBytes), 3);
    builder.writeUint(BigInt.from(offsetBytes), 8);
    builder.writeUint(BigInt.from(cellsNum), sizeBytes * 8);

    // Roots number
    builder.writeUint(BigInt.one, sizeBytes * 8);

    // Absent number
    builder.writeUint(BigInt.zero, sizeBytes * 8);

    // Total cell size
    builder.writeUint(BigInt.from(totalCellSize), offsetBytes * 8);

    // Root id == 0
    builder.writeUint(BigInt.zero, sizeBytes * 8);

    if (hasIdx) {
      for (var i = 0; i < cellsNum; i += 1) {
        builder.writeUint(BigInt.from(index[i]), offsetBytes * 8);
      }
    }
    for (var i = 0; i < cellsNum; i += 1) {
      _writeCellToBuilder(
        allCells[i].cell,
        allCells[i].refs,
        sizeBytes,
        builder,
      );
    }
    if (hasCrc32c) {
      var crc32 = Crc32c.ofUint8List(builder.list());
      builder.writeList(crc32);
    }

    var res = builder.list();
    if (res.length != totalSize ~/ 8) {
      throw 'Internal error when parsing, ${res.length} != $totalSize / 8';
    }
    return res;
  }
}

class ExtendedCell {
  BitString bits;
  List<int> refs;
  bool exotic;
  Cell? result;

  ExtendedCell({
    required this.bits,
    required this.refs,
    required this.exotic,
    this.result,
  });
}
