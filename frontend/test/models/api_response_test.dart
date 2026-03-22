import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/api_response.dart';

void main() {
  group('ApiResponse', () {
    group('constructor', () {
      test('uses default code and msg when not provided', () {
        final model = ApiResponse();
        expect(model.code, -1);
        expect(model.msg, 'Unknown error');
        expect(model.data, isNull);
        expect(model.exception, isNull);
      });

      test('accepts custom values', () {
        final model = ApiResponse(
          code: 0,
          msg: 'Success',
          data: {'key': 'value'},
        );
        expect(model.code, 0);
        expect(model.msg, 'Success');
        expect(model.data, {'key': 'value'});
      });
    });

    group('fromJson', () {
      test('parses success response', () {
        final json = {
          'code': 0,
          'message': 'OK',
          'data': {'token': 'abc123'},
        };
        final model = ApiResponse.fromJson(json);
        expect(model.code, 0);
        expect(model.msg, 'OK');
        expect(model.data, {'token': 'abc123'});
      });

      test('defaults code to 0 when key is missing', () {
        final model = ApiResponse.fromJson({'data': null});
        expect(model.code, 0);
      });

      test('uses default msg when message is missing', () {
        final model = ApiResponse.fromJson({'code': 0});
        expect(model.msg, 'Unknown error');
      });

      test('converts message to string when not string', () {
        final model = ApiResponse.fromJson({'code': 1, 'message': 404});
        expect(model.msg, '404');
      });
    });

    group('isSuccess', () {
      test('returns false when data is null even if code is 0', () {
        final model = ApiResponse(code: 0, msg: '', data: null);
        expect(model.isSuccess, false);
      });

      test('returns false when code is non-zero', () {
        final model = ApiResponse(code: 1, msg: '', data: null);
        expect(model.isSuccess, false);
      });
    });

    group('hasException', () {
      test('returns false when exception is null', () {
        final model = ApiResponse();
        expect(model.hasException, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = ApiResponse(code: 0, msg: 'OK', data: null);
        final copy = original.copyWith(code: 1, msg: 'Error');
        expect(copy.code, 1);
        expect(copy.msg, 'Error');
        expect(copy.data, isNull);
      });

      test('preserves unspecified fields', () {
        final original = ApiResponse(code: 0, msg: 'OK', data: {'x': 1});
        final copy = original.copyWith(code: 1);
        expect(copy.msg, 'OK');
        expect(copy.data, {'x': 1});
      });
    });

    group('toJson', () {
      test('serializes to map', () {
        final model = ApiResponse(
          code: 0,
          msg: 'Success',
          data: {'user': 'test'},
        );
        final json = model.toJson();
        expect(json['code'], 0);
        expect(json['msg'], 'Success');
        expect(json['data'], {'user': 'test'});
      });
    });

    group('defaultResponse', () {
      test('defaultResponse has default values', () {
        expect(ApiResponse.defaultResponse.code, -1);
        expect(ApiResponse.defaultResponse.msg, 'Unknown error');
        expect(ApiResponse.defaultResponse.data, isNull);
      });
    });
  });
}
