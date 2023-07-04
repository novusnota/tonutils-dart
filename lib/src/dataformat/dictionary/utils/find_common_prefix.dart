/// Returns the longest common prefix of a List of Strings as a String
String findCommonPrefix(List<String> src) {
  if (src.isEmpty) {
    return '';
  }
  if (src.length == 1) {
    return src[0];
  }
  final sorted = List.of(src);
  sorted.sort();
  var size = 0;
  for (var i = 0; i < sorted[0].length; i += 1) {
    if (sorted[0][i] != sorted[sorted.length - 1][i]) {
      break;
    }
    size += 1;
  }
  return src[0].substring(0, size);
}
