import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class MopidyHttpRpcClient {
  final String scheme;
  final String host;
  final int port;
  final String basePath;
  final Uuid _uuid = Uuid();

  MopidyHttpRpcClient({
    @required this.scheme,
    @required this.host,
    @required this.port,
    this.basePath = "",
  });

  Future<dynamic> callMethod(
    String method, {
    Map params = const {},
  }) async {
    Uri postUri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: basePath + "/mopidy/rpc",
    );
    http.Response response = await http.post(
      postUri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": _uuid.v4(),
        "method": method,
        "params": params,
      }),
    );
    var body = utf8.decode(response
        .bodyBytes); // Server adds invalid trailing ';' on Content-Type header
    return jsonDecode(body)["result"];
  }

  Future<dynamic> notifyMethod(
    String method, {
    Map params = const {},
  }) async {
    Uri postUri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: basePath + "/mopidy/rpc",
    );
    await http.post(
      postUri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "jsonrpc": "2.0",
        "method": method,
      }),
    );
  }
}
