import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'package:template_flutter/app.dart';
import 'package:template_flutter/core/config/app_config.dart';
import 'package:template_flutter/core/telemetry/telemetry.dart';
import 'package:template_flutter/testing/mock_template_go_server.dart';

const _useLiveApi = bool.fromEnvironment('USE_LIVE_API');
const _liveApiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _apiEnv = String.fromEnvironment('APP_ENV', defaultValue: 'mock');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  MockTemplateGoServer? mockServer;

  setUpAll(() async {
    if (!_useLiveApi) {
      mockServer = await MockTemplateGoServer.start();
    }
  });

  tearDownAll(() async {
    await mockServer?.close();
  });

  testWidgets('todo e2e flow with telemetry-enabled HTTP client',
      (tester) async {
    final client = http.Client();
    addTearDown(client.close);

    final baseUrl = (_useLiveApi && _liveApiBaseUrl.isNotEmpty)
        ? _liveApiBaseUrl
        : mockServer!.baseUrl;
    final environment =
        _useLiveApi ? (_apiEnv.isEmpty ? 'live' : _apiEnv) : 'mock';

    final config = AppConfig(
      apiBaseUrl: baseUrl,
      otelEndpoint: 'http://localhost:4318',
      serviceName: 'template-flutter-e2e',
      environment: environment,
    );

    await Telemetry.init(config, client: client, enableExporters: _useLiveApi);

    await tester.pumpWidget(App(config: config));

    // Page load renders a spinner while the initial fetch runs.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Template Todo'), findsOneWidget);
    expect(find.text('Seed todo'), findsOneWidget);
    expect(find.byKey(const Key('todo-input-field')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('todo-input-field')), 'Write e2e test');
    await tester.tap(find.byKey(const Key('todo-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Write e2e test'), findsOneWidget);

    await tester.tap(find.byKey(const Key('todo-2-checkbox')));
    await tester.pumpAndSettle();
    final completedTile = find.ancestor(
      of: find.text('Write e2e test'),
      matching: find.byType(ListTile),
    );
    final textWidget = tester.widget<Text>(
        find.descendant(of: completedTile, matching: find.byType(Text)).first);
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);

    await tester.tap(find.byKey(const Key('todo-2-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Write e2e test'), findsNothing);
  });
}
