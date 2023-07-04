import 'dart:convert';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../bitstring/api.dart' show BitString, BitReader;
import 'api.dart'
    show
        Boc,
        Builder,
        LevelMask,
        Slice,
        beginCell,
        resolveExotic,
        wonderCalculator;

/// Cell types, either of: ordinary, prunedBranch, library, merkleProof, merkleUpdate
enum CellType {
  ordinary, // 0, but should be read as -1
  prunedBranch, // 1
  library, // 2
  merkleProof, // 3
  merkleUpdate; // 4
}

/// Cell, as described in TVM spec
class Cell {
  static final Cell empty = Cell();

  /// Returns List<Cell> from passed BoC as a Uint8List
  static List<Cell> fromBoc(Uint8List src) {
    return Boc.deserialize(src);
  }

  /// Returns Cell from passed BoC as a String in base64
  static Cell fromBocBase64(String src) {
    var parsed = Cell.fromBoc(base64.decode(src));
    if (parsed.length != 1) {
      throw 'Can not deserialize more than one cell in this method';
    }
    return parsed[0];
  }

  // Public properties
  late CellType type;
  late final BitString bits;
  late final List<Cell> refs;
  late final LevelMask mask;

  // Level and depth information
  late final List<Uint8List> _hashes;
  late final List<int> _depths;

  Cell({bool? exotic, BitString? bits, List<Cell>? refs}) {
    var vbits = BitString.empty;
    if (bits != null) {
      vbits = bits;
    }

    var vrefs = <Cell>[];
    if (refs != null) {
      vrefs = List.of(refs);
    }

    var hashes = <Uint8List>[];
    var depths = <int>[];
    LevelMask mask;
    var type = CellType.ordinary;

    if (exotic == true) {
      var resolved = resolveExotic(vbits, vrefs);
      var wonders = wonderCalculator(resolved.type, vbits, vrefs);

      mask = wonders.mask;
      depths = wonders.depths;
      hashes = wonders.hashes;
      type = resolved.type;
    } else {
      if (vrefs.length > 4) {
        throw 'Too many references: ${vrefs.length} is greater than 4';
      }
      if (vbits.length > 1023) {
        throw 'Too many bits: ${vbits.length} is greater that 1023';
      }

      var wonders = wonderCalculator(type, vbits, vrefs);
      mask = wonders.mask;
      depths = wonders.depths;
      hashes = wonders.hashes;
    }

    this.type = type;
    this.bits = vbits;
    this.refs = vrefs;
    this.mask = mask;
    _depths = depths;
    _hashes = hashes;
  }

  /// Returns true if CellType isn't ordinary, false otherwise
  bool get isExotic => type != CellType.ordinary;

  /// Returns a new Slice out of the bits and refs of this Cell
  Slice beginParse([bool allowExotic = false]) {
    if (isExotic == true && allowExotic == false) {
      throw 'The cell is exotic, but allowExotic flag is $allowExotic, so the cell cannot be parsed';
    }
    return Slice(BitReader(bits), refs);
  }

  /// Returns Uint8List hash of the Cell
  Uint8List hash([int level = 3]) => _hashes[min(_hashes.length - 1, level)];

  /// Returns int of Cell depth
  int depth([int level = 3]) => _depths[min(_depths.length - 1, level)];

  /// Returns int of Cell level
  int level() => mask.level;

  /// Returns true if cells hashes are equal, false otherwise
  bool equals(Cell other) => hash().equals(other.hash());

  /// Returns a BoC out of this Cell as a Uint8List
  Uint8List toBoc({bool? idx, bool? crc32}) {
    return Boc.serialize(this, idx: idx ?? false, crc32: crc32 ?? true);
  }

  /// Returns this Cell as a String
  @override
  String toString([String? indent]) {
    var id = indent ?? '';
    var t = 'x';
    if (isExotic) {
      t = switch (type) {
        CellType.merkleProof => 'p',
        CellType.merkleUpdate => 'u',
        CellType.prunedBranch => 'p',
        _ => 'x'
      };
    }
    var s = StringBuffer('$id$t{${bits.toString()}}');
    for (var i = 0; i < refs.length; i += 1) {
      s.write('\n${refs[i].toString('$id ')}');
    }
    return s.toString();
  }

  /// Returns a Slice out of this Cell
  Slice asSlice() {
    return beginParse();
  }

  /// Returns a Builder out of this Cell
  Builder asBuilder() {
    return beginCell().storeSlice(asSlice());
  }
}
