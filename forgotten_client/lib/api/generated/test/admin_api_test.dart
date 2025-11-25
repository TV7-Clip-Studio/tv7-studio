import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';


/// tests for AdminApi
void main() {
  final instance = ForgottenClientApi().getAdminApi();

  group(AdminApi, () {
    // Delete User Endpoint
    //
    //Future<Object> deleteUserEndpointAdminUsersUserIdDeletePost(int userId) async
    test('test deleteUserEndpointAdminUsersUserIdDeletePost', () async {
      // TODO
    });

    // Delete Video
    //
    //Future<Object> deleteVideoAdminVideosVideoIdDeletePost(int videoId) async
    test('test deleteVideoAdminVideosVideoIdDeletePost', () async {
      // TODO
    });

    // Ingest From Dashboard
    //
    //Future<Object> ingestFromDashboardAdminVideosIngestPost() async
    test('test ingestFromDashboardAdminVideosIngestPost', () async {
      // TODO
    });

    // Login Form
    //
    //Future<String> loginFormAdminLoginGet() async
    test('test loginFormAdminLoginGet', () async {
      // TODO
    });

    // Login Submit
    //
    //Future<Object> loginSubmitAdminLoginPost(String email, String password) async
    test('test loginSubmitAdminLoginPost', () async {
      // TODO
    });

    // Logout
    //
    //Future<Object> logoutAdminLogoutPost() async
    test('test logoutAdminLogoutPost', () async {
      // TODO
    });

    // Request More Highlights
    //
    //Future<Object> requestMoreHighlightsAdminVideosVideoIdMoreHighlightsPost(int videoId) async
    test('test requestMoreHighlightsAdminVideosVideoIdMoreHighlightsPost', () async {
      // TODO
    });

    // Toggle User Status
    //
    //Future<Object> toggleUserStatusAdminUsersUserIdToggleStatusPost(int userId) async
    test('test toggleUserStatusAdminUsersUserIdToggleStatusPost', () async {
      // TODO
    });

    // User Detail Page
    //
    //Future<String> userDetailPageAdminUsersUserIdGet(int userId) async
    test('test userDetailPageAdminUsersUserIdGet', () async {
      // TODO
    });

    // Users Dashboard
    //
    //Future<String> usersDashboardAdminUsersGet() async
    test('test usersDashboardAdminUsersGet', () async {
      // TODO
    });

    // Video Detail
    //
    //Future<String> videoDetailAdminVideosVideoIdGet(int videoId) async
    test('test videoDetailAdminVideosVideoIdGet', () async {
      // TODO
    });

    // Video Status Json
    //
    //Future<Object> videoStatusJsonAdminVideosVideoIdStatusGet(int videoId) async
    test('test videoStatusJsonAdminVideosVideoIdStatusGet', () async {
      // TODO
    });

    // Videos Dashboard
    //
    //Future<String> videosDashboardAdminVideosGet() async
    test('test videosDashboardAdminVideosGet', () async {
      // TODO
    });

    // Youtube Callback
    //
    //Future<Object> youtubeCallbackAdminYoutubeCallbackGet({ String state, String code, String error }) async
    test('test youtubeCallbackAdminYoutubeCallbackGet', () async {
      // TODO
    });

    // Youtube Connect
    //
    //Future<Object> youtubeConnectAdminYoutubeConnectGet() async
    test('test youtubeConnectAdminYoutubeConnectGet', () async {
      // TODO
    });

    // Youtube Disconnect
    //
    //Future<Object> youtubeDisconnectAdminYoutubeDisconnectPost() async
    test('test youtubeDisconnectAdminYoutubeDisconnectPost', () async {
      // TODO
    });

  });
}
