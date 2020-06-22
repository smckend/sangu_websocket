import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:sangu_websocket/sangu_websocket.dart';
import 'package:sangu_websocket/src/clients/mopidy_json_rpc_client.dart';
import 'package:sangu_websocket/src/services/mopidy_rpc_service.dart';

import 'utils/mopidy_event_stream.dart';

class MopidyWebSocket extends SanguWebSocket {
  Uri webSocketUri;
  MopidyRpcService _rpcService;
  MopidyEventMapper _sanguEventStream;
  StreamSubscription _eventStreamSubscription;
  Stream _stream;

  int _reconnectRetryLimit = 5;
  int _reconnectRetryAttempts = 0;

  StreamController<Equatable> _streamController = StreamController.broadcast();

  MopidyWebSocket({@required this.webSocketUri}) {
    _stream = _streamController.stream;
    _initStream();
  }

  void _handleError(dynamic error) {
    print("Rpc client error: $error");
  }

  void _handleClose({int code, String reason}) async {
    if (_reconnectRetryAttempts < _reconnectRetryLimit) {
      print("Retrying websocket connection...");
      _streamController.add(WebSocketRetrying());
      _reconnectRetryAttempts = _reconnectRetryAttempts + 1;
      Future.delayed(const Duration(seconds: 1), () => _initStream());
    } else {
      _streamController
          .add(WebSocketClosed(reason: "Connection closed. Please refresh."));
      print("Retry limit for websocket connection exceeded.");
    }
  }

  Future _initStream() async {
    _eventStreamSubscription?.cancel();
    await _sanguEventStream?.close();

    print("Starting streams...");
    MopidyHttpRpcClient _mopidyHttpRpcClient = MopidyHttpRpcClient(
      scheme: webSocketUri.scheme == "ws" ? "http" : "https",
      host: webSocketUri.host,
      port: webSocketUri.port,
    );
    _rpcService = MopidyRpcService(rpcClient: _mopidyHttpRpcClient);
    _sanguEventStream = MopidyEventMapper(webSocketUri: webSocketUri);
    _eventStreamSubscription = _sanguEventStream.stream.listen(
      (event) {
        if (event is Equatable) _streamController.add(event);
      },
      cancelOnError: true,
      onError: (error) {
        _handleError(error);
      },
      onDone: () async {
        _handleClose(
          code: _sanguEventStream.closeCode,
          reason: _sanguEventStream.closeReason,
        );
      },
    );
    await Future.delayed(
      const Duration(milliseconds: 800),
      () {
        if (_sanguEventStream.closeCode == null) {
          _reconnectRetryAttempts = 0;
          _streamController.add(WebSocketConnected());
        }
      },
    );
    print("Finished starting streams...");
  }

  Stream get stream => _stream;

  bool get isConnected => !_streamController.isClosed;

  resumePlayback() async {
    _rpcService.resume();
  }

  pausePlayback() async {
    _rpcService.pause();
  }

  playTrack() async {
    _rpcService.play();
  }

  nextTrack() async {
    _rpcService.next();
  }

  getCurrentState() async {
    _rpcService.getState.then((state) {
      _streamController.add(TrackPlaybackChange(state: state));
    });
  }

  search(Map query) async {
    _rpcService.search(query: query).then(
      (result) {
        List listResult = result;
        List<SearchResult> searchResults = List();
        listResult.forEach(
          (rawSearchResult) {
            List tracks = rawSearchResult["tracks"];
            String searchBackend = rawSearchResult["uri"].split(":")[0];
            tracks?.forEach(
              (rawTrack) {
                Track track = Track.fromJson(rawTrack);
                searchResults.add(
                    SearchResult(track: track, searchBackend: searchBackend));
              },
            );
          },
        );
        _streamController
            .add(ReceivedSearchResults(searchResults: searchResults ?? []));
      },
    );
  }

  getTrackList() async {
    _rpcService.getIndex().then(
          (index) => _rpcService.getSliceOfTlTracks(start: index).then(
            (result) {
              List listOfRawTracks = result;
              var trackList = listOfRawTracks?.map((dynamic rawTrack) {
                return TlTrack.fromJson(rawTrack);
              })?.toList();
              _streamController.add(ReceivedTrackList(trackList: trackList));
            },
          ),
        );
  }

  getImages(List<String> uris) async {
    _rpcService.getImages(uris).then((result) {
      var artwork = Map<String, Images>();
      (result as Map)?.forEach((uri, images) {
        var imageList = images as List;
        if (imageList.isNotEmpty) {
          artwork[uri] = imageList.length > 1
              ? Images(
                  smallImage:
                      imageList.firstWhere((map) => map["width"] < 200)["uri"],
                  mediumImage: imageList.firstWhere((map) =>
                      200 <= map["width"] && map["width"] <= 400)["uri"],
                  largeImage:
                      imageList.firstWhere((map) => map["width"] > 400)["uri"],
                )
              : Images(
                  smallImage: imageList.first["uri"],
                  mediumImage: imageList.first["uri"],
                  largeImage: imageList.first["uri"]);
        }
      });
      if (artwork.isNotEmpty)
        _streamController.add(ReceivedAlbumArt(artwork: artwork));
    });
  }

  addTrackToTrackList(Track track) async {
    _rpcService.add([track.uri]).then((result) {
      print("Added '${track.name}' to tracklist");
    });
  }

  removeTrackFromTrackList(TlTrack tlTrack) async {
    _rpcService.remove([tlTrack.trackListId]).then((result) {
      print("Removed '${tlTrack.track.name}' from tracklist");
    });
  }

  playTrackIfNothingElseIsPlaying() async {
    _rpcService.getTlTracks.then((result) {
      List listOfRawTracks = result;
      if (listOfRawTracks.length == 1) _rpcService.play();
    });
  }

  getTimePosition() async {
    _rpcService.getTimePosition.then((position) {
      _streamController.add(Seeked(position: position));
    });
  }

  void dispose() async {
    _eventStreamSubscription?.cancel();
    _streamController?.close();
    _sanguEventStream?.close();
  }
}
