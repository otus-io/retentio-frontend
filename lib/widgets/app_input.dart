import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/constants.dart';
import 'package:retentio/theme/theme_tokens.dart';

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
    this.onEditingComplete,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction,
    this.focusNode,
    this.minLines,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.selectAllOnFocus,
    this.onTapAlwaysCalled,
    this.onTap,
    this.contextMenuBuilder,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.isDense,
    this.border,
    this.suffixConstraints,
    this.prefixConstraints,
    this.filled,
    this.fillColor,
    this.floatingLabelBehavior,
    this.onSubmitted,
    this.maxLength,
    this.style,
    this.enableInteractiveSelection,
    this.decorationBuilder,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final bool enabled;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final int? minLines;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool? selectAllOnFocus;
  final bool? onTapAlwaysCalled;
  final VoidCallback? onTap;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final bool? isDense;
  final InputBorder? border;
  final BoxConstraints? suffixConstraints;
  final BoxConstraints? prefixConstraints;
  final bool? filled;
  final Color? fillColor;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final TextStyle? style;
  final bool? enableInteractiveSelection;
  final InputDecoration Function(InputDecoration decoration)? decorationBuilder;
  final Iterable<String>? autofillHints;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _isObscured = true;

  bool get _hasCustomBorder => widget.border != null;

  static const BoxConstraints _kAffixConstraints = BoxConstraints(
    minWidth: 44,
    minHeight: 44,
  );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: AppThemeTokens.borderRadiusLg,
    borderSide: BorderSide(
      color: color,
      width: AppThemeTokens.borderWidthHairline,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bool effectiveObscure = widget.obscureText && _isObscured;
    final resolvedMaxLines = widget.obscureText ? 1 : widget.maxLines;
    final resolvedMinLines = widget.obscureText ? 1 : widget.minLines;
    final isSingleLine =
        resolvedMaxLines == 1 &&
        (resolvedMinLines == null || resolvedMinLines == 1);

    // Built-in show/hide toggle for password fields; only shown when no custom
    // suffixIcon is provided so callers retain full control when they need it.
    final Widget? passwordToggle =
        widget.obscureText && widget.suffixIcon == null
        ? IconButton(
            icon: Icon(
              _isObscured ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            splashRadius: 18,
            onPressed: () => setState(() => _isObscured = !_isObscured),
          )
        : null;

    final baseDecoration = InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      helperText: widget.helperText,
      errorText: widget.errorText,
      prefixIcon: widget.prefix,
      suffix: widget.suffix,
      suffixIcon: passwordToggle ?? widget.suffixIcon,
      contentPadding:
          widget.contentPadding ?? AppThemeTokens.inputContentPadding,
      isDense: widget.isDense,
      constraints: isSingleLine
          ? const BoxConstraints(
              minHeight: kTextFieldHeight,
              maxHeight: kTextFieldHeight,
            )
          : null,
      filled: widget.filled ?? !widget.enabled,
      fillColor:
          widget.fillColor ??
          (!widget.enabled
              ? colorScheme.onSurface.withValues(alpha: 0.08)
              : null),
      border: widget.border,
      enabledBorder: _hasCustomBorder
          ? widget.border
          : _border(colorScheme.outline),
      focusedBorder: _hasCustomBorder
          ? widget.border
          : _border(colorScheme.primary),
      errorBorder: _hasCustomBorder
          ? widget.border
          : _border(colorScheme.error),
      focusedErrorBorder: _hasCustomBorder
          ? widget.border
          : _border(colorScheme.error),
      disabledBorder: _hasCustomBorder
          ? widget.border
          : _border(colorScheme.onSurface.withValues(alpha: 0.12)),
      suffixIconConstraints: widget.suffixConstraints ?? _kAffixConstraints,
      prefixIconConstraints: widget.prefixConstraints ?? _kAffixConstraints,
      floatingLabelBehavior: widget.floatingLabelBehavior,
    );

    return TextField(
      controller: widget.controller,
      obscureText: effectiveObscure,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      enabled: widget.enabled,
      maxLines: resolvedMaxLines,
      minLines: resolvedMinLines,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      style: widget.style,
      textAlign: widget.textAlign,
      textAlignVertical:
          widget.textAlignVertical ??
          (isSingleLine ? TextAlignVertical.center : null),
      selectAllOnFocus: widget.selectAllOnFocus ?? false,
      onTapAlwaysCalled: widget.onTapAlwaysCalled ?? false,
      onTap: widget.onTap,
      contextMenuBuilder: widget.contextMenuBuilder,
      enableInteractiveSelection: widget.enableInteractiveSelection ?? true,
      textCapitalization: widget.textCapitalization,
      onSubmitted: widget.onSubmitted,
      maxLength: widget.maxLength,
      autofillHints: widget.autofillHints,
      decoration:
          widget.decorationBuilder?.call(baseDecoration) ?? baseDecoration,
    );
  }
}
