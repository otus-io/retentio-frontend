import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/common_net_image.dart';

class CardImage extends ConsumerWidget {
  const CardImage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommonNetImage(url: url);
  }
}
