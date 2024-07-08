enum Method {
  command,
  sendFile,
  authentication,
  unknown;

  String get stringValue => switch (this) {
        command => 'COMMAND',
        sendFile => 'SEND_FILE',
        authentication => 'AUTHENTICATION',
        unknown => 'UNKNOWN',
      };

  static Method fromJson(String value) => switch (value) {
        'COMMAND' => command,
        'SEND_FILE' => sendFile,
        'AUTHENTICATION' => authentication,
        _ => unknown,
      };
}
