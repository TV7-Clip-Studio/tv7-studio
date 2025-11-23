import 'package:flutter/material.dart';

import 'config/app_config.dart';

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
      home: _ConfigPreview(config: config),
    );
  }
}

class _ConfigPreview extends StatelessWidget {
  const _ConfigPreview({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgotten Client (${config.flavor})'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bootstrap shell is running.\n'
            'Replace this screen with auth/dashboard UI.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _ConfigCard(
            title: 'API base URL',
            value: config.apiBaseUrl.toString(),
          ),
          _ConfigCard(
            title: 'OpenAI mode',
            value: config.openAiMode,
          ),
          _ConfigCard(
            title: 'Feature flags (json)',
            value: config.featureFlags.toString(),
          ),
          _ConfigCard(
            title: 'Log level',
            value: config.appLogLevel,
          ),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
