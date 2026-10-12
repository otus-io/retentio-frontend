import 'dart:io';

import 'package:flutter/material.dart';
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
    final file = File(url);
    if (isLocalImagePath(url) && file.existsSync()) {
      return Image.file(file, fit: BoxFit.contain);
    }
    return CommonNetImage(url: url);
  }
}
