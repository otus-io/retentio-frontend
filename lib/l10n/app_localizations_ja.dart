// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Rete';

  @override
  String appVersionLabel(String appName, String version) {
    return '$appName v$version';
  }

  @override
  String get login => 'ログイン';

  @override
  String get register => '登録';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get username => 'ユーザー名';

  @override
  String get password => 'パスワード';

  @override
  String get loginPageTitle => 'ログイン';

  @override
  String get loginTagline => '千里の道も一歩から';

  @override
  String get registerPageTitle => 'アカウントを作成';

  @override
  String get registerPageSubtitle => '長期記憶デッキを作り始めましょう';

  @override
  String get email => 'メールアドレス';

  @override
  String get confirmPassword => 'パスワード（確認）';

  @override
  String get pleaseFillAllFields => 'すべての項目を入力してください';

  @override
  String get passwordNotMatch => 'パスワードが一致しません';

  @override
  String get registerSuccess => '登録が完了しました';

  @override
  String get loginSuccess => 'ログインしました';

  @override
  String get loginFailed => 'ログインに失敗しました';

  @override
  String get backToLogin => 'ログインに戻る';

  @override
  String get resetPassword => 'パスワードをリセット';

  @override
  String get resetPasswordSent => 'アカウントが存在する場合、リセットリンクを送信しました。';

  @override
  String get home => 'ホーム';

  @override
  String get decks => 'デッキ';

  @override
  String get deckListSubtitle => 'あなたの学習デッキ';

  @override
  String get profile => 'プロフィール';

  @override
  String get noDecksAvailable => 'デッキがありません';

  @override
  String get retry => '再試行';

  @override
  String get words => '単語';

  @override
  String get progress => 'カバー率';

  @override
  String get cards => 'カード';

  @override
  String get newCards => '新規';

  @override
  String get totalReviews => '総復習数';

  @override
  String get review => '復習';

  @override
  String get facts => '項目';

  @override
  String openDeck(String deckName) {
    return 'デッキを開く：$deckName';
  }

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirmTitle => 'ログアウト';

  @override
  String get logoutConfirmMessage => 'ログアウトしますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get changeLanguage => '言語を変更';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageJapaneseShort => '日';

  @override
  String get languageEnglishShort => 'EN';

  @override
  String get languageChineseShort => '中';

  @override
  String get changeTheme => 'テーマを変更';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get switchToLightMode => 'ライトモードに切り替え';

  @override
  String get switchToDarkMode => 'ダークモードに切り替え';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeSepia => 'セピア';

  @override
  String get totalCards => '合計';

  @override
  String get dueCards => '要復習';

  @override
  String get todaysDue => '今日の要復習';

  @override
  String get learned => '学習済み';

  @override
  String get noCardsInDeck => 'このデッキにカードがありません';

  @override
  String get startLearning => '学習を開始';

  @override
  String get allCaughtUp => 'すべて完了しました！';

  @override
  String get noCardsForTagFilter => 'このタグのカードはありません';

  @override
  String noCardsForTagFilterNamed(String tagName) {
    return 'タグ「$tagName」のカードはありません';
  }

  @override
  String get clearTagFilter => 'フィルターをクリア';

  @override
  String startLearningDeck(String deckName) {
    return '学習を開始：$deckName';
  }

  @override
  String get showAnswer => '答えを表示';

  @override
  String get hard => '難しい';

  @override
  String get good => '普通';

  @override
  String get easy => '簡単';

  @override
  String get backToDeck => 'デッキに戻る';

  @override
  String get viewCards => '一覧';

  @override
  String get learnButton => '学習';

  @override
  String get manage => '管理';

  @override
  String get createDeck => 'デッキを作成';

  @override
  String get createInputDeckName => 'デッキ名';

  @override
  String get createInputDeckNameHint => 'デッキ名を入力してください';

  @override
  String get deckEditorFieldHint => '例：英語';

  @override
  String get deckEditorFieldHintSecond => '例：日本語';

  @override
  String get deckEditorAddFieldTooltip => '列見出しを追加';

  @override
  String get deckCreateAddField => 'フィールドを追加';

  @override
  String get deckEditorRemoveFieldTooltip => '列見出しを削除';

  @override
  String get deckEditorNameRequired => 'デッキ名を入力してください';

  @override
  String get deckEditorMinTwoFields => '列見出しをもう1つ追加してください（最低2列必要）';

  @override
  String get deckEditorFieldNamesRequired => 'すべての列見出しを入力してください';

  @override
  String get language => '言語';

  @override
  String get rate => 'ペース';

  @override
  String get cardsPerDay => '枚の新規カード/日';

  @override
  String get slow => '遅い';

  @override
  String get fast => '速い';

  @override
  String get unidirectional => '一方向';

  @override
  String get bidirectional => '双方向';

  @override
  String get template => 'テンプレート';

  @override
  String get next => '次へ';

  @override
  String get noNetworkConnection => 'ネットワークに接続できません。インターネット設定を確認してください。';

  @override
  String get reviewAgain => 'もう一度復習';

  @override
  String get editDeck => 'デッキを編集';

  @override
  String get editFact => '項目を編集';

  @override
  String get hideCard => 'カードを非表示';

  @override
  String get deleteCard => 'カードを削除';

  @override
  String get deleteCardConfirm => 'このカードのみ削除されます。対応する項目とその他のカードはデッキに残ります。';

  @override
  String get deleteCardFailed => 'カードを削除できませんでした';

  @override
  String get deleteDeck => 'デッキを削除';

  @override
  String deleteDeckConfirm(String deckName) {
    return '「$deckName」とそのすべてのカード・項目が完全に削除されます。';
  }

  @override
  String get noCardsInThisDeck => 'このデッキにカードがありません';

  @override
  String get save => '保存';

  @override
  String newCardEveryMinutes(int interval) {
    return '$interval分ごとに新しいカードを追加';
  }

  @override
  String get addFact => '項目を追加';

  @override
  String get addFactAddRow => '行を追加';

  @override
  String get addFactRemoveRow => '行を削除';

  @override
  String get addFactFieldNameHint => 'フィールド名（任意）';

  @override
  String get addFactContentHint => 'テキスト（メディアを追加する場合は省略可）';

  @override
  String get addFactAttachImage => '画像';

  @override
  String get addFactAttachVideo => '動画';

  @override
  String get addFactAttachAudio => '音声';

  @override
  String get addFactClearAttachment => 'クリア';

  @override
  String get addFactAttachMediaTooltip => '画像・動画・音声を添付。長押しで削除。';

  @override
  String get addFactGalleryMediaTooltip => 'ライブラリから写真または動画を選択。長押しで削除。';

  @override
  String get addFactRecordAudioTooltip => 'マイクで録音。もう一度タップで停止して添付。録音中に長押しで破棄。';

  @override
  String get addFactStopRecordingTooltip => '録音を停止してこのフィールドに音声を添付';

  @override
  String get addFactMicPermissionDenied => '録音にはマイクへのアクセスが必要です。';

  @override
  String get addFactRecordingFailed => '録音できませんでした。もう一度お試しください。';

  @override
  String get addFactSubmit => '項目を保存';

  @override
  String get addFactUploadFailed => 'アップロードに失敗しました。もう一度お試しください。';

  @override
  String addFactFileTooLarge(int maxMb) {
    return 'ファイルが大きすぎます（最大 $maxMb MB）。';
  }

  @override
  String get addFactEntryNeedsContent => '各行にはテキストまたは少なくとも1つの添付が必要です。';

  @override
  String get addFactFileTypeNotSupported => 'このファイル形式はサポートされていません。';

  @override
  String get addFactFileWrongSlot => 'この添付タイプに合うファイルを選択してください。';

  @override
  String get addFactFailed => '項目を追加できませんでした';

  @override
  String get addFactSuccess => '項目を追加しました';

  @override
  String addFactFieldFallback(int number) {
    return 'フィールド $number';
  }

  @override
  String get addFactFieldShortLabel => 'フィールド';

  @override
  String get addFactPasteFromClipboard => 'クリップボードから貼り付け';

  @override
  String get cardAudioUnavailable => '音声を再生できません';

  @override
  String get font => 'フォント';

  @override
  String get deckFontSheetTitle => 'フォントとルビ';

  @override
  String get deckFontMainSizeLabel => '本文のサイズ';

  @override
  String get deckFontRubySizeLabel => 'ルビのサイズ';

  @override
  String get deckFontPreviewCaption => 'プレビュー';

  @override
  String get deckFontTabFront => '表面';

  @override
  String get deckFontTabBack => '裏面';

  @override
  String get tags => 'タグ';

  @override
  String get tagLabel => 'タグ';

  @override
  String get addTag => 'タグを追加';

  @override
  String get createTag => 'タグを作成';

  @override
  String get editTag => 'タグを編集';

  @override
  String get deleteTag => 'タグを削除';

  @override
  String get tagName => 'タグ名';

  @override
  String get tagDescription => '説明（任意）';

  @override
  String get tagNameHint => '例：文法、動詞…';

  @override
  String get tagNameRequired => 'タグ名を入力してください';

  @override
  String get tagCreated => 'タグを作成しました';

  @override
  String get tagUpdated => 'タグを更新しました';

  @override
  String get tagDeleted => 'タグを削除しました';

  @override
  String get tagCreateFailed => 'タグを作成できませんでした';

  @override
  String get tagUpdateFailed => 'タグを更新できませんでした';

  @override
  String get tagDeleteFailed => 'タグを削除できませんでした';

  @override
  String get tagAlreadyExists => '同じ名前のタグが既に存在します';

  @override
  String get tagLimitReached => 'タグの上限（1000個）に達しました';

  @override
  String get noTags => 'タグがありません';

  @override
  String get manageTags => 'タグを管理';

  @override
  String get tagPickerTitle => 'タグを選択';

  @override
  String get tagPickerSearchHint => 'タグを検索…';

  @override
  String get tagPickerDone => '完了';

  @override
  String tagPickerNoMatch(String query) {
    return '「$query」に一致するタグはありません';
  }

  @override
  String get tagPickerEmptyHint => 'タグがありません。下をタップして最初のタグを作成してください。';

  @override
  String get filterAll => 'すべて';

  @override
  String get studyTagFilterTitle => 'タグで復習';

  @override
  String get tagFacts => '項目';

  @override
  String get noFactsInTag => 'このタグにはまだ項目がありません';

  @override
  String get discoveryTab => '発見';

  @override
  String get discoverySearchHint => 'デッキ、作者、タグを検索';

  @override
  String get discoveryFilterLatest => '最新';

  @override
  String get discoveryFilterFavorites => 'お気に入り';

  @override
  String get discoveryEmpty => '公開デッキはまだありません';

  @override
  String get discoveryFavoritesEmpty => 'お気に入りのデッキはありません';

  @override
  String get discoveryImport => 'インポート';

  @override
  String get discoveryImporting => 'インポート中…';

  @override
  String get discoveryImported => 'インポート済み';

  @override
  String get discoveryGoStudy => '学習する';

  @override
  String get discoveryImportSuccess => 'デッキに追加しました';

  @override
  String get discoveryFavorite => 'お気に入り';

  @override
  String get discoveryUnfavorite => 'お気に入り解除';

  @override
  String discoveryYearsAgo(int count) {
    return '$count年前';
  }

  @override
  String discoveryMonthsAgo(int count) {
    return '$countか月前';
  }

  @override
  String discoveryDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String discoveryHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String get discoveryJustNow => 'たった今';

  @override
  String get discoveryDeckUnavailable => '利用不可';

  @override
  String discoveryCardSemantics(String name, String factCount, String owner) {
    return '$name、$factCount、作者 $owner';
  }

  @override
  String get discoveryImportedBadgeSemantics => 'マイデッキにインポート済み';

  @override
  String get discoveryUnavailableBadgeSemantics => 'このデッキは利用できません';

  @override
  String discoveryLoginToAccessTab(String tabLabel) {
    return '$tabLabelを使うにはログインしてください。';
  }

  @override
  String get deckOptionsTooltip => 'デッキオプション';

  @override
  String get discoveryNotFound => 'デッキが見つからないか、利用できなくなりました';

  @override
  String get discoveryImportSelf => '自分のデッキはインポートできません';

  @override
  String get discoveryImportDuplicate => 'このデッキは既にインポート済みです';

  @override
  String get discoveryImportFailed => 'インポートに失敗しました。もう一度お試しください。';

  @override
  String get discoveryLoginToImport => 'インポートするにはログインしてください';

  @override
  String get discoveryRetry => '再試行';

  @override
  String get publishDeck => 'デッキを公開';

  @override
  String get publishDeckHint => '公開すると、「発見」タブで他のユーザーがデッキを見つけてインポートできます。';

  @override
  String get publishDeckAction => '公開';

  @override
  String get publishingDeck => '公開中…';

  @override
  String get publishDeckSuccess => '公開しました！';

  @override
  String get publishDeckFailed => '公開に失敗しました。もう一度お試しください。';

  @override
  String get publishDeckAlreadyPublished => '公開済み';

  @override
  String get publishDeckUpdate => '公開バージョンを更新';

  @override
  String get errorUnknown => '予期しないエラーが発生しました';

  @override
  String get authInvalidCredentials => 'ユーザー名またはパスワードが正しくありません';

  @override
  String get authUsernameAlreadyExists => 'このユーザー名は既に使われています';

  @override
  String get authEmailAlreadyInUse => 'このメールアドレスは既に登録されています';

  @override
  String get authSessionExpired => 'セッションの有効期限が切れました。再度ログインしてください。';

  @override
  String get authTokenRequired => '続行するにはログインしてください';

  @override
  String get authResetTokenInvalid => 'リセットリンクが無効か、期限切れです';

  @override
  String get errorLoginFailed => 'ログインに失敗しました。もう一度お試しください。';

  @override
  String get errorRegisterFailed => '登録に失敗しました。もう一度お試しください。';

  @override
  String get errorPublishedDeckCannotDelete => '公開済みのデッキは削除できません';

  @override
  String get errorNoChangesToPublish => '公開する変更がありません';

  @override
  String get errorSourceDeckNotImportable => 'このデッキはインポートできません';

  @override
  String get errorCannotImportImportedDeck => '既にインポートしたデッキを再インポートできません';

  @override
  String get errorSourceDeckNotPublished => 'このデッキはまだ公開されていません';

  @override
  String get errorCannotModifyImportedDeck => 'インポートしたデッキは変更できません';

  @override
  String get discoveryDetailFields => 'フィールド';

  @override
  String get discoveryDetailDescription => '説明';

  @override
  String discoveryDetailFactCount(int count) {
    return '$count枚';
  }

  @override
  String get imageLoadFailed => '画像を読み込めませんでした';

  @override
  String get homeDailyGoal => '毎日の目標';

  @override
  String get homeLearningPath => '学習パス';

  @override
  String get homeToday => '今日';

  @override
  String get homeTodayFocus => '今日の重点';

  @override
  String get homeTodayFocusText => 'まず復習を1ラウンド終えてから、学習ノートから新しい項目を追加しましょう。';

  @override
  String get apiUserNotFound => 'ユーザーが見つかりません';

  @override
  String get apiInvalidRequestPayload => 'リクエストが無効です。もう一度お試しください。';

  @override
  String get apiDeckNotFound => 'デッキが見つかりません';

  @override
  String get apiNotAuthorizedAccessDeck => 'このデッキへのアクセス権限がありません';

  @override
  String get apiNotAuthorizedModifyDeck => 'このデッキを変更する権限がありません';

  @override
  String get apiNotAuthorizedDeleteDeck => 'このデッキを削除する権限がありません';

  @override
  String get apiNotAuthorized => 'この操作を行う権限がありません';

  @override
  String get apiServerRetrieveDeck => 'デッキを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerParseDeck => 'デッキデータが不正です。もう一度お試しください。';

  @override
  String get apiRegisterFieldsRequired => 'ユーザー名、パスワード、メールが必要です';

  @override
  String get apiLoginFieldsRequired => 'ユーザー名とパスワードが必要です';

  @override
  String get apiServerCheckUsername => 'ユーザー名を確認できませんでした。もう一度お試しください。';

  @override
  String get apiServerCheckEmail => 'メールを確認できませんでした。もう一度お試しください。';

  @override
  String get apiServerHashPassword => 'パスワードを処理できませんでした。もう一度お試しください。';

  @override
  String get apiServerSerializeUser => 'ユーザーデータを保存できませんでした。もう一度お試しください。';

  @override
  String get apiServerCreateUser => 'アカウントを作成できませんでした。もう一度お試しください。';

  @override
  String get apiServerRetrieveUser => 'ユーザーデータを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerParseUser => 'ユーザーデータが不正です。もう一度お試しください。';

  @override
  String get apiServerGenerateToken => 'ログインできませんでした。もう一度お試しください。';

  @override
  String get apiServerLogout => 'ログアウトできませんでした。もう一度お試しください。';

  @override
  String get apiEmailRequired => 'メールが必要です';

  @override
  String get apiServerGenerateResetToken => 'リセットメールを送信できませんでした。もう一度お試しください。';

  @override
  String get apiServerStoreResetToken => 'リセットリクエストを処理できませんでした。もう一度お試しください。';

  @override
  String get apiResetFieldsRequired => 'リセットトークンと新しいパスワードが必要です';

  @override
  String get apiServerValidateResetToken => 'リセットリンクを検証できませんでした。もう一度お試しください。';

  @override
  String get apiServerResetPassword => 'パスワードをリセットできませんでした。もう一度お試しください。';

  @override
  String get apiServerRetrieveProfile => 'プロフィールを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiDeckNameRequired => 'デッキ名が必要です';

  @override
  String get apiDeckFieldsRequired => '少なくとも1つの列名が必要です';

  @override
  String get apiDeckFieldNameEmpty => '列名を空にすることはできません';

  @override
  String get apiDeckRateRequired => '1日の新規カード数は1〜1000の間である必要があります';

  @override
  String get apiTagsOrTagIds => 'タグ名またはタグIDのどちらか一方のみを指定してください';

  @override
  String get apiDeckDescriptionInvalidChars => 'デッキ説明に無効な文字が含まれています';

  @override
  String get apiDeckDescriptionTooLong => 'デッキ説明は最大500文字です';

  @override
  String get apiTagIdRequired => 'タグIDが必要です';

  @override
  String get apiMaxTagsPerDeck => 'デッキのタグ数が上限に達しました';

  @override
  String get apiTagNameRequired => 'タグ名が必要です';

  @override
  String get apiTagNameInvalidChars => 'タグ名に無効な文字が含まれています';

  @override
  String get apiTagNameTooLong => 'タグ名が長すぎます（最大50文字）';

  @override
  String get apiTagNotFound => 'タグが見つかりません';

  @override
  String get apiServerResolveDeckTags => 'デッキタグを解決できませんでした。もう一度お試しください。';

  @override
  String get apiServerGenerateDeckId => 'デッキを作成できませんでした。もう一度お試しください。';

  @override
  String get apiServerMarshalDeck => 'デッキを保存できませんでした。もう一度お試しください。';

  @override
  String get apiServerCreateDeck => 'デッキを作成できませんでした。もう一度お試しください。';

  @override
  String get apiServerPrepareDeckMedia => 'メディアストレージを準備できませんでした。もう一度お試しください。';

  @override
  String get apiDeckRateRange => '1日の新規カード数は1〜1000の間である必要があります';

  @override
  String get apiInvalidVisibility => '公開設定が無効です';

  @override
  String get apiCannotChangeVisibilityAfterPublish => '公開後は公開設定を変更できません';

  @override
  String get apiCannotChangeVisibilityImported => 'インポートしたデッキの公開設定は変更できません';

  @override
  String get apiCannotChangeFieldsImported => 'インポートしたデッキのフィールドは変更できません';

  @override
  String get apiCannotChangeNameImported => 'インポートしたデッキの名前は変更できません';

  @override
  String get apiCannotChangeDescriptionImported => 'インポートしたデッキの説明は変更できません';

  @override
  String get apiImportedDeckRateRequired => 'インポートデッキの更新には1日の新規カード数が必要です';

  @override
  String get apiServerSerializeDeck => 'デッキを保存できませんでした。もう一度お試しください。';

  @override
  String get apiServerLoadCards => 'カードを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerRescheduleCards => 'カードを再スケジュールできませんでした。もう一度お試しください。';

  @override
  String get apiServerUpdateDeckCards => 'デッキを更新できませんでした。もう一度お試しください。';

  @override
  String get apiServerUpdateDeck => 'デッキを更新できませんでした。もう一度お試しください。';

  @override
  String get apiServerLoadFactsDelete => 'デッキを削除できませんでした。もう一度お試しください。';

  @override
  String get apiServerCleanupTags => 'デッキを削除できませんでした。もう一度お試しください。';

  @override
  String get apiServerDeleteDeck => 'デッキを削除できませんでした。もう一度お試しください。';

  @override
  String get apiServerRevokeMediaGrants => 'デッキを削除できませんでした。もう一度お試しください。';

  @override
  String get apiServerRetrieveDecks => 'デッキ一覧を読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerRetrieveDeckData => 'デッキを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerListCatalog => 'カタログを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerLoadCatalogDeck => 'デッキ詳細を読み込めませんでした。もう一度お試しください。';

  @override
  String get apiFirstPublishPublic => '初回公開は公開設定である必要があります';

  @override
  String get apiCannotPublishImported => 'インポートしたデッキは公開できません';

  @override
  String get apiSourceDeckIdRequired => 'ソースデッキIDが必要です';

  @override
  String get apiMaxFactTagsPerDeck => '項目タグ数が上限に達しました';

  @override
  String get apiUpdatesImportedOnly => '更新はインポートしたデッキでのみ利用できます';

  @override
  String get apiNotImportedDeck => 'これはインポートしたデッキではありません';

  @override
  String get apiSourceDeckMissing => 'ソースデッキが存在しません';

  @override
  String get apiFactsArrayRequired => '項目データが必要です';

  @override
  String get apiInvalidFactOperation =>
      '無効な操作です。対応：append、prepend、shuffle、spread';

  @override
  String get apiDeckRateMinForFacts => '項目を追加する前に、1日の新規カード数を1以上に設定してください';

  @override
  String get apiAtLeastOneFact => '少なくとも1つの項目が必要です';

  @override
  String get apiTemplateInvalid => 'カードテンプレートが無効です';

  @override
  String get apiEntryContentRequired => '各エントリにはテキスト、音声、画像、動画、またはJSONが必要です';

  @override
  String get apiFactNotFound => '項目が見つかりません';

  @override
  String get apiServerAddFacts => '項目を追加できませんでした。もう一度お試しください。';

  @override
  String get apiServerMergeFacts => '項目を追加できませんでした。もう一度お試しください。';

  @override
  String get apiServerSerializeFact => '項目を保存できませんでした。もう一度お試しください。';

  @override
  String get apiServerRebuildTemplate => 'カードを更新できませんでした。もう一度お試しください。';

  @override
  String get apiServerRetrieveCards => 'カードを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerSerializeCard => 'カードを保存できませんでした。もう一度お試しください。';

  @override
  String get apiServerUpdateFact => '項目を更新できませんでした。もう一度お試しください。';

  @override
  String get apiServerRemoveFactTags => '項目を更新できませんでした。もう一度お試しください。';

  @override
  String get apiServerRemoveFact => '項目を削除できませんでした。もう一度お試しください。';

  @override
  String get apiServerDeleteFact => '項目を削除できませんでした。もう一度お試しください。';

  @override
  String get apiServerRetrieveFacts => '項目を読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerRetrieveFactTags => '項目タグを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerCheckFact => '項目を確認できませんでした。もう一度お試しください。';

  @override
  String get apiInvalidUsedOnFilter => 'フィルター値が無効です';

  @override
  String get apiUsedOnRequired => 'デッキIDを設定する場合はフィルタータイプが必要です';

  @override
  String get apiDeckIdRequiredForFact => '項目フィルターにはデッキIDが必要です';

  @override
  String get apiServerRetrieveTags => 'タグを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiServerCheckTags => 'タグを確認できませんでした。もう一度お試しください。';

  @override
  String get apiServerCheckTagName => 'タグ名を確認できませんでした。もう一度お試しください。';

  @override
  String get apiServerGenerateTagId => 'タグを作成できませんでした。もう一度お試しください。';

  @override
  String get apiServerCreateTag => 'タグを作成できませんでした。もう一度お試しください。';

  @override
  String get apiServerSerializeTag => 'タグを保存できませんでした。もう一度お試しください。';

  @override
  String get apiServerSaveTag => 'タグを保存できませんでした。もう一度お試しください。';

  @override
  String get apiServerAssociateTag => 'タグを追加できませんでした。もう一度お試しください。';

  @override
  String get apiServerRemoveTag => 'タグを削除できませんでした。もう一度お試しください。';

  @override
  String get apiServerLoadTags => 'タグを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiFactIdRequired => '項目IDが必要です';

  @override
  String get apiTemplateRequired => 'カードテンプレートが必要です';

  @override
  String get apiTemplateExists => 'この項目には既にテンプレートがあります';

  @override
  String get apiCardNotFound => 'カードが見つかりません';

  @override
  String get apiCardIdRequired => 'カードIDが必要です';

  @override
  String get apiCardIdEmpty => 'カードIDを空にすることはできません';

  @override
  String get apiIntervalOrHiddenRequired => 'intervalまたはhiddenフィールドを指定してください';

  @override
  String get apiIntervalAndHiddenConflict =>
      '1つのリクエストでintervalとhiddenの両方を送信できません';

  @override
  String get apiLastReviewRequired => '間隔の更新にはlast_reviewが必要です';

  @override
  String get apiLastReviewIntervalOnly => 'last_reviewは間隔の更新でのみ有効です';

  @override
  String get apiLastReviewNumeric => 'last_reviewは数値のUnixタイムスタンプである必要があります';

  @override
  String get apiLastReviewWhole => 'last_reviewは整数のUnixタイムスタンプである必要があります';

  @override
  String get apiLastReviewPositive => 'last_reviewは正のUnixタイムスタンプである必要があります';

  @override
  String get apiIntervalNumeric => 'intervalは数値である必要があります';

  @override
  String get apiIntervalPositive => 'intervalは正の数である必要があります';

  @override
  String get apiHiddenBoolean => 'hiddenは真偽値である必要があります';

  @override
  String get apiUnsupportedCardOperation => '対応する操作：interval、visibility';

  @override
  String get apiCardTemplateInvalidForFact => 'この項目のカードテンプレートが無効です';

  @override
  String get apiServerUpdateCardRedis => 'カードを更新できませんでした。もう一度お試しください。';

  @override
  String get apiServerCheckCardMembership => 'カードを確認できませんでした。もう一度お試しください。';

  @override
  String get apiServerParseCard => 'カードデータが不正です。もう一度お試しください。';

  @override
  String get apiServerUpdateCard => 'カードを更新できませんでした。もう一度お試しください。';

  @override
  String get apiServerCheckCard => 'カードを確認できませんでした。もう一度お試しください。';

  @override
  String get apiServerDeleteCard => 'カードを削除できませんでした。もう一度お試しください。';

  @override
  String get apiServerGenerateCardId => 'カードを作成できませんでした。もう一度お試しください。';

  @override
  String get apiServerMergeCard => 'カードを追加できませんでした。もう一度お試しください。';

  @override
  String get apiServerAddCard => 'カードを追加できませんでした。もう一度お試しください。';

  @override
  String get apiServerParseFact => '項目データが不正です。もう一度お試しください。';

  @override
  String get apiInvalidMultipart => 'ファイルアップロードが無効です';

  @override
  String get apiMissingFileField => 'ファイルが選択されていないか、ファイルフィールドが無効です';

  @override
  String get apiMediaDeckIdRequired => 'メディアのアップロードにはデッキIDが必要です';

  @override
  String get apiClientIdInUse => 'アップロードIDは既に使用されています。もう一度お試しください。';

  @override
  String get apiFileTooLarge => 'ファイルが大きすぎます';

  @override
  String get apiUnsupportedMediaType => 'サポートされていないファイル形式です';

  @override
  String get apiInvalidJsonDocument => 'JSONファイルが無効です';

  @override
  String get apiMediaStorageNotConfigured => 'メディアストレージを利用できません';

  @override
  String get apiFailedCheckClientId => 'アップロードに失敗しました。もう一度お試しください。';

  @override
  String get apiFailedVerifyDeck => 'デッキを確認できませんでした。もう一度お試しください。';

  @override
  String get apiFailedReadFile => 'ファイルを読み取れませんでした。もう一度お試しください。';

  @override
  String get apiFailedGenerateId => 'アップロードに失敗しました。もう一度お試しください。';

  @override
  String get apiFailedPrepareMedia => 'アップロードに失敗しました。もう一度お試しください。';

  @override
  String get apiFailedStoreFile => 'ファイルを保存できませんでした。もう一度お試しください。';

  @override
  String get apiFailedSaveMetadata => 'ファイル情報を保存できませんでした。もう一度お試しください。';

  @override
  String get apiMediaVersionRequired => 'このメディアにはバージョンパラメータが必要です';

  @override
  String get apiAccessDenied => 'アクセスが拒否されました';

  @override
  String get apiMediaNotFound => 'メディアが見つかりません';

  @override
  String get apiMediaFileNotFound => 'メディアファイルが見つかりません';

  @override
  String get apiFailedListMedia => 'メディアを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiFailedLoadMedia => 'メディアを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiFeedbackImportedOnly => '貢献はインポートしたデッキでのみ利用できます';

  @override
  String get apiFeedbackSourceNotPublished => 'ソースデッキが公開されていません';

  @override
  String get apiFeedbackMessageLength => 'メッセージは1〜2000文字である必要があります';

  @override
  String get apiEntryIndexOutOfRange => 'エントリのインデックスが範囲外です';

  @override
  String get apiProposedEntriesContent => '提案エントリに内容が必要です';

  @override
  String get apiProposedEntriesLength => '提案エントリの数は項目と一致する必要があります';

  @override
  String get apiProposedEntriesDiffer => '提案エントリは原文と異なる必要があります';

  @override
  String get apiFactNotInSnapshot => '項目が固定スナップショットにありません';

  @override
  String get apiFeedbackDeckNotFound => 'デッキが見つかりません';

  @override
  String get apiFeedbackFactNotFound => '項目が見つかりません';

  @override
  String get apiFeedbackDailyLimit => '今日の貢献上限に達しました。明日もう一度お試しください。';

  @override
  String get apiServerSubmitFeedback => 'フィードバックを送信できませんでした。もう一度お試しください。';

  @override
  String get apiFeedbackInboxSourceOnly => '貢献受信箱はソースデッキでのみ利用できます';

  @override
  String get apiServerListFeedback => 'フィードバックを読み込めませんでした。もう一度お試しください。';

  @override
  String get apiInvalidFeedbackStatus => 'フィードバックのステータスが無効です';

  @override
  String get apiFeedbackNotFound => '貢献が見つかりません';

  @override
  String get apiServerUpdateFeedback => 'フィードバックを更新できませんでした。もう一度お試しください。';

  @override
  String get apiProposedEntriesRequiredAccept => 'フィードバックを受け入れるには提案エントリが必要です';

  @override
  String get apiFactNotOnSourceDeck => 'ソースデッキにその項目が見つかりません';

  @override
  String get apiReportCannotBeAccepted => '報告フィードバックは受け入れられません';

  @override
  String get apiServerAcceptFeedback => 'フィードバックを受け入れられませんでした。もう一度お試しください。';

  @override
  String get apiBadCertificate => '安全な接続に失敗しました';

  @override
  String get apiBadResponse => 'サーバーの応答が異常です';

  @override
  String get apiRequestCancel => 'リクエストがキャンセルされました';

  @override
  String get apiUnknownError => '予期しないエラーが発生しました';

  @override
  String get errorServerError => '問題が発生しました。しばらくしてからもう一度お試しください。';

  @override
  String apiFactEntryRequired(int index) {
    return '項目 $index：少なくとも1つのエントリが必要です';
  }

  @override
  String apiFactEntryContent(int index) {
    return '項目 $index：各エントリにはテキスト、音声、画像、動画、またはJSONが必要です';
  }

  @override
  String get apiInvalidTemplate => 'この項目のカードテンプレートが無効です';

  @override
  String apiNegativeInterval(String factId) {
    return 'このカードに問題があります。項目 $factId の削除を試してください。';
  }

  @override
  String apiUnsupportedMediaMime(String mime) {
    return 'サポートされていないファイル形式：$mime';
  }

  @override
  String get apiInvalidTargetVersion => 'ターゲットバージョンが無効です';

  @override
  String get errorSubmitCardFailed => 'カードの進捗を保存できませんでした。もう一度お試しください。';

  @override
  String get deckCheckUpdates => '更新を確認';

  @override
  String get deckSyncNow => '今すぐ同期';

  @override
  String get deckUpToDate => '最新です';

  @override
  String get deckSyncSuccess => 'デッキを同期しました';

  @override
  String deckUpdatesVersion(int source, int latest) {
    return '現在 v$source → 最新 v$latest';
  }

  @override
  String deckUpdatesCounts(int added, int edited, int removed, int media) {
    return '追加 $added、編集 $edited、削除 $removed、メディア変更 $media';
  }

  @override
  String get feedbackSubmit => 'フィードバックを送信';

  @override
  String get feedbackMessageHint => 'この項目の問題を説明してください';

  @override
  String get feedbackMessageRequired => 'フィードバック内容を入力してください';

  @override
  String get feedbackSubmitSuccess => 'フィードバックを送信しました';

  @override
  String get reportIssue => '問題を報告';

  @override
  String get reportIssueCategory => '問題の種類';

  @override
  String get reportIssueAudio => '音声';

  @override
  String get reportIssueContent => '内容';

  @override
  String get reportIssueOther => 'その他';

  @override
  String get reportIssueDetailsHint => '詳細を追加（任意）';

  @override
  String get reportIssueOtherHint => '問題を説明してください';

  @override
  String get reportIssueDetailsRequired => '問題を説明してください';

  @override
  String get reportIssueSubmit => '送信';

  @override
  String get reportIssueSuccess => '問題を報告しました';

  @override
  String get factEditNoEntries => 'この項目には編集可能な内容がありません';

  @override
  String deckUpdatesAddedSection(int count) {
    return '追加された項目（$count）';
  }

  @override
  String deckUpdatesRemovedSection(int count) {
    return '削除された項目（$count）';
  }

  @override
  String deckUpdatesEditedSection(int count) {
    return '編集された項目（$count）';
  }

  @override
  String deckUpdatesMediaSection(int count) {
    return 'メディア変更（$count）';
  }

  @override
  String deckUpdatesTemplatesSection(int count) {
    return 'カードテンプレート変更（$count）';
  }

  @override
  String get deckUpdatesAccept => '承認';

  @override
  String get deckUpdatesKeepLocal => '拒否';

  @override
  String get deckUpdatesAligned => '揃っています';

  @override
  String get deckUpdatesLocalOverlay => 'ローカルオーバーレイ';

  @override
  String get deckUpdatesKeepHint => 'ローカルオーバーレイあり';

  @override
  String get deckUpdatesAcceptHint => 'デフォルトで承認';

  @override
  String get deckUpdatesBefore => '更新前';

  @override
  String get deckUpdatesAfter => '更新後';

  @override
  String get deckUpdatesReviewChanges => '変更を確認';

  @override
  String get deckUpdatesHideReview => 'レビューを非表示';

  @override
  String get contributeFactEdit => '作者に編集を提出';

  @override
  String get contributeFactEditSuccess => '編集を作者に提出しました';

  @override
  String get contributeFactTags => 'タグ変更を提出';

  @override
  String get contributeFactTagsSuccess => 'タグ変更を提出しました';

  @override
  String get contributeNoTagChanges => '提出する前にタグを変更してください';

  @override
  String get contributeOptionalMessageHint => '作者への任意メッセージ';

  @override
  String get contributionsInbox => '貢献受信箱';

  @override
  String get contributionsEmpty => '未処理の貢献はありません';

  @override
  String get contributionsAccept => '承認';

  @override
  String get contributionsDismiss => '却下';

  @override
  String get contributionsResolve => '解決済みにする';

  @override
  String get contributionsAccepted => '貢献を承認しました';

  @override
  String get contributionsUpdated => '貢献の状態を更新しました';

  @override
  String get contributionsLoadMore => 'さらに読み込む';

  @override
  String get contributionsBefore => '変更前';

  @override
  String get contributionsAfter => '変更後';

  @override
  String get contributionsProposed => '提案内容';

  @override
  String get contributionsReported => '報告内容';

  @override
  String get contributionsFields => '列名';

  @override
  String get contributionsTags => 'タグ';

  @override
  String get contributionsPlayBefore => '原文を再生';

  @override
  String get contributionsPlayAfter => '提案を再生';

  @override
  String tagUsageCounts(int decks, int facts) {
    return '$decks デッキ · $facts 項目';
  }

  @override
  String tagFactRefLabel(String deckId, String factId) {
    return 'デッキ $deckId · 項目 $factId';
  }

  @override
  String get pendingOutbox => '未送信の貢献';

  @override
  String get pendingOutboxHint => '作者に送れるローカル変更と、この端末から送信済みの記録です。';

  @override
  String pendingTabPending(int count) {
    return '送信待ち（$count）';
  }

  @override
  String pendingTabSent(int count) {
    return '送信済み（$count）';
  }

  @override
  String get pendingEmpty => '送信待ちはありません。インポートしたデッキで項目を編集または追加するとここに表示されます。';

  @override
  String get pendingSentEmpty => 'この端末にはまだ送信済みの記録がありません。';

  @override
  String pendingSelectAll(int count) {
    return 'すべて選択（$count）';
  }

  @override
  String get pendingSendSelected => '選択したものを送信';

  @override
  String pendingSendSelectedCount(int count) {
    return '選択したものを送信（$count）';
  }

  @override
  String get pendingDismissSelected => '選択したものを却下';

  @override
  String get pendingClearAll => 'すべてクリア';

  @override
  String get pendingStaged => '未送信の貢献に保存しました';

  @override
  String pendingSendSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の貢献を送信しました',
      one: '1件の貢献を送信しました',
    );
    return '$_temp0';
  }

  @override
  String pendingSendPartial(int sent, int failed) {
    return '$sent件を送信しました。$failed件が失敗しました';
  }

  @override
  String pendingDismissed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件を却下しました',
      one: '1件を却下しました',
    );
    return '$_temp0';
  }

  @override
  String pendingCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '送信待ち$count件をクリアしました',
      one: '送信待ち1件をクリアしました',
    );
    return '$_temp0';
  }

  @override
  String get pendingKindEdit => '項目編集';

  @override
  String get pendingKindAdd => '新規項目';

  @override
  String get pendingKindDeckTags => 'デッキタグ';

  @override
  String get pendingKindFactTags => '項目タグ';

  @override
  String get pendingKindTemplate => 'テンプレート';

  @override
  String get pendingKindFieldRename => '列名の変更';

  @override
  String get pendingKindReport => '報告';

  @override
  String get pendingNotSubmittable => '送信箱からはまだ送れません';

  @override
  String get forgotPasswordHint => 'アカウントのメールアドレスを入力すると、リセットリンクを送信します。';

  @override
  String get resetPasswordTitle => '新しいパスワードを設定';

  @override
  String get resetPasswordHint => 'アカウントの新しいパスワードを選んでください。';

  @override
  String get resetPasswordSuccess => 'パスワードをリセットしました。ログインしてください。';

  @override
  String get resetPasswordMissingToken => 'リセットリンクがないか、無効です。';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get verifyEmailTitle => 'メールアドレスを確認';

  @override
  String get verifyEmailSuccess => 'メールアドレスの確認が完了しました。';

  @override
  String get verifyEmailMissingToken => '確認リンクがないか、無効です。';

  @override
  String get verifyEmailInProgress => 'メールアドレスを確認しています…';

  @override
  String get registerSuccessCheckEmail => '登録が完了しました。確認メールを開き、アドレスを確認してください。';

  @override
  String get emailNotVerified => 'メールアドレスはまだ確認されていません。アプリは引き続き利用できます。';

  @override
  String get resendVerification => '確認メールを再送信';

  @override
  String get verificationEmailSent => 'メールが未確認の場合、確認リンクを送信しました。';

  @override
  String get authVerifyTokenInvalid => '確認リンクが無効か、期限切れです';

  @override
  String get apiTokenRequired => 'トークンが必要です';

  @override
  String get apiServerValidateVerifyToken => '確認トークンを検証できませんでした。もう一度お試しください。';

  @override
  String get apiServerVerifyEmail => 'メールを確認できませんでした。もう一度お試しください。';
}
