import 'package:flutter/material.dart';
import 'package:retentio/widgets/app_toast.dart';

void showSnack(BuildContext context, String message) {
  AppToast.show(context, message);
}
