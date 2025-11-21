import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

class ResilientHttpClient extends http.BaseClient {
  ResilientHttpClient(
    http.Client inner, {
    this.requestTimeout = const Duration(seconds: 10),
    this.retries = 2,
    this.initialBackoff = const Duration(milliseconds: 200),
  }) : _retryClient = RetryClient(
          inner,
          retries: retries,
          when: (response) => response.statusCode >= 500,
          whenError: (error, _) =>
              error is TimeoutException || error is http.ClientException,
          delay: (attempt) => Duration(
            milliseconds:
                (initialBackoff.inMilliseconds * pow(2, attempt - 1)).toInt(),
          ),
        );

  final Duration requestTimeout;
  final int retries;
  final Duration initialBackoff;
  final RetryClient _retryClient;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _retryClient.send(request).timeout(requestTimeout);
  }

  @override
  void close() {
    _retryClient.close();
    super.close();
  }
}
