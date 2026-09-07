import 'package:flutter/material.dart';

abstract class PlutoGridSettings {
  /// Soft shared budget for all incremental footer calculations in one frame.
  /// A single user-supplied callback cannot be interrupted.
  static const Duration calculationFrameBudget = Duration(milliseconds: 2);
  static const int calculationBatchSize = 64;
  static const int calculationMaxStepsPerFrame = 16384;

  /// If there is a frozen column, the minimum width of the body
  /// (if it is less than the value, the frozen column is released)
  static const double bodyMinWidth = 200.0;

  /// Default column width
  static const double columnWidth = 200.0;

  /// Column width
  static const double minColumnWidth = 80.0;

  /// Frozen column division line (ShadowLine) size
  static const double shadowLineSize = 3.0;

  /// Sum of frozen column division line width
  static const double totalShadowLineWidth =
      PlutoGridSettings.shadowLineSize * 2;

  /// Grid - padding
  static const double gridPadding = 2.0;

  /// Grid - border width
  static const double gridBorderWidth = 1.0;

  /// Column divider width
  static const double columnBorderWidth = 1.0;

  /// Invisible pointer target centered on a resizable column boundary.
  ///
  /// It intentionally remains wider than [columnBorderWidth], so thin dividers
  /// are still easy to acquire with a mouse or trackpad.
  static const double columnResizeHandleWidth = 12.0;

  /// Visible divider width while a column boundary is hovered or dragged.
  static const double columnResizeHandleActiveWidth = 3.0;

  /// Default duration of the active resize divider width transition.
  static const Duration columnResizeIndicatorAnimationDuration = Duration(
    milliseconds: 200,
  );

  /// Default hover dwell time before the resize cursor is shown.
  static const Duration columnResizeCursorDelay = Duration(milliseconds: 100);

  /// Default hover dwell time before the active resize divider is shown.
  ///
  /// Dragging bypasses this delay.
  static const Duration columnResizeIndicatorHoverDelay = Duration(
    milliseconds: 180,
  );

  static const double gridInnerSpacing =
      (gridPadding * 2) + (gridBorderWidth * 2);

  /// Row - Default row height
  static const double rowHeight = 45.0;

  /// Row - border width
  static const double rowBorderWidth = 1.0;

  /// Row - total height
  static const double rowTotalHeight = rowHeight + rowBorderWidth;

  /// Cell - padding
  static const EdgeInsets cellPadding = EdgeInsets.symmetric(horizontal: 10);

  /// Column title - padding
  static const EdgeInsets columnTitlePadding = EdgeInsets.symmetric(
    horizontal: 10,
  );

  static const EdgeInsets columnFilterPadding = EdgeInsets.all(5);

  /// Cell - fontSize
  static const double cellFontSize = 14;

  /// Scroll when multi-selection is as close as that value from the edge
  static const double offsetScrollingFromEdge = 10.0;

  /// Size that scrolls from the edge at once when selecting multiple
  static const double offsetScrollingFromEdgeAtOnce = 200.0;

  static const int debounceMillisecondsForColumnFilter = 300;
}
