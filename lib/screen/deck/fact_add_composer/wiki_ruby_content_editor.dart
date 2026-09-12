import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Reading scale when the reading field is focused (idle ~0.55×).
@visibleForTesting
const kWikiRubyFocusedReadingScale = 1.0;

/// Base scale when the reading field is focused (idle = 1.0).
@visibleForTesting
const kWikiRubyShrunkBaseScale = 0.55;

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
  }) : kanjiController = null,
       kanjiFocus = null;

  _RubyEditSlot.ruby({
    required this.kanjiController,
    required this.controller,
    required this.focus,
    required this.kanjiFocus,
  }) : isContinuation = false;

  final TextEditingController? kanjiController;
  final TextEditingController controller;
  final FocusNode focus;
  final FocusNode? kanjiFocus;
  final bool isContinuation;

  bool get isRuby => kanjiController != null;
}

/// Card-style display with always-editable readings. Syncs `[[base|reading]]`
/// (or pending `[[base|]]`) into [storage].
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
  bool _mutatingSlots = false;
  String _trackedStorage = '';

  @override
  void initState() {
    super.initState();
    _trackedStorage = widget.storage.text;
    _slots = _slotsFromStorage(_trackedStorage);
    widget.storage.addListener(_onStorageExternalChange);
    for (final slot in _slots) {
      _attachSlotListeners(slot);
    }
    _maybeFocusAfterRebuild();
  }

  @override
  void dispose() {
    _mutatingSlots = true;
    widget.storage.removeListener(_onStorageExternalChange);
    for (final slot in _slots) {
      slot.controller.removeListener(_syncToStorage);
      slot.kanjiController?.removeListener(_syncToStorage);
      slot.controller.dispose();
      slot.kanjiController?.dispose();
      slot.focus.dispose();
      slot.kanjiFocus?.dispose();
    }
    super.dispose();
  }

  void _onStorageExternalChange() {
    if (_syncingStorage || widget.storage.text == _trackedStorage) return;
    _replaceSlots(_slotsFromStorage(widget.storage.text));
  }

  void _replaceSlots(
    List<_RubyEditSlot> next, {
    bool skipContinuationFocus = false,
  }) {
    _mutatingSlots = true;
    for (final slot in _slots) {
      slot.controller.removeListener(_syncToStorage);
      slot.kanjiController?.removeListener(_syncToStorage);
      slot.controller.dispose();
      slot.kanjiController?.dispose();
      slot.focus.dispose();
      slot.kanjiFocus?.dispose();
    }
    _slots = next;
    _trackedStorage = widget.storage.text;
    for (final slot in _slots) {
      _attachSlotListeners(slot);
    }
    _mutatingSlots = false;
    setState(() {});
    if (!skipContinuationFocus) {
      _maybeFocusAfterRebuild();
    }
  }

  void _maybeFocusAfterRebuild() {
    for (final slot in _slots) {
      if (slot.isRuby && slot.controller.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          slot.focus.requestFocus();
        });
        return;
      }
    }
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

  bool _rubyNeedsDissolve(_RubyEditSlot slot) {
    if (!slot.isRuby) return false;
    // Both empty → drop. Empty base alone stays until a second backspace.
    return slot.kanjiController!.text.isEmpty && slot.controller.text.isEmpty;
  }

  void _attachSlotListeners(_RubyEditSlot slot) {
    slot.controller.addListener(_syncToStorage);
    slot.kanjiController?.addListener(_syncToStorage);
    if (slot.isRuby) {
      slot.focus.addListener(() => _onRubySlotFocusChange(slot));
      slot.kanjiFocus!.addListener(() => _onRubySlotFocusChange(slot));
    }
  }

  void _onRubySlotFocusChange(_RubyEditSlot slot) {
    if (!mounted || _mutatingSlots) return;
    // Rebuild so the focused ruby reading can enlarge for editing.
    setState(() {});
    if (_syncingStorage) return;
    if (slot.focus.hasFocus || !slot.isRuby) return;
    if (!_slots.contains(slot)) return;
    if (slot.controller.text.isNotEmpty) return;
    if (slot.kanjiController!.text.isEmpty) return;
    _dissolveEmptyReadingToPlain(slot);
  }

  /// Empty reading on blur → keep base as plain text.
  void _dissolveEmptyReadingToPlain(_RubyEditSlot slot) {
    final index = _slots.indexOf(slot);
    if (index < 0) return;
    final caret =
        _composedOffsetBeforeSlot(index) + slot.kanjiController!.text.length;
    final pieces = <WikiRubyComposePiece>[
      for (var i = 0; i < _slots.length; i++)
        if (!_slots[i].isRuby)
          WikiRubyComposePlain(_slots[i].controller.text)
        else if (identical(_slots[i], slot))
          WikiRubyComposePlain(_slots[i].kanjiController!.text)
        else
          WikiRubyComposeRuby(
            kanji: _slots[i].kanjiController!.text,
            reading: _slots[i].controller.text,
          ),
    ];
    final next = WikiRubyMarkup.compose(pieces);
    if (next == _trackedStorage) return;
    _writeStorage(next, caret: caret.clamp(0, next.length));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _replaceSlots(_slotsFromStorage(next), skipContinuationFocus: true);
      _restoreFocusAt(composedOffset: caret.clamp(0, next.length));
    });
  }

  /// Second backspace on an empty base removes the ruby cell (reading too).
  void _removeRubySlot(int index) {
    if (index < 0 || index >= _slots.length) return;
    final slot = _slots[index];
    if (!slot.isRuby) return;
    final caret = _composedOffsetBeforeSlot(index);
    final pieces = <WikiRubyComposePiece>[
      for (var i = 0; i < _slots.length; i++)
        if (i != index)
          if (!_slots[i].isRuby)
            WikiRubyComposePlain(_slots[i].controller.text)
          else
            WikiRubyComposeRuby(
              kanji: _slots[i].kanjiController!.text,
              reading: _slots[i].controller.text,
            ),
    ];
    final next = WikiRubyMarkup.compose(pieces);
    _writeStorage(next, caret: caret.clamp(0, next.length));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _replaceSlots(_slotsFromStorage(next), skipContinuationFocus: true);
      _restoreFocusAt(composedOffset: caret.clamp(0, next.length));
    });
  }

  void _writeStorage(String next, {required int caret}) {
    _syncingStorage = true;
    _trackedStorage = next;
    widget.storage.value = widget.storage.value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: caret.clamp(0, next.length)),
      composing: TextRange.empty,
    );
    _syncingStorage = false;
  }

  /// Composed-string offset at the start of [index] (kanji/plain lengths only).
  int _composedOffsetBeforeSlot(int index) {
    var offset = 0;
    for (var i = 0; i < index && i < _slots.length; i++) {
      final slot = _slots[i];
      if (slot.isRuby) {
        offset += slot.kanjiController!.text.length;
      } else {
        offset += slot.controller.text.length;
      }
    }
    return offset;
  }

  /// Caret in composed text for the currently focused slot field.
  int? _composedCaretOffset() {
    var offset = 0;
    for (final slot in _slots) {
      if (!slot.isRuby) {
        if (slot.focus.hasFocus) {
          final sel = slot.controller.selection;
          final local = sel.isValid
              ? sel.baseOffset.clamp(0, slot.controller.text.length)
              : slot.controller.text.length;
          return offset + local;
        }
        offset += slot.controller.text.length;
        continue;
      }
      if (slot.focus.hasFocus) {
        // Reading is not part of composed text — place caret at start of base.
        return offset;
      }
      if (slot.kanjiFocus?.hasFocus == true) {
        final kanji = slot.kanjiController!;
        final sel = kanji.selection;
        final local = sel.isValid
            ? sel.baseOffset.clamp(0, kanji.text.length)
            : kanji.text.length;
        return offset + local;
      }
      offset += slot.kanjiController!.text.length;
    }
    return null;
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
            kanjiController: TextEditingController(text: piece.kanji),
            controller: TextEditingController(text: piece.reading),
            focus: FocusNode(),
            kanjiFocus: FocusNode(),
          ),
    ];
    if (slots.isEmpty || slots.last.isRuby) {
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
        if (!slot.isRuby)
          WikiRubyComposePlain(slot.controller.text)
        else
          WikiRubyComposeRuby(
            kanji: slot.kanjiController!.text,
            reading: slot.controller.text,
          ),
    ];
  }

  void _syncToStorage({bool rebuildIfMarkupChanged = false}) {
    final needsDissolve = _slots.any(_rubyNeedsDissolve);
    final next = WikiRubyMarkup.compose(_composePieces());
    if (next == _trackedStorage && !needsDissolve && !rebuildIfMarkupChanged) {
      return;
    }
    final caret = _composedCaretOffset() ?? next.length;
    _writeStorage(next, caret: caret);
    if (rebuildIfMarkupChanged || needsDissolve) {
      final focusIndex = _focusedSlotIndex();
      final preferEmptyReading = rebuildIfMarkupChanged && !needsDissolve;
      // Rebuild after the frame that triggered this sync — disposing slot
      // controllers inside their own listener throws.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _replaceSlots(
          _slotsFromStorage(_trackedStorage),
          skipContinuationFocus: focusIndex != null,
        );
        if (focusIndex != null) {
          _restoreFocusAt(
            slotIndex: focusIndex,
            composedOffset: caret,
            preferEmptyReading: preferEmptyReading,
          );
        }
      });
    }
  }

  int? _focusedSlotIndex() {
    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      if (slot.focus.hasFocus || slot.kanjiFocus?.hasFocus == true) {
        return i;
      }
    }
    return null;
  }

  /// Restores caret immediately (caller is already in a post-frame callback).
  void _restoreFocusAt({
    int? slotIndex,
    int? composedOffset,
    bool preferEmptyReading = false,
  }) {
    if (!mounted || _slots.isEmpty) return;
    if (preferEmptyReading) {
      for (final slot in _slots) {
        if (slot.isRuby && slot.controller.text.isEmpty) {
          slot.focus.requestFocus();
          return;
        }
      }
    }
    if (composedOffset != null) {
      _focusComposedOffset(composedOffset);
      return;
    }
    final index = (slotIndex ?? 0).clamp(0, _slots.length - 1);
    final slot = _slots[index];
    if (slot.isRuby) {
      slot.kanjiFocus!.requestFocus();
      final text = slot.kanjiController!.text;
      slot.kanjiController!.selection = TextSelection.collapsed(
        offset: text.length,
      );
      return;
    }
    slot.focus.requestFocus();
    final text = slot.controller.text;
    slot.controller.selection = TextSelection.collapsed(offset: text.length);
  }

  void _focusComposedOffset(int composedOffset) {
    var offset = 0;
    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      final len = slot.isRuby
          ? slot.kanjiController!.text.length
          : slot.controller.text.length;
      final isLast = i == _slots.length - 1;
      final atEmptyRuby = len == 0 && composedOffset == offset && slot.isRuby;
      if (composedOffset < offset + len || atEmptyRuby || isLast) {
        final local = (composedOffset - offset).clamp(0, len);
        if (slot.isRuby) {
          slot.kanjiFocus!.requestFocus();
          slot.kanjiController!.selection = TextSelection.collapsed(
            offset: local,
          );
        } else {
          slot.focus.requestFocus();
          slot.controller.selection = TextSelection.collapsed(offset: local);
        }
        return;
      }
      offset += len;
    }
  }

  bool _isCaretAtStart(TextEditingController controller) {
    final selection = controller.selection;
    return selection.isValid &&
        selection.isCollapsed &&
        selection.baseOffset == 0;
  }

  /// Backspace at caret start deletes into the previous slot (kanji or plain).
  void _deleteIntoPreviousSlot(int index) {
    if (index <= 0) {
      final slot = _slots[index];
      if (slot.isRuby && slot.kanjiController!.text.isEmpty) {
        _removeRubySlot(index);
      }
      return;
    }

    final prev = _slots[index - 1];
    if (prev.isRuby) {
      final kanji = prev.kanjiController!;
      if (kanji.text.isNotEmpty) {
        final nextText = kanji.text.substring(0, kanji.text.length - 1);
        kanji.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
        prev.kanjiFocus?.requestFocus();
      } else {
        // Empty base already — second backspace removes the ruby.
        _removeRubySlot(index - 1);
      }
      return;
    }

    final plain = prev.controller;
    if (plain.text.isEmpty) return;
    final nextText = plain.text.substring(0, plain.text.length - 1);
    plain.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
    prev.focus.requestFocus();
  }

  KeyEventResult _onBackspaceAtFieldStart({
    required int index,
    required TextEditingController controller,
    required KeyEvent event,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (!_isCaretAtStart(controller)) return KeyEventResult.ignored;
    _deleteIntoPreviousSlot(index);
    return KeyEventResult.handled;
  }

  /// Backspace on empty base removes the ruby; otherwise at start deletes prior.
  KeyEventResult _onBackspaceAtKanji({
    required int index,
    required KeyEvent event,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    final slot = _slots[index];
    if (!slot.isRuby) return KeyEventResult.ignored;
    final kanji = slot.kanjiController!;
    if (kanji.text.isEmpty) {
      _removeRubySlot(index);
      return KeyEventResult.handled;
    }
    if (!_isCaretAtStart(kanji)) return KeyEventResult.ignored;
    _deleteIntoPreviousSlot(index);
    return KeyEventResult.handled;
  }

  /// Backspace at start of reading moves focus to the end of the base (no delete).
  KeyEventResult _onBackspaceAtReadingStart({
    required int index,
    required KeyEvent event,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    final slot = _slots[index];
    if (!slot.isRuby || !_isCaretAtStart(slot.controller)) {
      return KeyEventResult.ignored;
    }
    final kanji = slot.kanjiController!;
    final kanjiFocus = slot.kanjiFocus!;
    kanjiFocus.requestFocus();
    kanji.selection = TextSelection.collapsed(offset: kanji.text.length);
    return KeyEventResult.handled;
  }

  Future<void> _applyPlainWrap(
    int index, {
    required int start,
    required int end,
  }) async {
    final slot = _slots[index];
    if (slot.isRuby) return;
    slot.controller.removeListener(_syncToStorage);
    final ok = wikiRubyApplyWrapToController(
      slot.controller,
      '',
      start: start,
      end: end,
    );
    slot.controller.addListener(_syncToStorage);
    if (!ok) return;
    _syncToStorage(rebuildIfMarkupChanged: true);
  }

  void _focusNextRubyReading(int fromIndex) {
    for (var i = fromIndex + 1; i < _slots.length; i++) {
      if (_slots[i].isRuby) {
        _slots[i].focus.requestFocus();
        return;
      }
    }
    _slots[fromIndex].focus.unfocus();
  }

  void _focusNextFromKanji(int fromIndex) {
    final nextIndex = fromIndex + 1;
    if (nextIndex >= _slots.length) return;
    _slots[nextIndex].focus.requestFocus();
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
    if (!slot.isRuby) {
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
                      child: Focus(
                        onKeyEvent: (node, event) => _onBackspaceAtFieldStart(
                          index: index,
                          controller: slot.controller,
                          event: event,
                        ),
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
                              onRubyWrap: ({required start, required end}) =>
                                  _applyPlainWrap(
                                    index,
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
              ),
            ],
          ),
        ),
      );
    }

    final kanjiController = slot.kanjiController!;
    final kanjiFocus = slot.kanjiFocus!;
    final readingFocused = slot.focus.hasFocus;
    final baseFocused = kanjiFocus.hasFocus;
    final baseFontSize = widget.baseStyle.fontSize ?? 16;
    // Focused side maximized; the other side shrinks so editing is clearer.
    final activeRubyStyle = readingFocused
        ? wikiRubyReadingStyle(
            widget.baseStyle,
            rubyFontSize: baseFontSize * kWikiRubyFocusedReadingScale,
          )
        : rubyStyle;
    final activeBaseStyle = widget.baseStyle.copyWith(
      color: scheme.onSurface,
      height: 1.0,
      fontSize: readingFocused
          ? baseFontSize * kWikiRubyShrunkBaseScale
          : baseFontSize,
    );
    final isLastRuby = !_hasRubyAfter(index);
    final readingInputAction = isLastRuby
        ? TextInputAction.done
        : TextInputAction.next;
    final kanjiInputAction = isLastRuby
        ? TextInputAction.done
        : TextInputAction.next;
    final baseH = _lineHeight(activeBaseStyle);
    final readingUnderline = scheme.primary.withValues(
      alpha: _kRubyReadingUnderlineAlpha,
    );

    return _slotShell(
      scheme: scheme,
      highlighted: readingFocused || baseFocused,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: _textWidth(
                slot.controller.text,
                activeRubyStyle,
                whenEmpty: widget.readingHint,
              ),
              child: Focus(
                onKeyEvent: (node, event) =>
                    _onBackspaceAtReadingStart(index: index, event: event),
                child: TextField(
                  controller: slot.controller,
                  focusNode: slot.focus,
                  style: activeRubyStyle.copyWith(
                    color: scheme.onSurface,
                    decoration: TextDecoration.underline,
                    decorationColor: readingUnderline,
                    decorationStyle: TextDecorationStyle.solid,
                  ),
                  textAlign: TextAlign.center,
                  decoration: _kPlainSlotDecoration.copyWith(
                    hintText: widget.readingHint,
                    hintStyle: activeRubyStyle.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  textInputAction: readingInputAction,
                  onSubmitted: (_) => _focusNextRubyReading(index),
                ),
              ),
            ),
            IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: _kPlainFieldMinWidth,
                ),
                child: SizedBox(
                  height: baseH,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildKanjiField(
                      index: index,
                      controller: kanjiController,
                      focusNode: kanjiFocus,
                      baseStyle: activeBaseStyle,
                      textAlign: TextAlign.center,
                      textInputAction: kanjiInputAction,
                      onSubmitted: (_) => _focusNextFromKanji(index),
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

  Widget _buildKanjiField({
    required int index,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextStyle baseStyle,
    required TextAlign textAlign,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Focus(
      onKeyEvent: (node, event) =>
          _onBackspaceAtKanji(index: index, event: event),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: baseStyle,
        strutStyle: StrutStyle.fromTextStyle(baseStyle, forceStrutHeight: true),
        cursorHeight: baseStyle.fontSize,
        textAlign: textAlign,
        textAlignVertical: TextAlignVertical.bottom,
        maxLines: 1,
        scrollPadding: EdgeInsets.zero,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: _kPlainSlotDecoration,
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
      if (_slots[i].isRuby) return true;
    }
    return false;
  }

  double _lineHeight(TextStyle style) {
    final fontSize = style.fontSize ?? 16;
    return fontSize * (style.height ?? 1.0);
  }

  double _textWidth(String text, TextStyle style, {String? whenEmpty}) {
    final sample = text.isEmpty ? (whenEmpty ?? '') : text;
    if (sample.isEmpty) return _kPlainFieldMinWidth;
    final painter = TextPainter(
      text: TextSpan(text: sample, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.clamp(_kPlainFieldMinWidth, double.infinity);
  }
}

/// Whether [text] should use the ruby reading editor instead of a plain field.
bool wikiRubyContentUsesReadingEditor(String text) =>
    WikiRubyMarkup.looksLikeMarkup(text);
