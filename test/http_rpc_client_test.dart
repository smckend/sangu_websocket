import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:sangu_websocket/src/clients/http_rpc_client.dart';

void main() {
  group("callMethod", () {
    test('Test success response', () async {
      String path = "/mopidy/rpc";
      String method = "method.test";
      String id = "some-id";
      var mockClient = MockClient(
        (request) => Future.delayed(Duration(milliseconds: 50)).then(
          (_) {
            if (request.url.path != path) return Response("", 404);
            var body = jsonDecode(request.body);
            print(body);
            if (body["method"] != method) return Response("Bad method", 422);
            if (body["jsonrpc"] != "2.0") return Response("Bad RPC ve", 422);
            if (body["id"] != id) return Response("Bad ID", 422);
            return Response(jsonEncode({'result': "some-result"}), 200,
                headers: const {'Content-Type': 'application/json'});
          },
        ),
      );
      HttpRpcClient mopidyHttpRpcClient = HttpRpcClient(
          client: mockClient, uri: Uri.parse("http://test.url$path"));
      expect(await mopidyHttpRpcClient.callMethod(method, id: id),
          equals("some-result"));
    });

    test('Test auto generate id', () async {
      String path = "/mopidy/rpc";
      String method = "method.test";
      var mockClient = MockClient(
        (request) => Future.delayed(Duration(milliseconds: 50)).then(
          (_) {
            if (request.url.path != path) return Response("", 404);
            var body = jsonDecode(request.body);
            print(body);
            if (body["method"] != method) return Response("Bad method", 422);
            if (body["jsonrpc"] != "2.0") return Response("Bad RPC ve", 422);
            if (body["id"] == "" || body["id"] == null)
              return Response("Bad ID", 422);
            return Response(jsonEncode({'result': "some-result"}), 200,
                headers: const {'Content-Type': 'application/json'});
          },
        ),
      );
      HttpRpcClient mopidyHttpRpcClient = HttpRpcClient(
          client: mockClient, uri: Uri.parse("http://test.url$path"));
      expect(
          await mopidyHttpRpcClient.callMethod(method), equals("some-result"));
    });

    test('Can handle content-type charset to response', () async {
      String path = "/mopidy/rpc";
      String method = "method.test";
      var mockClient = MockClient(
        (request) => Future.delayed(Duration(milliseconds: 50)).then(
          (_) {
            return Response(jsonEncode({'result': "some-result"}), 200,
                headers: const {
                  'Content-Type': 'application/json; charset=utf-8;'
                });
          },
        ),
      );
      HttpRpcClient mopidyHttpRpcClient = HttpRpcClient(
          client: mockClient, uri: Uri.parse("http://test.url$path"));
      expect(
          await mopidyHttpRpcClient.callMethod(method), equals("some-result"));
    });

//    test('Adds plain application/json header', () async {
//      String path = "/mopidy/rpc";
//      String method = "method.test";
//      var mockClient = MockClient(
//        (request) => Future.delayed(Duration(milliseconds: 50)).then(
//          (_) {
//            print(request.headers);
//            if (request.headers["Content-Type"] != "application/json")
//              return Response("Bad headers", 422);
//            return Response(jsonEncode({'result': "some-result"}), 200,
//                headers: const {
//                  'Content-Type': 'application/json'
//                });
//          },
//        ),
//      );
//      HttpRpcClient mopidyHttpRpcClient = HttpRpcClient(
//          client: mockClient, uri: Uri.parse("http://test.url$path"));
//      expect(
//          await mopidyHttpRpcClient.callMethod(method), equals("some-result"));
//    });
  });

  group("notifyMethod", () {
    test('Test success response', () async {
      String path = "/mopidy/rpc";
      String method = "method.test";
      var mockClient = MockClient(
        (request) => Future.delayed(Duration(milliseconds: 50)).then(
          (_) {
            if (request.url.path != path) return Response("", 404);
            var body = jsonDecode(request.body);
            print(body);
            if (body["method"] != method || body["jsonrpc"] != "2.0")
              return Response("", 422);
            return Response("", 200);
          },
        ),
      );
      HttpRpcClient mopidyHttpRpcClient = HttpRpcClient(
          client: mockClient, uri: Uri.parse("http://test.url$path"));
      expect(await mopidyHttpRpcClient.notifyMethod(method), null);
    });

//    test('Adds plain application/json header', () async {
//      String path = "/mopidy/rpc";
//      String method = "method.test";
//      var mockClient = MockClient(
//        (request) => Future.delayed(Duration(milliseconds: 50)).then(
//          (_) {
//            print(request.headers);
//            if (request.headers["Content-Type"] != "application/json")
//              return Response("Bad headers", 422);
//            return Response("", 200, headers: const {
//              'Content-Type': 'application/json'
//            });
//          },
//        ),
//      );
//      HttpRpcClient mopidyHttpRpcClient = HttpRpcClient(
//          client: mockClient, uri: Uri.parse("http://test.url$path"));
//      expect(await mopidyHttpRpcClient.notifyMethod(method),
//          equals("some-result"));
//    });
  });
}
