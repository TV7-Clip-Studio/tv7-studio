import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/config/app_theme.dart';
import 'package:forgotten_client/data/api/api_client.dart';
import 'package:forgotten_client/data/auth/auth_repository.dart';
import 'package:forgotten_client/data/auth/models.dart';
import 'package:forgotten_client/data/auth/token_store.dart';
import 'package:forgotten_client/data/config/config_repository.dart';
import 'package:forgotten_client/data/local/diagnostics_log.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_process_manager.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:forgotten_client/data/local/tool_runner.dart';
import 'package:forgotten_client/features/auth/login_form.dart';
import 'package:forgotten_client/features/dashboard/dashboard_page.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

class App extends StatelessWidget {
  App({
    required this.config,
    EngineStartupResult? engineStartup,
    EngineClient? engineClient,
    DiagnosticsLog? diagnosticsLog,
    this.engineManager,
    super.key,
  }) : engineStartup =
           engineStartup ??
           EngineStartupResult(
             status: EngineStartupStatus.unavailable,
             baseUri: _fallbackEngineBaseUri(),
             message: 'Engine startup has not run.',
           ),
       engineClient =
           engineClient ??
           EngineClient(
             baseUri: engineStartup?.baseUri ?? _fallbackEngineBaseUri(),
           ),
       diagnosticsLog = diagnosticsLog ?? DiagnosticsLog();

  final AppConfig config;
  final EngineStartupResult engineStartup;
  final EngineClient engineClient;
  final DiagnosticsLog diagnosticsLog;
  final EngineProcessManager? engineManager;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forgotten Client',
      debugShowCheckedModeBanner: false,
      theme: MidnightTheme.themeData,
      home: _Shell(
        config: config,
        engineStartup: engineStartup,
        engineClient: engineClient,
        diagnosticsLog: diagnosticsLog,
        engineManager: engineManager,
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell({
    required this.config,
    required this.engineStartup,
    required this.engineClient,
    required this.diagnosticsLog,
    this.engineManager,
  });

  final AppConfig config;
  final EngineStartupResult engineStartup;
  final EngineClient engineClient;
  final DiagnosticsLog diagnosticsLog;
  final EngineProcessManager? engineManager;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with WidgetsBindingObserver {
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
  late EngineStartupResult _engineStartup;
  bool _isAuthenticated = false;
  bool _isRefreshing = false;
  bool _isRefreshingEngine = false;
  Future<AuthTokens?>? _refreshingFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engineStartup = widget.engineStartup;
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

  Future<void> _refreshEngineDiagnostics() async {
    setState(() {
      _isRefreshingEngine = true;
    });

    try {
      final health = await widget.engineClient.getHealth();
      if (!health.isOk) {
        throw StateError('Engine health status is ${health.status}');
      }
      final diagnostics = await widget.engineClient.getDiagnostics();
      if (!mounted) return;
      setState(() {
        _engineStartup = EngineStartupResult(
          status: diagnostics.isReady
              ? EngineStartupStatus.ready
              : EngineStartupStatus.degraded,
          baseUri: widget.engineClient.baseUri,
          diagnostics: diagnostics,
          message: diagnostics.summary,
        );
      });
    } catch (error) {
      if (!mounted) return;
      widget.diagnosticsLog.record('Engine diagnostics refresh', error);
      setState(() {
        _engineStartup = EngineStartupResult(
          status: EngineStartupStatus.unavailable,
          baseUri: widget.engineClient.baseUri,
          message: 'Engine diagnostics refresh failed: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingEngine = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(widget.engineManager?.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.engineManager?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _isAuthenticated
        ? DashboardPage(
            configRepository: _configRepository,
            localVideoRepository: _localVideoRepository,
            authRepository: _authRepository,
            appConfig: widget.config,
            dio: _dio,
            engineClient: widget.engineClient,
            engineStartup: _engineStartup,
            diagnosticsLog: widget.diagnosticsLog,
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
    return Stack(
      children: [
        page,
        if (!_engineStartup.isReady)
          _EngineStartupBanner(
            startup: _engineStartup,
            isRefreshing: _isRefreshingEngine,
            onRefresh: _refreshEngineDiagnostics,
          ),
      ],
    );
  }
}

class _EngineStartupBanner extends StatelessWidget {
  const _EngineStartupBanner({
    required this.startup,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final EngineStartupResult startup;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final color = startup.status == EngineStartupStatus.degraded
        ? Colors.amber.shade800
        : Colors.red.shade700;
    final message = startup.message ?? 'Engine is not ready.';

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: color,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: isRefreshing
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Uri _fallbackEngineBaseUri() {
  return Uri(scheme: 'http', host: '127.0.0.1', port: 7070);
}
