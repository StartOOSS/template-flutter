import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MockTemplateGoServer {
  MockTemplateGoServer._(this._server);

  final HttpServer _server;
  final _todos = <Map<String, dynamic>>[
    {'id': '1', 'title': 'Seed todo', 'completed': false},
  ];
  int _nextId = 2;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<MockTemplateGoServer> start({int port = 0}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final mock = MockTemplateGoServer._(server);
    server.listen(mock._handleRequest, onError: stderr.writeln);
    return mock;
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/api/v1/todos' && request.method == 'GET') {
      return _json(request, _todos);
    }

    if (request.uri.path == '/api/v1/todos' && request.method == 'POST') {
      final payload = await _readJson(request);
      final todo = {
        'id': '${_nextId++}',
        'title': payload['title'] ?? 'Untitled',
        'completed': false,
      };
      _todos.insert(0, todo);
      return _json(request, todo, statusCode: HttpStatus.created);
    }

    if (request.uri.path.startsWith('/api/v1/todos/') &&
        request.method == 'PUT') {
      final id = request.uri.pathSegments.last;
      final index = _todos.indexWhere((todo) => todo['id'] == id);
      if (index == -1) {
        return _text(request, 'Not found', statusCode: HttpStatus.notFound);
      }
      final payload = await _readJson(request);
      final updated = {
        'id': id,
        'title': payload['title'] ?? _todos[index]['title'],
        'completed': payload['completed'] ?? _todos[index]['completed'],
      };
      _todos[index] = updated;
      return _json(request, updated);
    }

    if (request.uri.path.startsWith('/api/v1/todos/') &&
        request.method == 'DELETE') {
      final id = request.uri.pathSegments.last;
      final before = _todos.length;
      _todos.removeWhere((todo) => todo['id'] == id);
      if (before == _todos.length) {
        return _text(request, 'Not found', statusCode: HttpStatus.notFound);
      }
      request.response.statusCode = HttpStatus.noContent;
      return request.response.close();
    }

    return _text(request, 'Unhandled route',
        statusCode: HttpStatus.internalServerError);
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final data = await utf8.decoder.bind(request).join();
    if (data.isEmpty) {
      return {};
    }
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> _json(HttpRequest request, Object body,
      {int statusCode = HttpStatus.ok}) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }

  Future<void> _text(HttpRequest request, String message,
      {int statusCode = HttpStatus.ok}) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.text
      ..write(message);
    await request.response.close();
  }
}
