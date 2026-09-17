/// Configuration for the OLOF Clinic Server Room Local Storage & Streaming API.
///
/// This server runs on the server room PC (e.g. 192.168.100.17:8080) on the local LAN.
/// It stores high-resolution patient webcam photos, clinical canvas drawings,
/// lab results, and diagnostic files without consuming cloud Supabase storage limits.
class ApiConfig {
  ApiConfig._();

  /// Default IP address of the server room PC.
  /// Can be customized at runtime or via environment variables.
  static String _serverHost = const String.fromEnvironment(
    'OLOF_SERVER_HOST',
    defaultValue: '192.168.100.17',
  );

  /// Default port for the FastAPI streaming service.
  static int _serverPort = int.fromEnvironment(
    'OLOF_SERVER_PORT',
    defaultValue: 8080,
  );

  /// Current configured server host IP or hostname.
  static String get serverHost => _serverHost;

  /// Current configured server port.
  static int get serverPort => _serverPort;

  /// Base HTTP API URL, e.g. "http://192.168.100.17:8080"
  static String get baseUrl => 'http://$_serverHost:$_serverPort';

  /// Base static streaming files URL, e.g. "http://192.168.100.17:8080/files"
  static String get filesUrl => '$baseUrl/files';

  /// WebSocket URL for LAN queue broadcasting, e.g. "ws://192.168.100.17:8080/ws/queue"
  static String get wsUrl => 'ws://$_serverHost:$_serverPort/ws/queue';

  /// Updates the server host/port dynamically from clinic tablet settings.
  static void configure({String? host, int? port}) {
    if (host != null && host.trim().isNotEmpty) {
      _serverHost = host.trim();
    }
    if (port != null && port > 0) {
      _serverPort = port;
    }
  }

  /// Resolves a file URL or path to a full streaming URL.
  ///
  /// Examples:
  /// - `resolveFileUrl("http://...")` -> returns as is
  /// - `resolveFileUrl("/files/photos/abc.jpg")` -> "http://192.168.100.17:8080/files/photos/abc.jpg"
  /// - `resolveFileUrl("photos/abc.jpg")` -> "http://192.168.100.17:8080/files/photos/abc.jpg"
  static String resolveFileUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) {
      return '';
    }

    final trimmed = pathOrUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/files/')) {
      return '$baseUrl$trimmed';
    }

    if (trimmed.startsWith('files/')) {
      return '$baseUrl/$trimmed';
    }

    return '$filesUrl/$trimmed';
  }
}
