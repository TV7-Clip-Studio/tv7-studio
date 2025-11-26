import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

/// tests for VideosApi
void main() {
  final instance = ForgottenClientApi().getVideosApi();

  group(VideosApi, () {
    // Get Video Status
    //
    //Future<VideoRead> getVideoStatusApiV1VideosVideoIdGet(int videoId) async
    test('test getVideoStatusApiV1VideosVideoIdGet', () async {
      // TODO
    });

    // Ingest Upload Endpoint
    //
    //Future<VideoIngestResponse> ingestUploadEndpointApiV1VideosIngestUploadPost(MultipartFile file, { bool appendClips }) async
    test('test ingestUploadEndpointApiV1VideosIngestUploadPost', () async {
      // TODO
    });

    // Ingest Youtube Endpoint
    //
    //Future<VideoIngestResponse> ingestYoutubeEndpointApiV1VideosIngestYoutubePost(YouTubeIngestRequest youTubeIngestRequest) async
    test('test ingestYoutubeEndpointApiV1VideosIngestYoutubePost', () async {
      // TODO
    });

    // Register Local Video
    //
    //Future<VideoRead> registerLocalVideoApiV1VideosLocalPost(LocalVideoCreate localVideoCreate) async
    test('test registerLocalVideoApiV1VideosLocalPost', () async {
      // TODO
    });
  });
}
