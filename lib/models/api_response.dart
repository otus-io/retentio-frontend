import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// Standard API envelope: `code`, `message` (as [msg]), and `data`.
@JsonSerializable()
class ApiResponse {
  ApiResponse({
    @JsonKey(defaultValue: -1) this.code = -1,
    @JsonKey(defaultValue: 'Unknown error') this.msg = 'Unknown error',
    this.data,
    @JsonKey(includeFromJson: false, includeToJson: false) this.exception,
  });

  static ApiResponse defaultResponse = ApiResponse();

  factory ApiResponse.fromJson(dynamic json) {
    if (json is! Map) {
      return ApiResponse();
    }
    final normalized = Map<String, dynamic>.from(json);
    normalized['code'] = _codeFromJson(normalized['code']);
    normalized['msg'] =
        normalized['msg']?.toString() ??
        normalized['message']?.toString() ??
        'Unknown error';
    return _$ApiResponseFromJson(normalized);
  }

  int code;
  String msg;
  dynamic data;
  DioException? exception;

  bool get isSuccess => code != -1 && data != null;

  bool get hasException => exception != null;

  ApiResponse copyWith({
    int? code,
    String? msg,
    dynamic data,
    DioException? exception,
  }) => ApiResponse(
    code: code ?? this.code,
    msg: msg ?? this.msg,
    data: data ?? this.data,
  )..exception = exception ?? this.exception;

  Map<String, dynamic> toJson() {
    return _$ApiResponseToJson(this);
  }
}

int _codeFromJson(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
