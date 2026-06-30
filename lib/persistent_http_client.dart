import 'dart:io';

/// Reuses one [HttpClient] per transport instance for polling workloads.
mixin PersistentHttpClient {
  HttpClient? _persistentClient;

  HttpClient get httpClient => _persistentClient ??= HttpClient();

  void closeHttpClient() {
    _persistentClient?.close(force: true);
    _persistentClient = null;
  }
}
