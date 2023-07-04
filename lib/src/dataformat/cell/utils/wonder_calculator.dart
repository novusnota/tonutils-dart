import 'dart:math' show max;
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';

import '../../bitstring/api.dart' show BitString;
import '../api.dart' show CellType, Cell, LevelMask, getRepr;
import 'api.dart'
    show
        ExoticPruned,
        exoticPruned,
        exoticLibrary,
        exoticMerkleProof,
        exoticMerkleUpdate;

/// Returns a record ({LevelMask mask, List<Uint8List> hashes, List<int> depths})
/// Replicates unknown logic of resolving cell data:
/// https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/vm/cells/DataCell.cpp#L214
({
  LevelMask mask,
  List<Uint8List> hashes,
  List<int> depths,
}) wonderCalculator(CellType type, BitString bits, List<Cell> refs) {
  //
  // Resolving level mask
  //

  LevelMask levelMask;
  ExoticPruned? pruned;

  switch (type) {
    case CellType.ordinary:
      var mask = 0;
      for (var i = 0; i < refs.length; i += 1) {
        mask |= refs[i].mask.value;
      }
      levelMask = LevelMask(mask);

    case CellType.prunedBranch:
      pruned = exoticPruned(bits, refs);
      // load level
      levelMask = LevelMask(pruned.mask);

    case CellType.library:
      var _ = exoticLibrary(bits, refs);
      // load level
      levelMask = LevelMask();

    case CellType.merkleProof:
      var _ = exoticMerkleProof(bits, refs);
      // load level
      levelMask = LevelMask(refs[0].mask.value >> 1);

    case CellType.merkleUpdate:
      var _ = exoticMerkleUpdate(bits, refs);
      // load level
      levelMask = LevelMask((refs[0].mask.value | refs[1].mask.value) >> 1);
  }

  //
  // Calculate hashes and depths
  //

  var depths = <int>[];
  var hashes = <Uint8List>[];

  var hashCount = type == CellType.prunedBranch ? 1 : levelMask.hashCount;
  var totalHashCount = levelMask.hashCount;
  var hashIOffset = totalHashCount - hashCount;

  for (var levelI = 0, hashI = 0; levelI <= levelMask.level; levelI += 1) {
    if (levelMask.isSignificant(levelI) == false) {
      continue;
    }
    if (hashI < hashIOffset) {
      hashI += 1;
      continue;
    }

    //
    // Bits
    //

    BitString currentBits;
    if (hashI == hashIOffset) {
      if ((levelI == 0 || type == CellType.prunedBranch) == false) {
        throw 'Invalid level $levelI or type $type';
      }
      currentBits = bits;
    } else {
      if ((levelI != 0 && type != CellType.prunedBranch) == false) {
        throw 'Invalid level $levelI (not 0) and type $type (not CellType.prunedBranch)';
      }
      currentBits = BitString(hashes[hashI - hashIOffset - 1], 0, 256);
    }

    //
    // Depth
    //

    var currentDepth = 0;
    for (var j = 0; j < refs.length; j += 1) {
      int childDepth;
      switch (type) {
        case CellType.merkleProof:
        case CellType.merkleUpdate:
          childDepth = refs[j].depth(levelI + 1);
        case _:
          childDepth = refs[j].depth(levelI);
      }
      currentDepth = max(currentDepth, childDepth);
    }
    if (refs.isNotEmpty) {
      currentDepth += 1;
    }

    //
    // Hash
    //

    var repr = getRepr(bits, currentBits, refs, levelI, type);
    var hash = SHA256Digest().process(repr);

    // Persist next

    var destI = hashI - hashIOffset;
    if (destI > depths.length - 1) {
      depths.addAll(List.filled(destI - (depths.length - 1), 0));
    }
    depths[destI] = currentDepth;

    if (destI > hashes.length - 1) {
      hashes.addAll(List.filled(destI - (hashes.length - 1), Uint8List(0)));
    }
    hashes[destI] = hash;

    // Next

    hashI += 1;
  }

  //
  // Calculating hash and depth for all levels
  //

  var resolvedHashes = <Uint8List>[];
  var resolvedDepths = <int>[];

  if (pruned != null) {
    for (var i = 0; i < 4; i += 1) {
      final hashIndex = levelMask.apply(i).hashIndex;
      final thisHashIndex = levelMask.hashIndex;

      if (hashIndex != thisHashIndex) {
        resolvedHashes.add(pruned.pruned[hashIndex].hash);
        resolvedDepths.add(pruned.pruned[hashIndex].depth);
      } else {
        resolvedHashes.add(hashes[0]);
        resolvedDepths.add(depths[0]);
      }
    }
  } else {
    for (var i = 0; i < 4; i += 1) {
      var tgt = levelMask.apply(i).hashIndex;

      assert(hashes.length > tgt);
      assert(depths.length > tgt);

      resolvedHashes.add(hashes[tgt]);
      resolvedDepths.add(depths[tgt]);
    }
  }

  return (
    mask: levelMask,
    hashes: resolvedHashes,
    depths: resolvedDepths,
  );
}
