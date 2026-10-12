import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../widgets/common_net_image.dart';

class CardImage extends HookConsumerWidget {
  const CardImage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = File(url);
    if (url.startsWith('/') && file.existsSync()) {
      return Image.file(file, fit: BoxFit.contain);
    }
    return CommonNetImage(url: url);
  }
}
