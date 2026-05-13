import 'package:flutter/material.dart';
import 'package:retentio/constants.dart';
import 'package:retentio/theme/theme_tokens.dart';

class AppInput extends StatelessWidget {
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

  bool get _hasCustomBorder => border != null;

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
    final resolvedMaxLines = obscureText ? 1 : maxLines;
    final resolvedMinLines = obscureText ? 1 : minLines;
    final isSingleLine =
        resolvedMaxLines == 1 && (resolvedMinLines == null || resolvedMinLines == 1);

    final baseDecoration = InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefix,
      suffix: suffix,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding ?? AppThemeTokens.inputContentPadding,
      isDense: isDense,
      constraints: isSingleLine
          ? const BoxConstraints(
              minHeight: kTextFieldHeight,
              maxHeight: kTextFieldHeight,
            )
          : null,
      filled: filled ?? !enabled,
      fillColor:
          fillColor ??
          (!enabled ? colorScheme.onSurface.withValues(alpha: 0.08) : null),
      border: border,
      enabledBorder: _hasCustomBorder ? border : _border(colorScheme.outline),
      focusedBorder: _hasCustomBorder ? border : _border(colorScheme.primary),
      errorBorder: _hasCustomBorder ? border : _border(colorScheme.error),
      focusedErrorBorder: _hasCustomBorder
          ? border
          : _border(colorScheme.error),
      disabledBorder: _hasCustomBorder
          ? border
          : _border(colorScheme.onSurface.withValues(alpha: 0.12)),
      suffixIconConstraints: suffixConstraints ?? _kAffixConstraints,
      prefixIconConstraints: prefixConstraints ?? _kAffixConstraints,
      floatingLabelBehavior: floatingLabelBehavior,
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      enabled: enabled,
      maxLines: resolvedMaxLines,
      minLines: resolvedMinLines,
      textInputAction: textInputAction,
      focusNode: focusNode,
      style: style,
      textAlign: textAlign,
      textAlignVertical:
          textAlignVertical ?? (isSingleLine ? TextAlignVertical.center : null),
      selectAllOnFocus: selectAllOnFocus ?? false,
      onTapAlwaysCalled: onTapAlwaysCalled ?? false,
      onTap: onTap,
      contextMenuBuilder: contextMenuBuilder,
      enableInteractiveSelection: enableInteractiveSelection ?? true,
      textCapitalization: textCapitalization,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      decoration: decorationBuilder?.call(baseDecoration) ?? baseDecoration,
    );
  }
}
