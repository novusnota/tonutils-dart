import '../type/api.dart' show StringIntBool;

/// ({String message})
class ABIError {
  String message;

  ABIError({required this.message});
}

// <ABITypeRef>

/// Either a ABITrSimple or ABITrDict
sealed class ABITypeRef {}

/// ({String type, bool? optional, StringIntBool? format})
class ABITrSimple extends ABITypeRef {
  String type;
  bool? optional;
  StringIntBool? format;

  ABITrSimple({
    required this.type,
    this.optional,
    this.format,
  });
}

/// ({String key, String value, StringIntBool? format, StringIntBool? keyFormat, StringIntBool? valueFormat})
class ABITrDict extends ABITypeRef {
  StringIntBool? format;

  String key;
  StringIntBool? keyFormat;

  String value;
  StringIntBool? valueFormat;

  ABITrDict({
    required this.key,
    required this.value,
    this.format,
    this.keyFormat,
    this.valueFormat,
  });
}

// </ABITypeRef>

class ABIField {
  String name;
  ABITypeRef type;

  ABIField({
    required this.name,
    required this.type,
  });
}

class ABIType {
  String name;
  int? header;
  List<ABIField> fields;

  ABIType({
    required this.name,
    required this.fields,
    this.header,
  });
}

class ABIArgument {
  String name;
  ABITypeRef type;

  ABIArgument({
    required this.name,
    required this.type,
  });
} // NOTE copies ABIField, consider uniting into one?

class ABIGetter {
  String name;
  int? methodId;
  List<ABIArgument>? arguments;
  ABITypeRef? returnType;

  ABIGetter({
    required this.name,
    this.methodId,
    this.arguments,
    this.returnType,
  });
}

// <ABIReceiverMessage>

/// Either of: ABIRmTyped, ABIRmAny, ABIRmEmpty or ABIRmText
sealed class ABIReceiverMessage {}

class ABIRmTyped extends ABIReceiverMessage {
  String type;

  ABIRmTyped({
    required this.type,
  });
}

class ABIRmAny extends ABIReceiverMessage {}

class ABIRmEmpty extends ABIReceiverMessage {}

class ABIRmText extends ABIReceiverMessage {
  String? text;

  ABIRmText({
    this.text,
  });
}

// </ABIReceiverMessage>

// <ABIReceiver>

/// Either a ABIRInternal or ABIRExternal
sealed class ABIReceiver {}

/// ({ABIReceiverMessage message})
class ABIRInternal extends ABIReceiver {
  ABIReceiverMessage message;

  ABIRInternal({required this.message});
}

/// ({ABIReceiverMessage message})
class ABIRExternal extends ABIReceiver {
  ABIReceiverMessage message;

  ABIRExternal({required this.message});
}

// </ABIReceiver>

/// ({String? name, List<ABIType>? types, Map<int, ABIError>? errors, List<ABIGetter>? getters, LIST<ABIReceiver>? receivers})
class ContractABI {
  String? name;
  List<ABIType>? types;
  Map<int, ABIError>? errors;
  List<ABIGetter>? getters;
  List<ABIReceiver>? receivers;

  ContractABI({
    this.name,
    this.types,
    this.errors,
    this.getters,
    this.receivers,
  });
}
