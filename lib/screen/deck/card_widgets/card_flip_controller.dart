import 'package:flutter/material.dart';

class CardFlipController extends ChangeNotifier {
  bool isFront = true;

  /// 切换正反面
  void flip() {
    isFront = !isFront;
    notifyListeners();
  }

  /// 强制显示正面
  void showFront() {
    if (!isFront) {
      isFront = true;
      notifyListeners();
    }
  }

  /// 强制显示背面
  void showBack() {
    if (isFront) {
      isFront = false;
      notifyListeners();
    }
  }
}
