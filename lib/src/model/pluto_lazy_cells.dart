import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Cells of a [PlutoRow] that are created the first time they are read.
///
/// A grid with many rows renders, sorts and filters only some of its cells,
/// yet a cell for every column of every row costs 64 bytes. The grid does not
/// link every cell of such rows to its column and row: it [bind]s the cells
/// once, and each cell created after that gets its column and row when it is
/// created.
///
/// Reading a cell through the map creates it; so do [values], [entries] and
/// [forEach], which read every cell. [createdCells] reads only the cells
/// created so far. A created cell is kept, so a cell keeps its key, value
/// changes and callbacks.
abstract interface class PlutoLazyCells implements Map<String, PlutoCell> {
  /// Whether [bind] gave the cells a row, as [PlutoRow.initialized] asks.
  bool get bound;

  /// Links the created cells, and the cells created later, to [row] and to the
  /// column of their field in [columns], as the grid links the cells of other
  /// rows. Cells of fields without a column stay unlinked.
  void bind(PlutoRow row, Map<String, PlutoColumn> columns);

  /// Forgets the row and columns and clears the created cells, as
  /// [PlutoRow.clear] clears the cells of other rows.
  void unbind();

  /// The cells created so far, without creating others.
  Iterable<PlutoCell> get createdCells;
}
