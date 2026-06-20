import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_input.dart';
import 'package:retentio/widgets/common_bottom_sheet.dart';

const double _kTagSheetInitialSize = 0.48;
const double _kTagSheetMinSize = 0.38;
const double _kTagSheetMaxSize = 0.72;

Future<void> showTagEditDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
  String initialDescription = '',
  required Future<String?> Function(String name, String description) onConfirm,
}) {
  return showCommonBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    title: title,
    initialChildSize: _kTagSheetInitialSize,
    minChildSize: _kTagSheetMinSize,
    maxChildSize: _kTagSheetMaxSize,
    routeSettings: const RouteSettings(name: 'tag-edit-sheet'),
    child: _TagEditForm(
      confirmLabel: confirmLabel,
      initialName: initialName,
      initialDescription: initialDescription,
      onConfirm: onConfirm,
    ),
  );
}

class _TagEditForm extends StatefulWidget {
  const _TagEditForm({
    required this.confirmLabel,
    required this.initialName,
    required this.initialDescription,
    required this.onConfirm,
  });

  final String confirmLabel;
  final String initialName;
  final String initialDescription;
  final Future<String?> Function(String name, String description) onConfirm;

  @override
  State<_TagEditForm> createState() => _TagEditFormState();
}

class _TagEditFormState extends State<_TagEditForm> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_nameError != null || _submitError != null) {
      setState(() {
        _nameError = null;
        _submitError = null;
      });
    }
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
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          controller: _nameController,
          focusNode: _nameFocusNode,
          label: loc.tagName,
          hint: loc.tagNameHint,
          errorText: _nameError,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearErrors(),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        AppInput(
          controller: _descriptionController,
          label: loc.tagDescription,
          maxLines: 3,
          minLines: 3,
          textInputAction: TextInputAction.done,
          textAlignVertical: TextAlignVertical.top,
          onSubmitted: (_) => _submit(),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Text(
            _submitError!,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: 20),
        AppButton(
          label: widget.confirmLabel,
          variant: AppButtonVariant.primary,
          fullWidth: true,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: loc.cancel,
          variant: AppButtonVariant.ghost,
          fullWidth: true,
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
