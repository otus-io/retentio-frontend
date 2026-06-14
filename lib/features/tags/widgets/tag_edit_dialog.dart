import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/theme/theme_tokens.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';

const double _kTagDialogWidth = 360;
const double _kTagDialogRadius = 28;

Future<void> showTagEditDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
  String initialDescription = '',
  required Future<String?> Function(String name, String description) onConfirm,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _TagEditDialog(
        title: title,
        confirmLabel: confirmLabel,
        initialName: initialName,
        initialDescription: initialDescription,
        onConfirm: onConfirm,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
    routeSettings: const RouteSettings(name: 'tag-edit-dialog'),
    requestFocus: false,
  );
}

class _TagEditDialogScaffold extends StatelessWidget {
  const _TagEditDialogScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TagDialogPanel extends StatelessWidget {
  const _TagDialogPanel({
    required this.panelColor,
    required this.borderColor,
    required this.shadowColor,
    required this.child,
  });

  final Color? panelColor;
  final Color borderColor;
  final Color shadowColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kTagDialogWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(_kTagDialogRadius),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _TagEditDialog extends StatefulWidget {
  const _TagEditDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.initialDescription,
    required this.onConfirm,
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final String initialDescription;
  final Future<String?> Function(String name, String description) onConfirm;

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final FocusNode _nameFocusNode;

  String? _nameError;
  String? _submitError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _nameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = loc.tagNameRequired;
        _submitError = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _nameError = null;
      _submitError = null;
    });

    final error = await widget.onConfirm(
      name,
      _descriptionController.text.trim(),
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _submitError = error;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final panelColor = Color.lerp(
      scheme.surface,
      scheme.surfaceContainerHighest,
      0.5,
    );
    final fieldColor = scheme.surfaceContainerHighest.withValues(alpha: 0.72);
    final fieldBorder = OutlineInputBorder(
      borderRadius: AppThemeTokens.borderRadiusXl,
      borderSide: BorderSide(
        color: scheme.outline.withValues(alpha: 0.16),
        width: AppThemeTokens.borderWidthHairline,
      ),
    );

    return _TagEditDialogScaffold(
      child: _TagDialogPanel(
        panelColor: panelColor,
        borderColor: scheme.outline.withValues(alpha: 0.12),
        shadowColor: scheme.shadow.withValues(alpha: 0.14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.18),
                  borderRadius: AppThemeTokens.borderRadiusPill,
                ),
              ),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 18),
              AppInput(
                controller: _nameController,
                focusNode: _nameFocusNode,
                hint: AppLocalizations.of(context)!.tagName,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null || _submitError != null) {
                    setState(() {
                      _nameError = null;
                      _submitError = null;
                    });
                  }
                },
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.next,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                filled: true,
                fillColor: fieldColor,
                border: fieldBorder,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _descriptionController,
                hint: AppLocalizations.of(context)!.tagDescription,
                maxLines: 3,
                minLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                filled: true,
                fillColor: fieldColor,
                border: fieldBorder,
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                textAlignVertical: TextAlignVertical.top,
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _submitError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: AppLocalizations.of(context)!.cancel,
                    variant: AppButtonVariant.ghost,
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    label: widget.confirmLabel,
                    variant: AppButtonVariant.primary,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
