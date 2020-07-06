/// Copy of Flutter foundation's describeEnum function.
String describeEnum(Object enumEntry) {
  // ignore: omit_local_variable_types
  final String description = enumEntry.toString();
  // ignore: omit_local_variable_types
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}

/// Convert string to Enum entry [E].
///
/// Given "enum E {a, b, c}", "stringToEnum('c', E.values)" returns "E.c".
/*nullable*/ E stringToEnum<E>(String string, List<E> enumEntries,
        {E Function() orElse}) =>
    enumEntries.firstWhere((e) => describeEnum(e) == string, orElse: orElse);
