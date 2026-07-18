import 'package:json_annotation/json_annotation.dart';

part 'import_deck_result.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ImportDeckResult {
  const ImportDeckResult({
    required this.id,
    required this.sourceDeckId,
    required this.sourceVersion,
    required this.importedAt,
  });

  /// 导入后生成的新卡组 ID，用于跳转学习。
  final String id;
  final String sourceDeckId;
  final int sourceVersion;
  final DateTime importedAt;

  factory ImportDeckResult.fromJson(Map<String, dynamic> json) =>
      _$ImportDeckResultFromJson(json);

  Map<String, dynamic> toJson() => _$ImportDeckResultToJson(this);
}
