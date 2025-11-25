import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';


/// tests for UsersApi
void main() {
  final instance = ForgottenClientApi().getUsersApi();

  group(UsersApi, () {
    // Create User Endpoint
    //
    //Future<UserRead> createUserEndpointApiV1UsersPost(UserCreate userCreate) async
    test('test createUserEndpointApiV1UsersPost', () async {
      // TODO
    });

    // List Users Endpoint
    //
    //Future<List<UserRead>> listUsersEndpointApiV1UsersGet() async
    test('test listUsersEndpointApiV1UsersGet', () async {
      // TODO
    });

  });
}
