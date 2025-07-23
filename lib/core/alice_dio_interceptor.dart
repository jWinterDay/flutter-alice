import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/model/alice_form_data_file.dart';
import 'package:flutter_alice/model/alice_from_data_field.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_http_error.dart';
import 'package:flutter_alice/model/alice_http_request.dart';
import 'package:flutter_alice/model/alice_http_response.dart';

class AliceDioInterceptor extends InterceptorsWrapper {
  /// Creates dio interceptor
  AliceDioInterceptor(this.aliceCore);

  /// AliceCore instance
  final AliceCore aliceCore;

  /// Handles dio request and creates alice http call based on it
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final AliceHttpCall call = AliceHttpCall(options.hashCode);

    final Uri uri = options.uri;
    call.method = options.method;
    String path = options.uri.path;
    if (path.isEmpty) {
      path = '/';
    }
    call.endpoint = path;
    call.server = uri.host;
    call.port = uri.port;
    call.client = 'Dio';
    call.uri = options.uri.toString();

    if (uri.scheme == 'https') {
      call.secure = true;
    }

    final AliceHttpRequest request = AliceHttpRequest();

    final dynamic data = options.data;
    if (data == null) {
      request.size = 0;
      request.body = '';
    } else {
      if (data is FormData) {
        request.body += 'Form data';

        if (data.fields.isNotEmpty) {
          final List<AliceFormDataField> fields = <AliceFormDataField>[];
          for (final MapEntry<String, String> entry in data.fields) {
            fields.add(AliceFormDataField(entry.key, entry.value));
          }
          request.formDataFields = fields;
        }
        if (data.files.isNotEmpty) {
          final List<AliceFormDataFile> files = <AliceFormDataFile>[];
          for (final MapEntry<String, MultipartFile> entry in data.files) {
            files.add(AliceFormDataFile(entry.value.filename!, entry.value.contentType.toString(), entry.value.length));
          }

          request.formDataFiles = files;
        }
      } else {
        request.size = utf8.encode(data.toString()).length;
        request.body = data;
      }
    }

    request.time = DateTime.now();
    request.headers = options.headers;
    request.contentType = options.contentType.toString();
    request.queryParameters = uri.queryParameters; // options.queryParameters;

    call.request = request;
    call.response = AliceHttpResponse();

    // print('++++++ alice onRequest: ${options.uri} hash = ${options.hashCode}');

    aliceCore.addRequest(call);

    handler.next(options);
  }

  /// Handles dio response and adds data to alice http call
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final AliceHttpResponse httpResponse = AliceHttpResponse();
    httpResponse.status = response.statusCode!;

    // print('++++++ alice onResponse: ${response.requestOptions.uri} hash = ${response.requestOptions.hashCode}');

    if (response.data == null) {
      httpResponse.body = '';
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.data;
      httpResponse.size = utf8.encode(response.data.toString()).length;
    }

    httpResponse.time = DateTime.now();
    final Map<String, String> headers = <String, String>{};
    response.headers.forEach((String header, List<String> values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    aliceCore.addResponse(httpResponse, response.requestOptions.hashCode);

    handler.next(response);
  }

  /// Handles error and adds data to alice http call
  @override
  void onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) {
    // error
    final AliceHttpError httpError = AliceHttpError();
    httpError.status = error.response?.statusCode ?? -1;
    httpError.error = error.toString();
    httpError.body = error.response?.data;
    httpError.headers = error.requestOptions.headers.map(
      (String key, dynamic value) => MapEntry<String, String>(
        key,
        value.toString(),
      ),
    );

    if (error is Error) {
      final Error basicError = error as Error;
      httpError.stackTrace = basicError.stackTrace;
    }

    aliceCore.addError(httpError, error.requestOptions.hashCode);

    // response
    final AliceHttpResponse httpResponse = AliceHttpResponse();
    httpResponse.time = DateTime.now();

    if (error.response == null) {
      httpResponse.status = -1;
      aliceCore.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      httpResponse.status = error.response!.statusCode!;

      if (error.response!.data == null) {
        httpResponse.body = '';
        httpResponse.size = 0;
      } else {
        httpResponse.body = error.response!.data;
        httpResponse.size = utf8.encode(error.response!.data.toString()).length;
      }
      final Map<String, String> headers = <String, String>{};
      if (error.response?.headers != null) {
        error.response!.headers.forEach((String header, List<String> values) {
          headers[header] = values.toString();
        });
      }
      httpResponse.headers = headers;

      aliceCore.addResponse(httpResponse, error.requestOptions.hashCode);
    }

    handler.next(error);
  }
}
