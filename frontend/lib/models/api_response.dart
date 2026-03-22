import 'package:dio/dio.dart';

/// Standard API envelope: `code`, `message` (as [msg]), and `data`.
class ApiResponse {
  ApiResponse({
    this.code = -1,
    this.msg = 'Unknown error',
    this.data,
    this.exception,
  });

  static ApiResponse defaultResponse = ApiResponse();

  factory ApiResponse.fromJson(dynamic json) => ApiResponse(
    code: json['code'] ?? 0,
    msg: json['message']?.toString() ?? 'Unknown error',
    data: json['data'],
  );

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
    final map = <String, dynamic>{};
    map['code'] = code;
    map['msg'] = msg;
    map['data'] = data;
    return map;
  }
}
