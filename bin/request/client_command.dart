enum ClientCommand {
  token,
  startRecording,
  stopRecording,
  unknown;

  String get stringValue => switch (this) {
        token => 'TOKEN',
        startRecording => 'START_RECORDING',
        stopRecording => 'STOP_RECORDING',
        unknown => 'UNKNOWN',
      };

  static ClientCommand fromString(String value) => switch (value) {
        'TOKEN' => token,
        'START_RECORDING' => startRecording,
        'STOP_RECORDING' => stopRecording,
        _ => unknown,
      };
}
