import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Class for setting shortcut actions.
///
/// Defaults to [PlutoGridShortcut.defaultActions] if not passing [actions].
class PlutoGridShortcut {
  const PlutoGridShortcut({
    Map<ShortcutActivator, PlutoGridShortcutAction>? actions,
  }) : _actions = actions;

  /// Custom shortcuts and actions.
  ///
  /// When the shortcut set in [ShortcutActivator] is input,
  /// the [PlutoGridShortcutAction.execute] method is executed.
  Map<ShortcutActivator, PlutoGridShortcutAction> get actions =>
      _actions ?? defaultActions;

  final Map<ShortcutActivator, PlutoGridShortcutAction>? _actions;

  /// If the shortcut registered in [actions] matches,
  /// the action for the shortcut is executed.
  ///
  /// If there is no matching shortcut and returns false ,
  /// the default shortcut behavior is processed.
  bool handle({
    required PlutoKeyManagerEvent keyEvent,
    required PlutoGridStateManager stateManager,
    required HardwareKeyboard state,
  }) {
    for (final action in actions.entries) {
      if (action.key.accepts(keyEvent.event, state)) {
        action.value.execute(keyEvent: keyEvent, stateManager: stateManager);
        return true;
      }
    }

    return false;
  }

  static final Map<ShortcutActivator, PlutoGridShortcutAction>
  defaultActions = {
    // Move cell focus
    LogicalKeySet(LogicalKeyboardKey.arrowLeft):
        const PlutoGridActionMoveCellFocus(PlutoMoveDirection.left),
    LogicalKeySet(LogicalKeyboardKey.arrowRight):
        const PlutoGridActionMoveCellFocus(PlutoMoveDirection.right),
    LogicalKeySet(LogicalKeyboardKey.arrowUp):
        const PlutoGridActionMoveCellFocus(PlutoMoveDirection.up),
    LogicalKeySet(LogicalKeyboardKey.arrowDown):
        const PlutoGridActionMoveCellFocus(PlutoMoveDirection.down),
    // Move selected cell focus
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.left),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.right),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowUp):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.up),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowDown):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.down),

    LogicalKeySet(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.arrowLeft):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.left),
    LogicalKeySet(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.arrowRight):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.right),
    LogicalKeySet(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.arrowUp):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.up),
    LogicalKeySet(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.arrowDown):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.down),

    LogicalKeySet(LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.arrowLeft):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.left),
    LogicalKeySet(LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.arrowRight):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.right),
    LogicalKeySet(LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.arrowUp):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.up),
    LogicalKeySet(LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.arrowDown):
        const PlutoGridActionMoveSelectedCellFocus(PlutoMoveDirection.down),

    // Move cell focus by page vertically
    LogicalKeySet(LogicalKeyboardKey.pageUp):
        const PlutoGridActionMoveCellFocusByPage(PlutoMoveDirection.up),
    LogicalKeySet(LogicalKeyboardKey.pageDown):
        const PlutoGridActionMoveCellFocusByPage(PlutoMoveDirection.down),
    // Move cell focus by page vertically
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.pageUp):
        const PlutoGridActionMoveSelectedCellFocusByPage(PlutoMoveDirection.up),
    LogicalKeySet(
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.pageDown,
    ): const PlutoGridActionMoveSelectedCellFocusByPage(
      PlutoMoveDirection.down,
    ),

    LogicalKeySet(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.pageUp):
        const PlutoGridActionMoveSelectedCellFocusByPage(PlutoMoveDirection.up),
    LogicalKeySet(
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.pageDown,
    ): const PlutoGridActionMoveSelectedCellFocusByPage(
      PlutoMoveDirection.down,
    ),
    // Move page when pagination is enabled
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.pageUp):
        const PlutoGridActionMoveCellFocusByPage(PlutoMoveDirection.left),
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.pageDown):
        const PlutoGridActionMoveCellFocusByPage(PlutoMoveDirection.right),
    // Default tab key action
    LogicalKeySet(LogicalKeyboardKey.tab): const PlutoGridActionDefaultTab(),

    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
        const PlutoGridActionDefaultTab(),
    LogicalKeySet(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.tab):
        const PlutoGridActionDefaultTab(),
    LogicalKeySet(LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.tab):
        const PlutoGridActionDefaultTab(),
    // Default enter key action
    LogicalKeySet(LogicalKeyboardKey.enter):
        const PlutoGridActionDefaultEnterKey(),
    LogicalKeySet(LogicalKeyboardKey.numpadEnter):
        const PlutoGridActionDefaultEnterKey(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
        const PlutoGridActionDefaultEnterKey(),
    LogicalKeySet(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.enter):
        const PlutoGridActionDefaultEnterKey(),
    LogicalKeySet(LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.enter):
        const PlutoGridActionDefaultEnterKey(),
    // Default escape key action
    LogicalKeySet(LogicalKeyboardKey.escape):
        const PlutoGridActionDefaultEscapeKey(),
    // Move cell focus to edge
    LogicalKeySet(LogicalKeyboardKey.home):
        const PlutoGridActionMoveCellFocusToEdge(PlutoMoveDirection.left),
    LogicalKeySet(LogicalKeyboardKey.end):
        const PlutoGridActionMoveCellFocusToEdge(PlutoMoveDirection.right),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.home):
        const PlutoGridActionMoveCellFocusToEdge(PlutoMoveDirection.up),
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.end):
        const PlutoGridActionMoveCellFocusToEdge(PlutoMoveDirection.down),

    LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.home):
        const PlutoGridActionMoveCellFocusToEdge(PlutoMoveDirection.up),
    LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.end):
        const PlutoGridActionMoveCellFocusToEdge(PlutoMoveDirection.down),

    LogicalKeySet(LogicalKeyboardKey.controlRight, LogicalKeyboardKey.home):
        const PlutoGridActionMoveCellFocusToEdge(PlutoMoveDirection.up),
    LogicalKeySet(LogicalKeyboardKey.controlRight, LogicalKeyboardKey.end):
        const PlutoGridActionMoveCellFocusToEdge(PlutoMoveDirection.down),
    // Move selected cell focus to edge
    LogicalKeySet(
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.left,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.right,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.left,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.right,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.left,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.right,
    ),

    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),

    LogicalKeySet(
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),

    LogicalKeySet(
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.home,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.up,
    ),

    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),

    LogicalKeySet(
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),

    LogicalKeySet(
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),
    LogicalKeySet(
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.end,
    ): const PlutoGridActionMoveSelectedCellFocusToEdge(
      PlutoMoveDirection.down,
    ),
    // Set editing
    LogicalKeySet(LogicalKeyboardKey.f2): const PlutoGridActionSetEditing(),
    // Focus to column filter
    LogicalKeySet(LogicalKeyboardKey.f3):
        const PlutoGridActionFocusToColumnFilter(),
    // Toggle column sort
    LogicalKeySet(LogicalKeyboardKey.f4):
        const PlutoGridActionToggleColumnSort(),

    // Paste values from clipboard
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),
    LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),
    LogicalKeySet(LogicalKeyboardKey.controlRight, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),

    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),
    LogicalKeySet(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),
    LogicalKeySet(LogicalKeyboardKey.altRight, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),

    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),
    LogicalKeySet(LogicalKeyboardKey.metaRight, LogicalKeyboardKey.keyV):
        const PlutoGridActionPasteValues(),
  };

  static final Map<ShortcutActivator, PlutoGridShortcutAction>
  exportAvailableActions = {
    // Copy the values of cells
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),
    LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),
    LogicalKeySet(LogicalKeyboardKey.controlRight, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),

    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),
    LogicalKeySet(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),
    LogicalKeySet(LogicalKeyboardKey.altRight, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),

    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),
    LogicalKeySet(LogicalKeyboardKey.metaRight, LogicalKeyboardKey.keyC):
        const PlutoGridActionCopyValues(),
    // Select all cells or rows
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),
    LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),
    LogicalKeySet(LogicalKeyboardKey.controlRight, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),

    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),
    LogicalKeySet(LogicalKeyboardKey.altLeft, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),
    LogicalKeySet(LogicalKeyboardKey.altRight, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),

    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),
    LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),
    LogicalKeySet(LogicalKeyboardKey.metaRight, LogicalKeyboardKey.keyA):
        const PlutoGridActionSelectAll(),
  };
}
