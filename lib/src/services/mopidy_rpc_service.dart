import 'package:flutter/material.dart';
import 'package:sangu_websocket/sangu_websocket.dart';
import 'package:sangu_websocket/src/clients/http_rpc_client.dart';

class MopidyRpcService {
  final HttpRpcClient rpcClient;

  MopidyRpcService({@required this.rpcClient});

  void resume() => rpcClient.notifyMethod("core.playback.resume");

  void pause() => rpcClient.notifyMethod("core.playback.pause");

  void next() => rpcClient.notifyMethod("core.playback.next");

  Future get getVersion => rpcClient.callMethod("core.get_version");

  Future get getState => rpcClient.callMethod(
        "core.playback.get_state",
      );

  Future get getTimePosition => rpcClient.callMethod(
        "core.playback.get_time_position",
      );

  Future get getTlTracks => rpcClient.callMethod(
        "core.tracklist.get_tl_tracks",
      );

  Future getIndex({TlTrack tlTrack, int trackListId}) => rpcClient.callMethod(
        "core.tracklist.index",
        params: {
          "tl_track": tlTrack,
          "tlid": trackListId,
        },
      );

  Future getSliceOfTlTracks({int start, int end}) => rpcClient.callMethod(
        "core.tracklist.slice",
        params: {
          "start": start,
          "end": end,
        },
      );

  play({int trackListId}) {
    return rpcClient.callMethod(
      "core.playback.play",
      params: {
        "tlid": trackListId,
      },
    );
  }

  Future search({Map query, List uris = const []}) {
    Map params = {
      "query": query,
      "exact": false
    };
    if (uris.length > 0)
      params.addAll({
        "uris": uris
      });
    return rpcClient.callMethod(
      "core.library.search",
      params: params,
    );
  }

  Future getImages(List uris) => rpcClient.callMethod(
        "core.library.get_images",
        params: {
          "uris": uris,
        },
      );

  Future lookup(List uris) => rpcClient.callMethod(
        "core.library.lookup",
        params: {
          "uris": uris,
        },
      );

  Future add(List<String> uris) => rpcClient.callMethod(
        "core.tracklist.add",
        params: {
          "uris": uris,
        },
      );

  Future remove(List<int> trackListIds) => rpcClient.callMethod(
        "core.tracklist.remove",
        params: {
          "criteria": {
            'tlid': trackListIds,
          }
        },
      );
}
