// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Retentio';

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
  String get decks => '卡组';

  @override
  String get profile => '我的';

  @override
  String get noDecksAvailable => '暂无卡组';

  @override
  String get retry => '重试';

  @override
  String get words => '单词';

  @override
  String get progress => '学习进度';

  @override
  String get cards => '卡片';

  @override
  String get newCards => '新卡片';

  @override
  String get review => '复习';

  @override
  String get facts => '词条';

  @override
  String openDeck(String deckName) {
    return '打开卡组：$deckName';
  }

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirmTitle => '退出登录';

  @override
  String get logoutConfirmMessage => '确定要退出登录吗？';

  @override
  String get cancel => '取消';

  @override
  String get changeLanguage => '更改语言';

  @override
  String get changeTheme => '更改主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get totalCards => '总计';

  @override
  String get dueCards => '待复习';

  @override
  String get learned => '已学习';

  @override
  String get noCardsInDeck => '卡组中没有卡片';

  @override
  String get startLearning => '开始学习';

  @override
  String get allCaughtUp => '全部完成！';

  @override
  String startLearningDeck(String deckName) {
    return '开始学习：$deckName';
  }

  @override
  String get showAnswer => '显示答案';

  @override
  String get hard => '困难';

  @override
  String get good => '一般';

  @override
  String get easy => '简单';

  @override
  String get backToDeck => '返回卡组';

  @override
  String get viewCards => '查看';

  @override
  String get learnButton => '学习';

  @override
  String get manage => '管理';

  @override
  String get createDeck => '创建卡组';

  @override
  String get createInputDeckName => '名称';

  @override
  String get createInputDeckNameHint => '为你的deck设置name';

  @override
  String get language => '语言';

  @override
  String get rate => '速率';

  @override
  String get slow => '慢';

  @override
  String get fast => '快';

  @override
  String get unidirectional => '单向';

  @override
  String get bidirectional => '双向';

  @override
  String get template => '模版';

  @override
  String get next => '下一个';

  @override
  String get noNetworkConnection => '网络连接不可用，请检查网络设置';

  @override
  String get reviewAgain => '再次复习';

  @override
  String get editDeck => '编辑卡组';

  @override
  String get hideCard => '隐藏卡片';

  @override
  String get deleteCard => '删除卡片';

  @override
  String get deleteCardConfirm => '只会删除这一张卡片；对应的词条及其他卡片仍会保留。';

  @override
  String get deleteCardFailed => '无法删除卡片';

  @override
  String get deleteDeck => '删除卡组';

  @override
  String get noCardsInThisDeck => '这个卡组中没有卡片';

  @override
  String get save => '保存';

  @override
  String newCardEveryMinutes(int interval) {
    return '每$interval分钟引入一张新卡片';
  }

  @override
  String get addFact => '添加词条';

  @override
  String get addFactAddRow => '添加一行';

  @override
  String get addFactRemoveRow => '删除该行';

  @override
  String get addFactFieldNameHint => '字段名（可选）';

  @override
  String get addFactContentHint => '文本（若已添加媒体可留空）';

  @override
  String get addFactAttachImage => '图片';

  @override
  String get addFactAttachVideo => '视频';

  @override
  String get addFactAttachAudio => '音频';

  @override
  String get addFactClearAttachment => '清除';

  @override
  String get addFactAttachMediaTooltip => '添加图片、视频或音频；长按可移除。';

  @override
  String get addFactGalleryMediaTooltip => '从相册选择照片或视频；长按可移除。';

  @override
  String get addFactSubmit => '保存词条';

  @override
  String get addFactUploadFailed => '上传失败，请重试。';

  @override
  String addFactFileTooLarge(int maxMb) {
    return '文件过大（最大 $maxMb MB）。';
  }

  @override
  String get addFactEntryNeedsContent => '每一行至少需要填写文本或添加一种附件。';

  @override
  String get addFactFileTypeNotSupported => '不支持此文件类型。';

  @override
  String get addFactFileWrongSlot => '请选择与附件类型匹配的文件。';

  @override
  String get addFactFailed => '无法添加词条';

  @override
  String get addFactSuccess => '已添加词条';

  @override
  String addFactFieldFallback(int number) {
    return '字段 $number';
  }

  @override
  String get addFactFieldShortLabel => '字段';
}
