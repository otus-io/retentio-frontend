// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Wordupx';

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get loginPageTitle => '登录';

  @override
  String get email => '邮箱';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get pleaseFillAllFields => '请填写所有字段';

  @override
  String get passwordNotMatch => '两次密码输入不一致';

  @override
  String get registerSuccess => '注册成功';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get loginFailed => '登录失败';

  @override
  String get backToLogin => '返回登录';

  @override
  String get resetPassword => '重置密码';

  @override
  String get resetPasswordSent => '重置密码邮件已发送';

  @override
  String get home => '首页';

  @override
  String get learn => '学习';

  @override
  String get profile => '我的';
}
