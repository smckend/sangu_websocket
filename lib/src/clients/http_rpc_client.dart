import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class HttpRpcClient {
  final Uri uri;
  final Uuid _uuid = Uuid();
  final http.Client client;

  HttpRpcClient({@required this.uri, @required this.client});

  Future<dynamic> callMethod(
    String method, {
    Map params = const {},
    String id,
  }) async {
    http.Response response = await client.post(uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "id": id ?? _uuid.v4(),
          "method": method,
          "params": params,
        }),
        encoding: utf8);
    if (response.statusCode != HttpStatus.ok)
      _throwException(HttpStatus.ok, response);
    var body = utf8.decode(response
        .bodyBytes); // Server adds invalid trailing ';' on Content-Type header
    return jsonDecode(body)["result"];
  }

  void _throwException(int expectedStatus, http.Response response) {
    throw Exception(
        "HttpRpcClient expected a status code of '$expectedStatus' but got '${response.statusCode}'. Server message: ${response.body}");
  }

  Future<dynamic> notifyMethod(
    String method, {
    Map params = const {},
  }) async {
    http.Response response = await client.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "jsonrpc": "2.0",
        "method": method,
      }),
    );
    if (response.statusCode != HttpStatus.ok)
      _throwException(HttpStatus.ok, response);
  }
}
