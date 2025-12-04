import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/config/app_theme.dart';
import 'package:forgotten_client/data/api/api_client.dart';
import 'package:forgotten_client/data/auth/auth_repository.dart';
import 'package:forgotten_client/data/auth/models.dart';
import 'package:forgotten_client/data/auth/token_store.dart';
import 'package:forgotten_client/data/config/config_repository.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:forgotten_client/data/local/tool_runner.dart';
import 'package:forgotten_client/features/auth/login_form.dart';
import 'package:forgotten_client/features/dashboard/dashboard_page.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

class App extends StatelessWidget {
  const App({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forgotten Client',
      debugShowCheckedModeBanner: false,
      theme: MidnightTheme.themeData,
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
  late final ClientVideoRepository _localVideoRepository;
  late final Dio _dio;
  late final VideosApi _videosApi;
  late final UploadsApi _uploadsApi;
  late final UsersApi _usersApi;
  late final AiApi _aiApi;
  bool _isAuthenticated = false;
  bool _isRefreshing = false;
  Future<AuthTokens?>? _refreshingFuture;

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
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          if (status == 401) {
            final tokens = await _tokenStore.read();
            if (tokens == null) {
              return handler.next(error);
            }

            try {
              if (_isRefreshing && _refreshingFuture != null) {
                final refreshed = await _refreshingFuture;
                if (refreshed == null) {
                  return handler.next(error);
                }
                final request = error.requestOptions;
                request.headers['Authorization'] =
                    'Bearer ${refreshed.accessToken}';
                final clone = await _dio.fetch<dynamic>(request);
                return handler.resolve(clone);
              }

              _isRefreshing = true;
              _refreshingFuture = _authRepository.refresh(tokens);
              final refreshed = await _refreshingFuture;
              _refreshingFuture = null;
              _isRefreshing = false;

              if (refreshed == null) {
                await _tokenStore.clear();
                if (mounted) {
                  setState(() {
                    _isAuthenticated = false;
                  });
                }
                return handler.next(error);
              }

              final request = error.requestOptions;
              request.headers['Authorization'] =
                  'Bearer ${refreshed.accessToken}';
              final clone = await _dio.fetch<dynamic>(request);
              return handler.resolve(clone);
            } catch (_) {
              _isRefreshing = false;
              _refreshingFuture = null;
              await _tokenStore.clear();
              if (mounted) {
                setState(() {
                  _isAuthenticated = false;
                });
              }
              return handler.next(error);
            }
          }
          return handler.next(error);
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
    _uploadsApi = UploadsApi(_dio);
    _usersApi = UsersApi(_dio);
    _aiApi = AiApi(_dio);
    _localVideoRepository = ClientVideoRepository(
      toolRunner: ToolRunner(),
      videosApi: _videosApi,
      uploadsApi: _uploadsApi,
      aiApi: _aiApi,
      dio: _dio,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthenticated
        ? DashboardPage(
            configRepository: _configRepository,
            localVideoRepository: _localVideoRepository,
            authRepository: _authRepository,
            usersApi: _usersApi,
            onLogout: () {
              setState(() {
                _isAuthenticated = false;
              });
            },
          )
        : LoginPage(
            authRepository: _authRepository,
            flavor: widget.config.flavor,
            onSuccess: () {
              setState(() {
                _isAuthenticated = true;
              });
            },
          );
  }
}
