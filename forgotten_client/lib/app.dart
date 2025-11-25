import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'config/app_config.dart';
import 'data/api/api_client.dart';
import 'data/auth/auth_repository.dart';
import 'data/auth/token_store.dart';
import 'data/config/config_repository.dart';
import 'data/local/local_video_repository.dart';
import 'data/local/tool_runner.dart';
import 'package:dio/dio.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';
import 'features/auth/login_form.dart';
import 'features/dashboard/dashboard_page.dart';

class App extends StatelessWidget {
  const App({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forgotten Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: _Shell(config: config),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell({required this.config});

  final AppConfig config;

  @override
  State<_Shell> createState() => _ShellState();
}



class _ShellState extends State<_Shell> {
  late final TokenStore _tokenStore;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final ConfigRepository _configRepository;
  late final LocalVideoRepository _localVideoRepository;
  late final Dio _dio;
  late final VideosApi _videosApi;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _tokenStore = InMemoryTokenStore();
    _apiClient = ApiClient(config: widget.config, tokenStore: _tokenStore);
    _authRepository = AuthRepository(
      config: widget.config,
      apiClient: _apiClient,
      tokenStore: _tokenStore,
    );
    _configRepository = ConfigRepository(widget.config);
    _dio = Dio(BaseOptions(baseUrl: widget.config.apiBaseUrl.toString()));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokens = await _tokenStore.read();
          if (tokens != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          return handler.next(options);
        },
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (msg) => debugPrint('[videos_api] $msg'),
      ),
    );
    _videosApi = VideosApi(_dio);
    _localVideoRepository = LocalVideoRepository(toolRunner: ToolRunner(), videosApi: _videosApi);
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthenticated
        ? DashboardPage(
            configRepository: _configRepository,
            localVideoRepository: _localVideoRepository,
          )
        : Scaffold(
            appBar: AppBar(
              title: Text('Sign in (${widget.config.flavor})'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LoginForm(
                authRepository: _authRepository,
                onSuccess: () {
                  setState(() {
                    _isAuthenticated = true;
                  });
                },
              ),
            ),
          );
  }
}
