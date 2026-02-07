// ignore: unnecessary_library_name
library services;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:wordupx/utils/log.dart';

import '../models/res_base_model.dart';
import 'apis/api_service.dart';
part 'dio_client/dio_client.dart';
part 'dio_client/interceptors.dart';
part 'env.dart';
part 'api.dart';
