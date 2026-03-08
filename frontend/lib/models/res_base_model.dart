/// Created on 2026/2/5
/// Description:
library;

import 'package:dio/dio.dart';

class ResBaseModel {
  ResBaseModel({
    this.code = -1,
    this.msg = 'Unknown error',
    this.data,
    this.exception,
  });

  static ResBaseModel defaultRes = ResBaseModel();

  factory ResBaseModel.fromJson(dynamic json) => ResBaseModel(
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

  ResBaseModel copyWith({
    int? code,
    String? msg,
    dynamic data,
    DioException? exception,
  }) => ResBaseModel(
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
