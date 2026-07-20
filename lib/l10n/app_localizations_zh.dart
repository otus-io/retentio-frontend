// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Rete';

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
  String get noCardsForTagFilter => '该标签下暂无卡片';

  @override
  String noCardsForTagFilterNamed(String tagName) {
    return '标签「$tagName」下暂无卡片';
  }

  @override
  String get clearTagFilter => '清除筛选';

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
  String get createInputDeckName => '卡组名称';

  @override
  String get createInputDeckNameHint => '为你的deck设置name';

  @override
  String get deckEditorFieldHint => '例如：英语';

  @override
  String get deckEditorFieldHintSecond => '例如：日语';

  @override
  String get deckEditorAddFieldTooltip => '添加列标题';

  @override
  String get deckCreateAddField => '新增一个字段';

  @override
  String get deckEditorRemoveFieldTooltip => '移除此列标题';

  @override
  String get deckEditorNameRequired => '请输入卡组名称';

  @override
  String get deckEditorMinTwoFields => '请再添加一个列标题（至少需要两列）';

  @override
  String get deckEditorFieldNamesRequired => '请填写每个列标题';

  @override
  String get language => '语言';

  @override
  String get rate => '速率';

  @override
  String get cardsPerDay => '张新卡片/天';

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
  String get editFact => '编辑词条';

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
  String get addFactRecordAudioTooltip => '使用麦克风录音；再次点击结束并附加。录音时长按可放弃。';

  @override
  String get addFactStopRecordingTooltip => '停止录音并将音频附加到该字段';

  @override
  String get addFactMicPermissionDenied => '录音需要麦克风权限。';

  @override
  String get addFactRecordingFailed => '录音失败，请重试。';

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

  @override
  String get addFactPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get cardAudioUnavailable => '音频不可用（文件无效或缺失）';

  @override
  String get font => '字体';

  @override
  String get deckFontSheetTitle => '字体与注音';

  @override
  String get deckFontMainSizeLabel => '正文字号';

  @override
  String get deckFontRubySizeLabel => '注音字号';

  @override
  String get deckFontPreviewCaption => '预览';

  @override
  String get deckFontTabFront => '正面';

  @override
  String get deckFontTabBack => '背面';

  @override
  String get tags => '标签';

  @override
  String get tagLabel => '标签';

  @override
  String get addTag => '添加标签';

  @override
  String get createTag => '创建标签';

  @override
  String get editTag => '编辑标签';

  @override
  String get deleteTag => '删除标签';

  @override
  String get tagName => '标签名称';

  @override
  String get tagDescription => '描述（可选）';

  @override
  String get tagNameHint => '例如：语法、动词…';

  @override
  String get tagNameRequired => '请输入标签名称';

  @override
  String get tagCreated => '标签已创建';

  @override
  String get tagUpdated => '标签已更新';

  @override
  String get tagDeleted => '标签已删除';

  @override
  String get tagCreateFailed => '无法创建标签';

  @override
  String get tagUpdateFailed => '无法更新标签';

  @override
  String get tagDeleteFailed => '无法删除标签';

  @override
  String get tagAlreadyExists => '已存在同名标签';

  @override
  String get tagLimitReached => '最多只能创建 1000 个标签';

  @override
  String get noTags => '暂无标签';

  @override
  String get manageTags => '管理标签';

  @override
  String get tagPickerTitle => '选择标签';

  @override
  String get tagPickerSearchHint => '搜索标签…';

  @override
  String get tagPickerDone => '完成';

  @override
  String tagPickerNoMatch(String query) {
    return '没有匹配\"$query\"的标签';
  }

  @override
  String get tagPickerEmptyHint => '暂无标签，点击下方创建第一个';

  @override
  String get filterAll => '全部';

  @override
  String get studyTagFilterTitle => '按标签复习';

  @override
  String get tagFacts => '词条';

  @override
  String get noFactsInTag => '该标签下还没有词条';

  @override
  String get discoveryTab => '发现';

  @override
  String get discoverySearchHint => '搜索卡组、作者、标签';

  @override
  String get discoveryFilterLatest => '最新';

  @override
  String get discoveryFilterFavorites => '收藏';

  @override
  String get discoveryEmpty => '暂无公开卡组';

  @override
  String get discoveryFavoritesEmpty => '暂无收藏卡组';

  @override
  String get discoveryImport => '导入';

  @override
  String get discoveryImporting => '导入中…';

  @override
  String get discoveryImported => '已导入';

  @override
  String get discoveryGoStudy => '去学习';

  @override
  String get discoveryImportSuccess => '已添加到你的卡组';

  @override
  String get discoveryFavorite => '收藏';

  @override
  String get discoveryUnfavorite => '取消收藏';

  @override
  String discoveryYearsAgo(int count) {
    return '$count年前';
  }

  @override
  String discoveryMonthsAgo(int count) {
    return '$count个月前';
  }

  @override
  String discoveryDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String discoveryHoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String get discoveryJustNow => '刚刚';

  @override
  String get discoveryDeckUnavailable => '已下架';

  @override
  String discoveryCardSemantics(String name, String factCount, String owner) {
    return '$name，$factCount，作者 $owner';
  }

  @override
  String get discoveryImportedBadgeSemantics => '已导入到我的卡组';

  @override
  String get discoveryUnavailableBadgeSemantics => '该卡组已下架';

  @override
  String discoveryLoginToAccessTab(String tabLabel) {
    return '登录后即可使用$tabLabel。';
  }

  @override
  String get deckOptionsTooltip => '卡组选项';

  @override
  String get discoveryNotFound => '卡组不存在或已下架';

  @override
  String get discoveryImportSelf => '不能导入自己的卡组';

  @override
  String get discoveryImportDuplicate => '该卡组已经导入过了';

  @override
  String get discoveryImportFailed => '导入失败，请重试';

  @override
  String get discoveryLoginToImport => '请登录后导入';

  @override
  String get discoveryRetry => '重试';

  @override
  String get publishDeck => '发布卡组';

  @override
  String get publishDeckHint => '发布后，其他用户可在「发现」页浏览并导入你的卡组。';

  @override
  String get publishDeckAction => '发布';

  @override
  String get publishingDeck => '发布中…';

  @override
  String get publishDeckSuccess => '已发布！';

  @override
  String get publishDeckFailed => '发布失败，请重试';

  @override
  String get publishDeckAlreadyPublished => '已发布';

  @override
  String get publishDeckUpdate => '更新已发布版本';

  @override
  String get errorUnknown => '发生意外错误';

  @override
  String get authInvalidCredentials => '用户名或密码错误';

  @override
  String get authUsernameAlreadyExists => '用户名已被使用';

  @override
  String get authEmailAlreadyInUse => '邮箱已被注册';

  @override
  String get authSessionExpired => '登录已过期，请重新登录';

  @override
  String get authTokenRequired => '请登录后继续';

  @override
  String get authResetTokenInvalid => '重置链接无效或已过期';

  @override
  String get errorLoginFailed => '登录失败，请重试';

  @override
  String get errorRegisterFailed => '注册失败，请重试';

  @override
  String get errorPublishedDeckCannotDelete => '已发布的卡组不能删除';

  @override
  String get errorNoChangesToPublish => '没有需要发布的更改';

  @override
  String get errorSourceDeckNotImportable => '该卡组不支持导入';

  @override
  String get errorCannotImportImportedDeck => '不能重复导入同一卡组';

  @override
  String get errorSourceDeckNotPublished => '该卡组尚未发布';

  @override
  String get errorCannotModifyImportedDeck => '导入的卡组不能修改';

  @override
  String get discoveryDetailFields => '字段';

  @override
  String get discoveryDetailDescription => '简介';

  @override
  String discoveryDetailFactCount(int count) {
    return '$count词';
  }

  @override
  String get imageLoadFailed => '加载失败';

  @override
  String get homeDailyGoal => '每日目标';

  @override
  String get homeLearningPath => '学习路径';

  @override
  String get homeToday => '今日';

  @override
  String get homeTodayFocus => '今日重点';

  @override
  String get homeTodayFocusText => '先完成一轮复习，再从学习笔记中添加新词条。';

  @override
  String get apiUserNotFound => '用户不存在';

  @override
  String get apiInvalidRequestPayload => '请求无效，请重试';

  @override
  String get apiDeckNotFound => '卡组不存在';

  @override
  String get apiNotAuthorizedAccessDeck => '无权访问此卡组';

  @override
  String get apiNotAuthorizedModifyDeck => '无权修改此卡组';

  @override
  String get apiNotAuthorizedDeleteDeck => '无权删除此卡组';

  @override
  String get apiNotAuthorized => '无权执行此操作';

  @override
  String get apiServerRetrieveDeck => '无法加载卡组，请重试';

  @override
  String get apiServerParseDeck => '卡组数据异常，请重试';

  @override
  String get apiRegisterFieldsRequired => '请填写用户名、密码和邮箱';

  @override
  String get apiLoginFieldsRequired => '请填写用户名和密码';

  @override
  String get apiServerCheckUsername => '无法验证用户名，请重试';

  @override
  String get apiServerCheckEmail => '无法验证邮箱，请重试';

  @override
  String get apiServerHashPassword => '无法处理密码，请重试';

  @override
  String get apiServerSerializeUser => '无法保存用户数据，请重试';

  @override
  String get apiServerCreateUser => '无法创建账户，请重试';

  @override
  String get apiServerRetrieveUser => '无法加载用户数据，请重试';

  @override
  String get apiServerParseUser => '用户数据异常，请重试';

  @override
  String get apiServerGenerateToken => '无法登录，请重试';

  @override
  String get apiServerLogout => '无法退出登录，请重试';

  @override
  String get apiEmailRequired => '请填写邮箱';

  @override
  String get apiServerGenerateResetToken => '无法发送重置邮件，请重试';

  @override
  String get apiServerStoreResetToken => '无法处理重置请求，请重试';

  @override
  String get apiResetFieldsRequired => '请提供重置令牌和新密码';

  @override
  String get apiServerValidateResetToken => '无法验证重置链接，请重试';

  @override
  String get apiServerResetPassword => '无法重置密码，请重试';

  @override
  String get apiServerRetrieveProfile => '无法加载个人资料，请重试';

  @override
  String get apiDeckNameRequired => '请填写卡组名称';

  @override
  String get apiDeckFieldsRequired => '至少需要一个列名';

  @override
  String get apiDeckFieldNameEmpty => '列名不能为空';

  @override
  String get apiDeckRateRequired => '每日新卡数量须在 1 到 1000 之间';

  @override
  String get apiTagsOrTagIds => '请只填写标签名或标签 ID，不能同时填写';

  @override
  String get apiDeckDescriptionInvalidChars => '卡组描述包含无效字符';

  @override
  String get apiDeckDescriptionTooLong => '卡组描述最多 500 个字符';

  @override
  String get apiTagIdRequired => '请提供标签 ID';

  @override
  String get apiMaxTagsPerDeck => '卡组标签数量已达上限';

  @override
  String get apiTagNameRequired => '请填写标签名称';

  @override
  String get apiTagNameInvalidChars => '标签名称包含无效字符';

  @override
  String get apiTagNameTooLong => '标签名称过长（最多 50 个字符）';

  @override
  String get apiTagNotFound => '标签不存在';

  @override
  String get apiServerResolveDeckTags => '无法解析卡组标签，请重试';

  @override
  String get apiServerGenerateDeckId => '无法创建卡组，请重试';

  @override
  String get apiServerMarshalDeck => '无法保存卡组，请重试';

  @override
  String get apiServerCreateDeck => '无法创建卡组，请重试';

  @override
  String get apiServerPrepareDeckMedia => '无法准备媒体存储，请重试';

  @override
  String get apiDeckRateRange => '每日新卡数量须在 1 到 1000 之间';

  @override
  String get apiInvalidVisibility => '可见性设置无效';

  @override
  String get apiCannotChangeVisibilityAfterPublish => '发布后不能更改可见性';

  @override
  String get apiCannotChangeVisibilityImported => '导入的卡组不能更改可见性';

  @override
  String get apiCannotChangeFieldsImported => '导入的卡组不能更改字段';

  @override
  String get apiCannotChangeNameImported => '导入的卡组不能更改名称';

  @override
  String get apiCannotChangeDescriptionImported => '导入的卡组不能更改描述';

  @override
  String get apiImportedDeckRateRequired => '更新导入卡组需要设置每日新卡数量';

  @override
  String get apiServerSerializeDeck => '无法保存卡组，请重试';

  @override
  String get apiServerLoadCards => '无法加载卡片，请重试';

  @override
  String get apiServerRescheduleCards => '无法重新安排卡片，请重试';

  @override
  String get apiServerUpdateDeckCards => '无法更新卡组，请重试';

  @override
  String get apiServerUpdateDeck => '无法更新卡组，请重试';

  @override
  String get apiServerLoadFactsDelete => '无法删除卡组，请重试';

  @override
  String get apiServerCleanupTags => '无法删除卡组，请重试';

  @override
  String get apiServerDeleteDeck => '无法删除卡组，请重试';

  @override
  String get apiServerRevokeMediaGrants => '无法删除卡组，请重试';

  @override
  String get apiServerRetrieveDecks => '无法加载卡组列表，请重试';

  @override
  String get apiServerRetrieveDeckData => '无法加载卡组，请重试';

  @override
  String get apiServerListCatalog => '无法加载目录，请重试';

  @override
  String get apiServerLoadCatalogDeck => '无法加载卡组详情，请重试';

  @override
  String get apiFirstPublishPublic => '首次发布需要设为公开';

  @override
  String get apiCannotPublishImported => '导入的卡组不能发布';

  @override
  String get apiSourceDeckIdRequired => '请提供源卡组 ID';

  @override
  String get apiMaxFactTagsPerDeck => '词条标签数量已达上限';

  @override
  String get apiUpdatesImportedOnly => '仅导入的卡组可查看更新';

  @override
  String get apiNotImportedDeck => '此卡组不是导入的卡组';

  @override
  String get apiSourceDeckMissing => '源卡组不存在';

  @override
  String get apiFactsArrayRequired => '请提供词条数据';

  @override
  String get apiInvalidFactOperation => '无效操作，支持：append、prepend、shuffle、spread';

  @override
  String get apiDeckRateMinForFacts => '添加词条前请将每日新卡数量设为至少 1';

  @override
  String get apiAtLeastOneFact => '至少需要一个词条';

  @override
  String get apiTemplateInvalid => '卡片模板无效';

  @override
  String get apiEntryContentRequired => '每个条目需要文字、音频、图片、视频或 JSON';

  @override
  String get apiFactNotFound => '词条不存在';

  @override
  String get apiServerAddFacts => '无法添加词条，请重试';

  @override
  String get apiServerMergeFacts => '无法添加词条，请重试';

  @override
  String get apiServerSerializeFact => '无法保存词条，请重试';

  @override
  String get apiServerRebuildTemplate => '无法更新卡片，请重试';

  @override
  String get apiServerRetrieveCards => '无法加载卡片，请重试';

  @override
  String get apiServerSerializeCard => '无法保存卡片，请重试';

  @override
  String get apiServerUpdateFact => '无法更新词条，请重试';

  @override
  String get apiServerRemoveFactTags => '无法更新词条，请重试';

  @override
  String get apiServerRemoveFact => '无法移除词条，请重试';

  @override
  String get apiServerDeleteFact => '无法删除词条，请重试';

  @override
  String get apiServerRetrieveFacts => '无法加载词条，请重试';

  @override
  String get apiServerRetrieveFactTags => '无法加载词条标签，请重试';

  @override
  String get apiServerCheckFact => '无法验证词条，请重试';

  @override
  String get apiInvalidUsedOnFilter => '筛选条件无效';

  @override
  String get apiUsedOnRequired => '设置卡组 ID 时需要指定筛选类型';

  @override
  String get apiDeckIdRequiredForFact => '按词条筛选时需要提供卡组 ID';

  @override
  String get apiServerRetrieveTags => '无法加载标签，请重试';

  @override
  String get apiServerCheckTags => '无法验证标签，请重试';

  @override
  String get apiServerCheckTagName => '无法验证标签名称，请重试';

  @override
  String get apiServerGenerateTagId => '无法创建标签，请重试';

  @override
  String get apiServerCreateTag => '无法创建标签，请重试';

  @override
  String get apiServerSerializeTag => '无法保存标签，请重试';

  @override
  String get apiServerSaveTag => '无法保存标签，请重试';

  @override
  String get apiServerAssociateTag => '无法添加标签，请重试';

  @override
  String get apiServerRemoveTag => '无法移除标签，请重试';

  @override
  String get apiServerLoadTags => '无法加载标签，请重试';

  @override
  String get apiFactIdRequired => '请提供词条 ID';

  @override
  String get apiTemplateRequired => '请提供卡片模板';

  @override
  String get apiTemplateExists => '该词条已有卡片模板';

  @override
  String get apiCardNotFound => '卡片不存在';

  @override
  String get apiCardIdRequired => '请提供卡片 ID';

  @override
  String get apiCardIdEmpty => '卡片 ID 不能为空';

  @override
  String get apiIntervalOrHiddenRequired => '请提供 interval 或 hidden 字段';

  @override
  String get apiIntervalAndHiddenConflict => '不能在同一请求中同时发送 interval 和 hidden';

  @override
  String get apiLastReviewRequired => '更新间隔时需要提供 last_review';

  @override
  String get apiLastReviewIntervalOnly => 'last_review 仅适用于间隔更新';

  @override
  String get apiLastReviewNumeric => 'last_review 必须是数字 Unix 时间戳';

  @override
  String get apiLastReviewWhole => 'last_review 必须是整数 Unix 时间戳';

  @override
  String get apiLastReviewPositive => 'last_review 必须是正数 Unix 时间戳';

  @override
  String get apiIntervalNumeric => 'interval 必须是数字';

  @override
  String get apiIntervalPositive => 'interval 必须是正数';

  @override
  String get apiHiddenBoolean => 'hidden 必须是布尔值';

  @override
  String get apiUnsupportedCardOperation => '支持的操作：interval、visibility';

  @override
  String get apiCardTemplateInvalidForFact => '此词条的卡片模板无效';

  @override
  String get apiServerUpdateCardRedis => '无法更新卡片，请重试';

  @override
  String get apiServerCheckCardMembership => '无法验证卡片，请重试';

  @override
  String get apiServerParseCard => '卡片数据异常，请重试';

  @override
  String get apiServerUpdateCard => '无法更新卡片，请重试';

  @override
  String get apiServerCheckCard => '无法验证卡片，请重试';

  @override
  String get apiServerDeleteCard => '无法删除卡片，请重试';

  @override
  String get apiServerGenerateCardId => '无法创建卡片，请重试';

  @override
  String get apiServerMergeCard => '无法添加卡片，请重试';

  @override
  String get apiServerAddCard => '无法添加卡片，请重试';

  @override
  String get apiServerParseFact => '词条数据异常，请重试';

  @override
  String get apiInvalidMultipart => '文件上传无效';

  @override
  String get apiMissingFileField => '未选择文件或文件字段无效';

  @override
  String get apiMediaDeckIdRequired => '上传媒体需要卡组 ID';

  @override
  String get apiClientIdInUse => '上传 ID 已被使用，请重试';

  @override
  String get apiFileTooLarge => '文件过大';

  @override
  String get apiUnsupportedMediaType => '不支持的文件类型';

  @override
  String get apiInvalidJsonDocument => 'JSON 文件无效';

  @override
  String get apiMediaStorageNotConfigured => '媒体存储不可用';

  @override
  String get apiFailedCheckClientId => '上传失败，请重试';

  @override
  String get apiFailedVerifyDeck => '无法验证卡组，请重试';

  @override
  String get apiFailedReadFile => '无法读取文件，请重试';

  @override
  String get apiFailedGenerateId => '上传失败，请重试';

  @override
  String get apiFailedPrepareMedia => '上传失败，请重试';

  @override
  String get apiFailedStoreFile => '无法保存文件，请重试';

  @override
  String get apiFailedSaveMetadata => '无法保存文件信息，请重试';

  @override
  String get apiMediaVersionRequired => '此媒体需要指定版本参数';

  @override
  String get apiAccessDenied => '访问被拒绝';

  @override
  String get apiMediaNotFound => '媒体不存在';

  @override
  String get apiMediaFileNotFound => '媒体文件不存在';

  @override
  String get apiFailedListMedia => '无法加载媒体，请重试';

  @override
  String get apiFailedLoadMedia => '无法加载媒体，请重试';

  @override
  String get apiFeedbackImportedOnly => '仅导入的卡组可提交贡献';

  @override
  String get apiFeedbackSourceNotPublished => '源卡组尚未发布';

  @override
  String get apiFeedbackMessageLength => '反馈内容须在 1 到 2000 个字符之间';

  @override
  String get apiEntryIndexOutOfRange => '条目索引超出范围';

  @override
  String get apiProposedEntriesContent => '建议条目不能为空';

  @override
  String get apiProposedEntriesLength => '建议条目数量须与词条一致';

  @override
  String get apiProposedEntriesDiffer => '建议条目须与原文不同';

  @override
  String get apiFactNotInSnapshot => '词条不在固定快照中';

  @override
  String get apiFeedbackDeckNotFound => '卡组不存在';

  @override
  String get apiFeedbackFactNotFound => '词条不存在';

  @override
  String get apiFeedbackDailyLimit => '今日贡献次数已达上限，请明天再试';

  @override
  String get apiServerSubmitFeedback => '无法提交反馈，请重试';

  @override
  String get apiFeedbackInboxSourceOnly => '仅源卡组可查看贡献收件箱';

  @override
  String get apiServerListFeedback => '无法加载反馈，请重试';

  @override
  String get apiInvalidFeedbackStatus => '反馈状态无效';

  @override
  String get apiFeedbackNotFound => '贡献不存在';

  @override
  String get apiServerUpdateFeedback => '无法更新反馈，请重试';

  @override
  String get apiProposedEntriesRequiredAccept => '接受反馈需要提供建议条目';

  @override
  String get apiFactNotOnSourceDeck => '源卡组中找不到该词条';

  @override
  String get apiReportCannotBeAccepted => '无法接受贡献反馈';

  @override
  String get apiServerAcceptFeedback => '无法接受反馈，请重试';

  @override
  String get apiBadCertificate => '安全连接失败';

  @override
  String get apiBadResponse => '服务器响应异常';

  @override
  String get apiRequestCancel => '请求已取消';

  @override
  String get apiUnknownError => '发生意外错误';

  @override
  String get errorServerError => '出了点问题，请稍后再试。';

  @override
  String apiFactEntryRequired(int index) {
    return '词条 $index：至少需要一个条目';
  }

  @override
  String apiFactEntryContent(int index) {
    return '词条 $index：每个条目需要文字、音频、图片、视频或 JSON';
  }

  @override
  String get apiInvalidTemplate => '此词条的卡片模板无效';

  @override
  String apiNegativeInterval(String factId) {
    return '此卡片异常，请尝试删除词条 $factId';
  }

  @override
  String apiUnsupportedMediaMime(String mime) {
    return '不支持的文件类型：$mime';
  }

  @override
  String get apiInvalidTargetVersion => '目标版本无效';

  @override
  String get errorSubmitCardFailed => '无法保存卡片进度，请重试';

  @override
  String get deckCheckUpdates => '检查更新';

  @override
  String get deckSyncNow => '立即同步';

  @override
  String get deckUpToDate => '已是最新版本';

  @override
  String get deckSyncSuccess => '卡组已同步';

  @override
  String deckUpdatesVersion(int source, int latest) {
    return '当前版本 v$source -> 最新版本 v$latest';
  }

  @override
  String deckUpdatesCounts(int added, int edited, int removed, int media) {
    return '新增 $added，修改 $edited，删除 $removed，媒体变更 $media';
  }

  @override
  String get feedbackSubmit => '提交反馈';

  @override
  String get feedbackMessageHint => '描述这个词条的问题';

  @override
  String get feedbackMessageRequired => '请输入反馈内容';

  @override
  String get feedbackSubmitSuccess => '反馈已提交';

  @override
  String get factEditNoEntries => '该词条没有可编辑内容';
}
