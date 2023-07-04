import '../../cell/api.dart' show Cell;
import '../../address/api.dart' show InternalAddress;

// String or int or bool

/// String | int | bool [value]
/// Either of: SibString, SibInt, SibBool
sealed class StringIntBool {
  dynamic get value;
}

/// Subtype of StringIntBool union type (sealed class) with String [value]
class SibString extends StringIntBool {
  @override
  String value;

  /// String [value], subtype of StringIntBool
  SibString(this.value);
}

/// Subtype of StringIntBool union type (sealed class) with int [value]
class SibInt extends StringIntBool {
  @override
  int value;

  /// int [value], subtype of StringIntBool
  SibInt(this.value);
}

/// Subtype of StringIntBool union type (sealed class) with bool [value]
class SibBool extends StringIntBool {
  @override
  bool value;

  /// bool [value], subtype of StringIntBool
  SibBool(this.value);
}

// String or BigInt

/// String | BigInt [value]
/// Either of: SbiString, SbiBigInt
sealed class StringBigInt {
  dynamic get value;
}

/// Subtype of StringBigInt union type (sealed class) with String [value]
class SbiString extends StringBigInt {
  @override
  String value;

  /// String [value], subtype of StringBigInt
  SbiString(this.value);
}

/// Subtype of StringBigInt union type (sealed class) with BigInt [value]
class SbiBigInt extends StringBigInt {
  @override
  BigInt value;

  /// BigInt [value], subtype of StringBigInt
  SbiBigInt(this.value);
}

// String or Cell

/// String | Cell [value]
/// Either of: ScString, ScCell
sealed class StringCell {
  dynamic get value;
}

/// Subtype of StringCell union type (sealed class) with String [value]
class ScString extends StringCell {
  @override
  String value;

  /// String [value], subtype of StringCell
  ScString(this.value);
}

/// Subtype of StringCell union type (sealed class) with Cell [value]
class ScCell extends StringCell {
  @override
  Cell value;

  /// Cell [value], subtype of StringCell
  ScCell(this.value);
}

// String or InternalAddress

/// String | InternalAddress [value]
/// Either of: SiaString, SiaInternalAddress
sealed class StringInternalAddress {
  dynamic get value;
}

/// Subtype of StringInternalAddress union type (sealed class) with String [value]
class SiaString extends StringInternalAddress {
  @override
  String value;

  /// String [value], subtype of StringInternalAddress
  SiaString(this.value);
}

/// Subtype of StringInternalAddress union type (sealed class) with InternalAddress [value]
class SiaInternalAddress extends StringInternalAddress {
  @override
  InternalAddress value;

  /// InternalAddress [value], subtype of StringInternalAddress
  SiaInternalAddress(this.value);
}
