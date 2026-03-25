import 'package:flutter/widgets.dart';

/// True when [focusContext] is a descendant of the subtree rooted at [hostContext].
bool addFactFocusContextWithinHost(
  BuildContext focusContext,
  BuildContext hostContext,
) {
  final Element host = hostContext as Element;
  var found = false;
  focusContext.visitAncestorElements((ancestor) {
    if (ancestor == host) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/// Row index whose host contains the focus, or `null` if focus is not inside any host.
int? addFactFocusedHostRowIndex({
  required BuildContext? focusContext,
  required List<GlobalKey> hostKeys,
}) {
  if (focusContext == null) return null;
  for (var i = 0; i < hostKeys.length; i++) {
    final hostCtx = hostKeys[i].currentContext;
    if (hostCtx != null &&
        addFactFocusContextWithinHost(focusContext, hostCtx)) {
      return i;
    }
  }
  return null;
}

/// Media attaches to the focused row, or row 0 when focus is outside all rows.
int addFactTargetRowIndexForMedia({
  required BuildContext? focusContext,
  required List<GlobalKey> hostKeys,
}) {
  return addFactFocusedHostRowIndex(
        focusContext: focusContext,
        hostKeys: hostKeys,
      ) ??
      0;
}

/// Which row [−] removes: focused row if focus is inside a host, else last row.
/// Returns `null` when removal is not allowed (≤1 row).
int? addFactIndexToRemoveOnMinus({
  required int rowCount,
  required BuildContext? focusContext,
  required List<GlobalKey> hostKeys,
}) {
  if (rowCount <= 1) return null;
  return addFactFocusedHostRowIndex(
        focusContext: focusContext,
        hostKeys: hostKeys,
      ) ??
      rowCount - 1;
}
