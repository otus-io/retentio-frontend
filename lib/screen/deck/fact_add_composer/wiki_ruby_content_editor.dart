import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/card_widgets/card_wiki_ruby_layout.dart';
import 'package:retentio/screen/deck/fact_add_composer/wiki_ruby_wrap_action.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

const _kRubyTapPadding = EdgeInsets.symmetric(horizontal: 1, vertical: 2);
const _kRubyTapRadius = 6.0;
const _kRubyIdleFillAlpha = 0.07;
const _kRubyReadingUnderlineAlpha = 0.45;
const _kPlainFieldMinWidth = 4.0;
const _kContinuationFieldMinWidth = 8.0;

/// Theme input chrome (fill/borders) must be fully cleared — setting only
/// [InputDecoration.border] still leaves enabled/focused borders and fill.
const _kPlainSlotDecoration = InputDecoration(
  isDense: true,
  isCollapsed: true,
  filled: false,
  fillColor: Colors.transparent,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  contentPadding: EdgeInsets.zero,
  hoverColor: Colors.transparent,
);

class _RubyEditSlot {
  _RubyEditSlot.plain({
    required this.controller,
    required this.focus,
    this.isContinuation = false,
  }) : kanji = null;

  _RubyEditSlot.ruby({
    required this.kanji,
    required this.controller,
    required this.focus,
  }) : isContinuation = false;

  final String? kanji;
  final TextEditingController controller;
  final FocusNode focus;
  final bool isContinuation;
  VoidCallback? focusListener;
}

/// Card-style display with tap-to-edit readings. Syncs `[[base|reading]]` into [storage].
class WikiRubyContentEditor extends StatefulWidget {
  const WikiRubyContentEditor({
    super.key,
    required this.storage,
    required this.baseStyle,
    required this.readingHint,
    this.contentPadding = EdgeInsets.zero,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController storage;
  final TextStyle baseStyle;
  final String readingHint;
  final EdgeInsets contentPadding;
  final TextAlign textAlign;

  @override
  State<WikiRubyContentEditor> createState() => _WikiRubyContentEditorState();
}

class _WikiRubyContentEditorState extends State<WikiRubyContentEditor> {
  late List<_RubyEditSlot> _slots;
  bool _syncingStorage = false;
  String _trackedStorage = '';
  int? _editingRubyIndex;

  @override
  void initState() {
    super.initState();
    _trackedStorage = widget.storage.text;
    _slots = _slotsFromStorage(_trackedStorage);
    widget.storage.addListener(_onStorageExternalChange);
    for (final slot in _slots) {
      slot.controller.addListener(_syncToStorage);
      _attachRubyFocus(slot);
    }
    _maybeFocusContinuation();
  }

  @override
  void dispose() {
    widget.storage.removeListener(_onStorageExternalChange);
    for (final slot in _slots) {
      slot.controller.removeListener(_syncToStorage);
      _detachRubyFocus(slot);
      slot.controller.dispose();
      slot.focus.dispose();
    }
    super.dispose();
  }

  void _attachRubyFocus(_RubyEditSlot slot) {
    if (slot.kanji == null) return;
    void listener() {
      if (slot.focus.hasFocus) return;
      if (!mounted) return;
      final index = _slots.indexOf(slot);
      if (index >= 0 && _editingRubyIndex == index) {
        setState(() => _editingRubyIndex = null);
      }
    }

    slot.focusListener = listener;
    slot.focus.addListener(listener);
  }

  void _detachRubyFocus(_RubyEditSlot slot) {
    final listener = slot.focusListener;
    if (listener != null) {
      slot.focus.removeListener(listener);
    }
    slot.focusListener = null;
  }

  void _onStorageExternalChange() {
    if (_syncingStorage || widget.storage.text == _trackedStorage) return;
    _replaceSlots(_slotsFromStorage(widget.storage.text));
  }

  void _replaceSlots(List<_RubyEditSlot> next) {
    for (final slot in _slots) {
      slot.controller.removeListener(_syncToStorage);
      _detachRubyFocus(slot);
      slot.controller.dispose();
      slot.focus.dispose();
    }
    _slots = next;
    _trackedStorage = widget.storage.text;
    _editingRubyIndex = null;
    for (final slot in _slots) {
      slot.controller.addListener(_syncToStorage);
      _attachRubyFocus(slot);
    }
    setState(() {});
    _maybeFocusContinuation();
  }

  void _maybeFocusContinuation() {
    if (_slots.isEmpty) return;
    final last = _slots.last;
    if (!last.isContinuation || last.controller.text.isNotEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      last.focus.requestFocus();
    });
  }

  List<_RubyEditSlot> _slotsFromStorage(String raw) {
    final slots = <_RubyEditSlot>[
      for (final piece in WikiRubyMarkup.decompose(raw))
        if (piece is WikiRubyComposePlain)
          _RubyEditSlot.plain(
            controller: TextEditingController(text: piece.text),
            focus: FocusNode(),
          )
        else if (piece is WikiRubyComposeRuby)
          _RubyEditSlot.ruby(
            kanji: piece.kanji,
            controller: TextEditingController(text: piece.reading),
            focus: FocusNode(),
          ),
    ];
    if (slots.isEmpty || slots.last.kanji != null) {
      slots.add(
        _RubyEditSlot.plain(
          controller: TextEditingController(),
          focus: FocusNode(),
          isContinuation: true,
        ),
      );
    }
    return slots;
  }

  List<WikiRubyComposePiece> _composePieces() {
    return [
      for (final slot in _slots)
        if (slot.kanji == null)
          WikiRubyComposePlain(slot.controller.text)
        else
          WikiRubyComposeRuby(
            kanji: slot.kanji!,
            reading: slot.controller.text,
          ),
    ];
  }

  void _syncToStorage({bool rebuildIfMarkupChanged = false}) {
    final next = WikiRubyMarkup.compose(_composePieces());
    if (next == _trackedStorage) return;
    _syncingStorage = true;
    _trackedStorage = next;
    widget.storage.value = widget.storage.value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
      composing: TextRange.empty,
    );
    _syncingStorage = false;
    if (rebuildIfMarkupChanged) {
      _replaceSlots(_slotsFromStorage(next));
    }
  }

  Future<void> _applyPlainWrap(
    int index,
    String reading, {
    required int start,
    required int end,
  }) async {
    final slot = _slots[index];
    if (slot.kanji != null) return;
    slot.controller.removeListener(_syncToStorage);
    final ok = wikiRubyApplyWrapToController(
      slot.controller,
      reading,
      start: start,
      end: end,
    );
    slot.controller.addListener(_syncToStorage);
    if (!ok) return;
    _syncToStorage(rebuildIfMarkupChanged: true);
  }

  void _startEditingRuby(int index) {
    setState(() => _editingRubyIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _slots[index].focus.requestFocus();
    });
  }

  void _focusNextRuby(int fromIndex) {
    for (var i = fromIndex + 1; i < _slots.length; i++) {
      if (_slots[i].kanji != null) {
        _startEditingRuby(i);
        return;
      }
    }
    setState(() => _editingRubyIndex = null);
    _slots[fromIndex].focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final rubyStyle = wikiRubyReadingStyle(widget.baseStyle);
    final scheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final wrapAlignment = switch (widget.textAlign) {
      TextAlign.start || TextAlign.left => WrapAlignment.start,
      TextAlign.end || TextAlign.right => WrapAlignment.end,
      _ => WrapAlignment.center,
    };

    return Padding(
      padding: widget.contentPadding,
      child: FocusTraversalGroup(
        child: Wrap(
          alignment: wrapAlignment,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 0,
          runSpacing: 6,
          children: [
            for (var i = 0; i < _slots.length; i++)
              _buildSlot(context, i, rubyStyle, scheme, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(
    BuildContext context,
    int index,
    TextStyle rubyStyle,
    ColorScheme scheme,
    AppLocalizations loc,
  ) {
    final slot = _slots[index];
    if (slot.kanji == null) {
      // Same outer shell + reading/base column as ruby cells so WrapCrossAlignment.end
      // aligns kanji baselines (not the Material box edge).
      final baseStyle = widget.baseStyle.copyWith(
        color: scheme.onSurface,
        height: 1.0,
      );
      final baseH = _lineHeight(baseStyle);
      final readingH = _lineHeight(rubyStyle);
      return _slotShell(
        scheme: scheme,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(height: readingH),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: slot.isContinuation
                        ? _kContinuationFieldMinWidth
                        : _kPlainFieldMinWidth,
                  ),
                  child: SizedBox(
                    height: baseH,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: TextField(
                        controller: slot.controller,
                        focusNode: slot.focus,
                        style: baseStyle,
                        strutStyle: StrutStyle.fromTextStyle(
                          baseStyle,
                          forceStrutHeight: true,
                        ),
                        cursorHeight: baseStyle.fontSize,
                        textAlignVertical: TextAlignVertical.bottom,
                        maxLines: 1,
                        scrollPadding: EdgeInsets.zero,
                        decoration: _kPlainSlotDecoration,
                        contextMenuBuilder: (context, editableTextState) {
                          return wikiRubySelectionToolbar(
                            context: context,
                            editableTextState: editableTextState,
                            loc: loc,
                            readingHint: widget.readingHint,
                            onReadingChosen:
                                (reading, {required start, required end}) =>
                                    _applyPlainWrap(
                                      index,
                                      reading,
                                      start: start,
                                      end: end,
                                    ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final kanji = slot.kanji!;
    final reading = slot.controller.text;
    final editing = _editingRubyIndex == index;
    final isLastRuby = !_hasRubyAfter(index);
    final textInputAction = isLastRuby
        ? TextInputAction.done
        : TextInputAction.next;

    if (!editing) {
      return _slotShell(
        scheme: scheme,
        onTap: () => _startEditingRuby(index),
        highlighted: false,
        child: wikiRubyCellWidget(
          kanji: kanji,
          reading: reading,
          baseStyle: widget.baseStyle.copyWith(
            color: scheme.onSurface,
            height: 1.0,
          ),
          rubyStyle: rubyStyle.copyWith(
            color: scheme.onSurface,
            decoration: TextDecoration.underline,
            decorationColor: scheme.primary.withValues(
              alpha: _kRubyReadingUnderlineAlpha,
            ),
            decorationStyle: TextDecorationStyle.dotted,
          ),
        ),
      );
    }

    return FocusTraversalOrder(
      order: NumericFocusOrder(index.toDouble()),
      child: _slotShell(
        scheme: scheme,
        highlighted: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: slot.controller,
                  focusNode: slot.focus,
                  style: rubyStyle.copyWith(color: scheme.primary),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.readingHint,
                    hintStyle: rubyStyle.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: scheme.primary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: scheme.primary, width: 2),
                    ),
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                    fillColor: Colors.transparent,
                  ),
                  textInputAction: textInputAction,
                  onSubmitted: (_) => _focusNextRuby(index),
                ),
              ),
              Text(
                kanji,
                style: widget.baseStyle.copyWith(
                  color: scheme.onSurface,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared chrome for ruby + plain slots so box padding does not shift baselines.
  Widget _slotShell({
    required ColorScheme scheme,
    required Widget child,
    VoidCallback? onTap,
    bool highlighted = false,
  }) {
    final fill = onTap != null || highlighted
        ? scheme.primary.withValues(
            alpha: highlighted ? _kRubyIdleFillAlpha * 2 : _kRubyIdleFillAlpha,
          )
        : Colors.transparent;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(_kRubyTapRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kRubyTapRadius),
        child: Padding(padding: _kRubyTapPadding, child: child),
      ),
    );
  }

  bool _hasRubyAfter(int index) {
    for (var i = index + 1; i < _slots.length; i++) {
      if (_slots[i].kanji != null) return true;
    }
    return false;
  }

  double _lineHeight(TextStyle style) {
    final fontSize = style.fontSize ?? 16;
    return fontSize * (style.height ?? 1.0);
  }
}

/// Whether [text] should use the ruby reading editor instead of a plain field.
bool wikiRubyContentUsesReadingEditor(String text) =>
    WikiRubyMarkup.looksLikeMarkup(text);
