import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/providers/locale_provider.dart';
import 'package:retentio/providers/theme_provider.dart';

class LoginToolbarControls extends ConsumerWidget {
  final bool isLoading;
  final bool isDark;

  const LoginToolbarControls({
    super.key,
    required this.isLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final paddingTop = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned(
          top: paddingTop,
          right: 24,
          child: Center(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: currentLocale,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: Colors.grey,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                borderRadius: BorderRadius.circular(4),
                items: const [
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text(
                      'ENGLISH',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                  DropdownMenuItem(
                    value: Locale('zh'),
                    child: Text(
                      '简体中文',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
                onChanged: isLoading
                    ? null
                    : (Locale? newLocale) {
                        if (newLocale != null) {
                          ref
                              .read(localeProvider.notifier)
                              .setLocale(newLocale);
                        }
                      },
              ),
            ),
          ),
        ),
        Positioned(
          top: paddingTop,
          left: 24,
          child: IconButton(
            icon: Icon(
              isDark ? CupertinoIcons.moon : CupertinoIcons.sun_max,
              color: Colors.grey,
              size: 22,
            ),
            tooltip: isDark ? '切换到浅色' : '切换到深色',
            onPressed: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ),
      ],
    );
  }
}
