import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';

import '../api.dart' show Cell, CellType, LevelMask;
import '../../bitstring/api.dart' show BitString, BitReader;

class PrunedCell {
  int depth;
  Uint8List hash;

  PrunedCell({
    required this.depth,
    required this.hash,
  });
}

class ExoticPruned {
  int mask;
  List<PrunedCell> pruned;

  ExoticPruned({
    required this.mask,
    required this.pruned,
  });
}

class ExoticCell {
  CellType type;
  List<int> depths;
  List<Uint8List> hashes;
  LevelMask mask;

  ExoticCell({
    required this.type,
    required this.depths,
    required this.hashes,
    required this.mask,
  });
}

/// Returns a ExoticPruned representation of a passed Cell of bits and refs
ExoticPruned exoticPruned(BitString bits, List<Cell> refs) {
  var reader = BitReader(bits);
  var type = reader.loadUint(8);

  if (type != 1) {
    throw 'Pruned Branch cell must have type 1, got $type';
  }
  if (refs.isNotEmpty) {
    throw 'Pruned Branch cell can not have refs, got ${refs.length}';
  }

  LevelMask mask;
  if (bits.length == 280) {
    // Special case for config proof - this test proof is generated in the moment of voting for a slashing.
    // It seems that tools generate it incorrectly and therefore doesn't have mask in it, so we need to hardcode it equal to 1

    mask = LevelMask(1);
  } else {
    mask = LevelMask(reader.loadUint(8));
    if (mask.level < 1 || mask.level > 3) {
      throw 'Pruned Branch cell level must be >= 1 and <= 3, got ${mask.level}/${mask.value}';
    }
    //                                                       256 Hash + 16 Depth
    final size = 8 + 8 + (mask.apply(mask.level - 1).hashCount * (256 + 16));
    if (bits.length != size) {
      throw 'Pruned Branch cell must have exactly $size bits, got ${bits.length}';
    }
  }

  var pruned = <PrunedCell>[];
  var hashes = <Uint8List>[];
  var depths = <int>[];

  for (var i = 0; i < mask.level; i += 1) {
    hashes.add(reader.loadList(32));
  }
  for (var i = 0; i < mask.level; i += 1) {
    depths.add(reader.loadUint(16));
  }
  for (var i = 0; i < mask.level; i += 1) {
    pruned.add(PrunedCell(
      depth: depths[i],
      hash: hashes[i],
    ));
  }

  return ExoticPruned(
    mask: mask.value,
    pruned: pruned,
  );
}

/// Returns empty record
() exoticLibrary(BitString bits, List<Cell> refs) {
  final reader = BitReader(bits);

  // type + hash
  if (bits.length != 8 + 256) {
    throw 'Library cell must have exactly (8 + 256) bits, got ${bits.length}';
  }

  var type = reader.loadUint(8);
  if (type != 2) {
    throw 'Library cell must have type 2, got $type';
  }

  return ();
}

/// Returns a record of proofDepth as int, proofHash as Uint8List for one reference in Merkle Proof cell
({
  int proofDepth,
  Uint8List proofHash,
}) exoticMerkleProof(BitString bits, List<Cell> refs) {
  final reader = BitReader(bits);

  // type + hash + depth
  if (bits.length != 8 + 256 + 16) {
    throw 'Merkle Proof cell must have exactly (8 + 256 + 16) bits, got ${bits.length}';
  }

  if (refs.length != 1) {
    throw 'Merkle Proof cell must have exactly 1 reference, got ${refs.length}';
  }

  var type = reader.loadUint(8);
  if (type != 3) {
    throw 'Merkle Proof cell must have type 3, got $type';
  }

  final proofHash = reader.loadList(32);
  final proofDepth = reader.loadUint(16);
  final refHash = refs[0].hash(0);
  final refDepth = refs[0].depth(0);

  if (proofDepth != refDepth) {
    throw 'Merkle Proof cell reference depth must be exactly $proofDepth, got $refDepth';
  }

  if (!proofHash.equals(refHash)) {
    throw 'Merkle Proof cell reference hash must be exactly ${hex.encode(proofHash)}, got ${hex.encode(refHash)}';
  }

  return (
    proofDepth: proofDepth,
    proofHash: proofHash,
  );
}

/// Returns a record of two proofDepth as int, proofHash as Uint8List, with one for each referenced in Merkle Update cell
({
  int proofDepth1,
  int proofDepth2,
  Uint8List proofHash1,
  Uint8List proofHash2,
}) exoticMerkleUpdate(BitString bits, List<Cell> refs) {
  final reader = BitReader(bits);

  // type + 2 * (hash + depth)
  if (bits.length != 8 + 2 * (256 + 16)) {
    throw 'Merkle Update cell must have exactly (8 + 2 * (256 + 16)) bits, got ${bits.length}';
  }

  if (refs.length != 2) {
    throw 'Merkle Update cell must have exactly 2 references, got ${refs.length}';
  }

  var type = reader.loadUint(8);
  if (type != 4) {
    throw 'Merkle Update cell type must be exactly 4, got $type';
  }

  final proofHash1 = reader.loadList(32);
  final proofHash2 = reader.loadList(32);
  final proofDepth1 = reader.loadUint(16);
  final proofDepth2 = reader.loadUint(16);

  if (proofDepth1 != refs[0].depth(0)) {
    throw 'MerkleUpdate cell reference depth must be exactly $proofDepth1, got ${refs[0].depth(0)}';
  }
  if (!proofHash1.equals(refs[0].hash(0))) {
    throw 'MerkleUpdate cell reference hash must be exactly ${hex.encode(proofHash1)}, got ${hex.encode(refs[0].hash(0))}';
  }

  if (proofDepth2 != refs[1].depth(0)) {
    throw 'MerkleUpdate cell reference depth must be exactly $proofDepth2, got ${refs[1].depth(0)}';
  }
  if (!proofHash2.equals(refs[1].hash(0))) {
    throw 'MerkleUpdate cell reference hash must be exactly ${hex.encode(proofHash2)}, got ${hex.encode(refs[1].hash(0))}';
  }

  return (
    proofDepth1: proofDepth1,
    proofDepth2: proofDepth2,
    proofHash1: proofHash1,
    proofHash2: proofHash2,
  );
}

ExoticCell _resolvePruned(BitString bits, List<Cell> refs) {
  var pruned = exoticPruned(bits, refs);

  var depths = <int>[];
  var hashes = <Uint8List>[];
  var mask = LevelMask(pruned.mask);

  for (var i = 0; i < pruned.pruned.length; i += 1) {
    depths.add(pruned.pruned[i].depth);
    hashes.add(pruned.pruned[i].hash);
  }

  return ExoticCell(
    type: CellType.prunedBranch,
    depths: depths,
    hashes: hashes,
    mask: mask,
  );
}

ExoticCell _resolveLibrary(BitString bits, List<Cell> refs) {
  var _ = exoticLibrary(bits, refs);

  var depths = <int>[];
  var hashes = <Uint8List>[];
  var mask = LevelMask();

  return ExoticCell(
    type: CellType.library,
    depths: depths,
    hashes: hashes,
    mask: mask,
  );
}

ExoticCell _resolveMerkleProof(BitString bits, List<Cell> refs) {
  var _ = exoticMerkleProof(bits, refs);

  var depths = <int>[];
  var hashes = <Uint8List>[];
  var mask = LevelMask(refs[0].level() >> 1);

  return ExoticCell(
    type: CellType.merkleProof,
    depths: depths,
    hashes: hashes,
    mask: mask,
  );
}

ExoticCell _resolveMerkleUpdate(BitString bits, List<Cell> refs) {
  var _ = exoticMerkleUpdate(bits, refs);

  var depths = <int>[];
  var hashes = <Uint8List>[];
  var mask = LevelMask((refs[0].level() | refs[1].level()) >> 1);

  return ExoticCell(
    type: CellType.merkleUpdate,
    depths: depths,
    hashes: hashes,
    mask: mask,
  );
}

/// Returns a ExoticCell out of the Cell read by internal BitReader
ExoticCell resolveExotic(BitString bits, List<Cell> refs) {
  var reader = BitReader(bits);
  var type = reader.preloadUint(8);

  return switch (type) {
    1 => _resolvePruned(bits, refs),
    2 => _resolveLibrary(bits, refs),
    3 => _resolveMerkleProof(bits, refs),
    4 => _resolveMerkleUpdate(bits, refs),
    _ => throw 'Invalid exotic cell type: $type',
  };
}
