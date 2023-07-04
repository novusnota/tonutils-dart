import 'package:convert/convert.dart';

import '../api.dart' show Cell;

/// Returns a List of objects, where each object has two properties: Cell cell and List<int> refs
List<({Cell cell, List<int> refs})> topologicalSort(Cell src) {
  var pending = <Cell>[src];
  var allCells = <String, ({Cell cell, List<String> refs})>{};
  var notPermCells = <String>{};
  var sorted = <String>[];

  while (pending.isNotEmpty) {
    final cells = List.of(pending);
    pending = <Cell>[];
    for (var i = 0; i < cells.length; i += 1) {
      final hash = hex.encode(cells[i].hash());
      if (allCells.containsKey(hash)) {
        continue;
      }
      notPermCells.add(hash);
      allCells[hash] = (
        cell: cells[i],
        refs: cells[i].refs.map((e) => hex.encode(e.hash())).toList(),
      );
      for (var j = 0; j < cells[i].refs.length; j += 1) {
        pending.add(cells[i].refs[j]);
      }
    }
  }

  var tempMark = <String>{};
  void visit(String hash) {
    if (notPermCells.contains(hash) == false) {
      return;
    }
    if (tempMark.contains(hash)) {
      throw 'Not a DAG!';
    }
    tempMark.add(hash);
    var refs = allCells[hash]!.refs;
    for (var i = 0; i < refs.length; i += 1) {
      visit(refs[i]);
    }
    sorted.insert(0, hash);
    tempMark.remove(hash);
    notPermCells.remove(hash);
  }

  while (notPermCells.isNotEmpty) {
    final id = List.of(notPermCells)[0];
    visit(id);
  }

  var indexes = <String, int>{};
  for (var i = 0; i < sorted.length; i += 1) {
    indexes[sorted[i]] = i;
  }

  var result = <({Cell cell, List<int> refs})>[];
  for (var i = 0; i < sorted.length; i += 1) {
    final r = allCells[sorted[i]]!;
    result.add(
      (cell: r.cell, refs: r.refs.map((e) => indexes[e]!).toList()),
    );
  }

  return result;
}
