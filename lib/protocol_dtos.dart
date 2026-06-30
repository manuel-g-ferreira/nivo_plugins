/// Shared protocol result types for Nivo plugin handlers.
class AuthResult {
  const AuthResult({
    required this.authToken,
    required this.userId,
    required this.sessionOptions,
    this.defaultDataSourceId,
  });

  final String authToken;
  final String userId;
  final String? defaultDataSourceId;
  final Map<String, String> sessionOptions;

  Map<String, dynamic> toAuthenticateResponse() {
    return {
      'success': true,
      'authToken': authToken,
      'userId': userId,
      if (defaultDataSourceId != null)
        'defaultDataSourceId': defaultDataSourceId,
      'sessionOptions': sessionOptions,
    };
  }
}

class FetchReadingsResult {
  const FetchReadingsResult({
    required this.current,
    required this.history,
  });

  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> history;

  Map<String, dynamic> toFetchReadingsResponse() {
    return {
      'success': true,
      'current': current,
      'history': history,
    };
  }
}
