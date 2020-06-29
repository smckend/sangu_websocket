import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class MopidyHttpRpcClient {
  final Uri uri;
  final Uuid _uuid = Uuid();

  MopidyHttpRpcClient({@required this.uri});

  Future<dynamic> callMethod(
    String method, {
    Map params = const {},
  }) async {
    http.Response response = await http.post(
      uri,
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
    await http.post(
      uri,
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
