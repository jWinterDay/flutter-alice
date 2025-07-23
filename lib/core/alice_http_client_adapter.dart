import 'dart:convert';
import 'dart:io';

import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_http_request.dart';
import 'package:flutter_alice/model/alice_http_response.dart';

class AliceHttpClientAdapter {
  /// Creates alice http client adapter
  AliceHttpClientAdapter(this.aliceCore);

  /// AliceCore instance
  final AliceCore aliceCore;

  /// Handles httpClientRequest and creates http alice call from it
  void onRequest(HttpClientRequest request, {dynamic body}) {
    final AliceHttpCall call = AliceHttpCall(request.hashCode);
    call.loading = true;
    call.client = 'HttpClient (io package)';
    call.method = request.method;
    call.uri = request.uri.toString();

    String path = request.uri.path;
    if (path.isEmpty) {
      path = '/';
    }

    call.endpoint = path;
    call.server = request.uri.host;
    if (request.uri.scheme == 'https') {
      call.secure = true;
    }
    final AliceHttpRequest httpRequest = AliceHttpRequest();
    if (body == null) {
      httpRequest.size = 0;
      httpRequest.body = '';
    } else {
      httpRequest.size = utf8.encode(body.toString()).length;
      httpRequest.body = body;
    }
    httpRequest.time = DateTime.now();
    final Map<String, dynamic> headers = <String, dynamic>{};
    httpRequest.headers.forEach((String header, dynamic value) {
      headers[header] = value;
    });

    httpRequest.headers = headers;
    String? contentType = 'unknown';
    if (headers.containsKey('Content-Type')) {
      contentType = headers['Content-Type'];
    }

    httpRequest.contentType = contentType;
    httpRequest.cookies = request.cookies;

    call.request = httpRequest;
    call.response = AliceHttpResponse();
    aliceCore.addRequest(call);
  }

  /// Handles httpClientRequest and adds response to http alice call
  Future<void> onResponse(HttpClientResponse response, HttpClientRequest request, {dynamic body}) async {
    final AliceHttpResponse httpResponse = AliceHttpResponse();
    httpResponse.status = response.statusCode;

    if (body != null) {
      httpResponse.body = body;
      httpResponse.size = utf8.encode(body.toString()).length;
    } else {
      httpResponse.body = '';
      httpResponse.size = 0;
    }
    httpResponse.time = DateTime.now();
    final Map<String, String> headers = <String, String>{};
    response.headers.forEach((String header, List<String> values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;
    aliceCore.addResponse(httpResponse, request.hashCode);
  }
}
