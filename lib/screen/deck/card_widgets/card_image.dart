import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../widgets/common_net_image.dart';

/// Whether [url] is an absolute file path in [style], the running platform's
/// path style by default.
bool isLocalImagePath(String url, {p.Context? style}) =>
    (style ?? p.context).isAbsolute(url);

class CardImage extends HookConsumerWidget {
  const CardImage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocalFile = useMemoized(
      () => isLocalImagePath(url) && File(url).existsSync(),
      [url],
    );
    if (isLocalFile) return Image.file(File(url), fit: BoxFit.contain);
    return CommonNetImage(url: url);
  }
}
