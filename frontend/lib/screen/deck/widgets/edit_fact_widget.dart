import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/deck.dart';
import '../../../models/fact.dart';
import '../../../providers/loading_state_provider.dart';
import '../../../services/apis/card_service.dart';
import '../../learn/widgets/loading_state_widget.dart';

class EditFactWidget extends ConsumerStatefulWidget {
  const EditFactWidget({
    super.key,
    required this.deck,
    required this.factId,
    required this.onSaved,
  });

  final Deck deck;

  /// Fact id from the current card (passed from parent scope so this sheet does
  /// not depend on [cardProvider] inside a modal route).
  final String factId;

  /// Refresh cards using the **parent** [WidgetRef] (learn screen notifier).
  final Future<void> Function() onSaved;

  @override
  ConsumerState<EditFactWidget> createState() => _EditFactWidgetState();
}

class _EditFactWidgetState extends ConsumerState<EditFactWidget> {
  bool _loading = true;
  String? _error;
  Fact? _loaded;
  List<TextEditingController>? _controllers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFact());
  }

  Future<void> _loadFact() async {
    final fact = await CardService.getFact(widget.deck.id, widget.factId);
    if (!mounted) return;
    if (fact == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load fact';
      });
      return;
    }
    if (fact.entries.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Fact has no entries';
      });
      return;
    }
    final controllers = fact.entries
        .map((e) => TextEditingController(text: e.text))
        .toList();
    setState(() {
      _loaded = fact;
      _controllers = controllers;
      _loading = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers ?? <TextEditingController>[]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _mergedFactHasContent(Fact f) {
    for (final e in f.entries) {
      if (e.text.isNotEmpty ||
          e.audio.isNotEmpty ||
          e.image.isNotEmpty ||
          e.video.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  String _labelFor(int index) {
    final fact = _loaded;
    if (fact != null && index < fact.fields.length) {
      return fact.fields[index];
    }
    return 'Field ${index + 1}';
  }

  Future<void> _onSave() async {
    final loaded = _loaded;
    final controllers = _controllers;
    if (loaded == null || controllers == null) return;

    final texts = controllers.map((c) => c.text).toList();
    final merged = loaded.withMergedTexts(texts);
    if (!_mergedFactHasContent(merged)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one entry must have content')),
      );
      return;
    }

    ref.read(loadingStateProvider.notifier).showLoading();
    final res = await CardService.updateFact(
      widget.deck.id,
      merged.id,
      merged.toUpdateBody(),
    );
    ref.read(loadingStateProvider.notifier).showLoaded();

    if (!mounted) return;
    if (res?.isSuccess != true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res?.msg ?? 'Update failed')));
      return;
    }
    await widget.onSaved();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final controllers = _controllers!;
    return SafeArea(
      child: FocusTraversalGroup(
        child: Column(
          spacing: 20,
          children: [
            ...List.generate(controllers.length, (i) {
              return TextFormField(
                controller: controllers[i],
                decoration: InputDecoration(
                  labelText: _labelFor(i),
                  border: const OutlineInputBorder(),
                ),
                maxLines: null,
              );
            }),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onSave,
                child: Row(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    LoadingStateWidget(child: Icon(LucideIcons.save)),
                    const Text('Save'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
