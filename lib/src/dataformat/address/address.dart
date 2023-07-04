import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';

import '../../crypto/crc/api.dart' show Crc16;

/// Either of: InternalAddress or ExternalAddress
sealed class Address {
  static const bounceableTag = 0x11;
  static const nonBounceableTag = 0x51;
  static const testFlag = 0x80;
}

/// (bool isBounceable, bool isTestOnly, InternalAddress address)
class AddressParams {
  final bool isBounceable;
  final bool isTestOnly;
  final InternalAddress address;

  /// (bool isBounceable, bool isTestOnly, InternalAddress address)
  AddressParams(this.isBounceable, this.isTestOnly, this.address);
}

/// Class for working with External Addresses
class ExternalAddress extends Address {
  final BigInt value;
  final int bits;

  ExternalAddress(this.value, this.bits);

  @override
  String toString() {
    return 'External<$bits:$value>';
  }
}

class InternalAddress extends Address {
  final Uint8List hash;
  final BigInt workChain;

  InternalAddress(this.workChain, this.hash);

  bool equals(InternalAddress src) {
    if (workChain != src.workChain) {
      return false;
    }
    return hash.equals(src.hash);
  }

  Uint8List toList({bool? isBounceable, bool? isTestOnly}) {
    var bounceable = isBounceable ?? true;
    var testOnly = isTestOnly ?? false;

    var tag = bounceable ? Address.bounceableTag : Address.nonBounceableTag;
    if (testOnly) {
      tag |= Address.testFlag;
    }

    final addr = Uint8List(34);
    addr[0] = tag;
    addr[1] = workChain.toInt();
    addr.setAll(2, hash);

    final addrWithChecksum = Uint8List(36);
    addrWithChecksum.setAll(0, addr);
    addrWithChecksum.setAll(34, Crc16.ofUint8List(addr));

    return addrWithChecksum;
  }

  Uint8List toRaw() {
    final addrWithChecksum = Uint8List(36);
    addrWithChecksum.setAll(0, hash);
    addrWithChecksum.setAll(32, <int>[
      workChain.toInt(),
      workChain.toInt(),
      workChain.toInt(),
      workChain.toInt(),
    ]);

    return addrWithChecksum;
  }

  String toRawString() {
    return '$workChain:${hex.encode(hash)}';
  }

  @override
  String toString({bool? isUrlSafe, bool? isBounceable, bool? isTestOnly}) {
    var urlSafe = isUrlSafe ?? true;
    var list = toList(isBounceable: isBounceable, isTestOnly: isTestOnly);

    if (urlSafe) {
      return base64
          .encode(list)
          .replaceAll(RegExp(r'\+'), '-')
          .replaceAll(RegExp(r'/'), '_');
    }

    return base64.encode(list);
  }

  /// Returns bool if a String doesn't contain :
  static bool isFriendly(String src) {
    return !src.contains(':');
  }

  /// Returns normalized address as a String, takes String or InternalAddress
  static String normalize(dynamic src) {
    if (src is String) {
      return InternalAddress.parse(src).toString();
    }
    if (src is InternalAddress) {
      return src.toString();
    }
    throw 'Expected String or InternalAddress, got $src';
  }

  /// Returns InternalAddress from a String, takes raw or friendly addresses
  static InternalAddress parse(String src) {
    if (InternalAddress.isFriendly(src)) {
      return parseFriendly(src).address;
    }
    return parseRaw(src);
  }

  /// Returns AddressParams from a friendly address of String or Uint8List
  static AddressParams parseFriendly(dynamic src) {
    if (src is Uint8List) {
      return parseFriendlyAddress(src);
    }

    if (src is String) {
      var addr =
          src.replaceAll(RegExp(r'\-'), '+').replaceAll(RegExp(r'_'), '/');

      return parseFriendlyAddress(base64.decode(addr));
    }

    throw 'Expected String or Uint8List, got $src';
  }

  /// Returns AddressParams from a friendly address of Uint8List
  static AddressParams parseFriendlyAddress(Uint8List src) {
    if (src.length != 36) {
      throw 'Unknown address type: byte length ${src.length} is not equal to 36';
    }

    var addr = src.sublist(0, 34);
    var crc = src.sublist(34, 36);
    var calcedCrc = Crc16.ofUint8List(addr);

    if (!(crc[0] == calcedCrc[0] && crc[1] == calcedCrc[1])) {
      throw 'Invalid crc16 check of $src. Expected $calcedCrc, got $crc';
    }

    var tag = addr[0];
    var isTestOnly = false;
    var isBounceable = false;

    if ((tag & Address.testFlag) != 0) {
      isTestOnly = true;
      tag ^= Address.testFlag;
    }
    if (tag != Address.bounceableTag && tag != Address.nonBounceableTag) {
      throw 'Unknown address tag $tag';
    }

    isBounceable = tag == Address.bounceableTag;

    var workChainInt = 0;
    if (addr[1] == 0xff) {
      workChainInt = -1;
    } else {
      workChainInt = addr[1];
    }

    var hash = addr.sublist(2, 34);

    return AddressParams(
        isBounceable,
        isTestOnly,
        InternalAddress(
          BigInt.from(workChainInt),
          hash,
        ));
  }

  /// Returns InternalAddress from a raw address passed of String
  static InternalAddress parseRaw(String src) {
    var workChain = int.parse(src.split(':')[0]);
    var hash = Uint8List.fromList(hex.decode(src.split(':')[1]));

    return InternalAddress(BigInt.from(workChain), hash);
  }
}
