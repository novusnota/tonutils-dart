/// Enum-like type
class SendMode {
  static const carryAllRemainingBalance = SendMode._(128);
  static const carryAllRemainingIncomingValue = SendMode._(64);
  static const destroyAccountIfZero = SendMode._(32);
  // 16, 8, 4
  static const ignoreErrors = SendMode._(2);
  static const payGasSeparately = SendMode._(1);
  static const none = SendMode._(0);

  final int value;

  const SendMode._(this.value);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SendMode &&
            runtimeType == other.runtimeType &&
            value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

// NOTE: consider using Enhanced Enum Classes
