enum ClientCommand {
  startRecording,
  stopRecording,
  sendVideo,
  unknown;

  String get stringValue => switch (this) {
        startRecording => 'START_RECORDING',
        stopRecording => 'STOP_RECORDING',
        sendVideo => 'SEND_VIDEO',
        unknown => 'UNKNOWN',
      };

  static ClientCommand fromString(String value) => switch (value) {
        'START_RECORDING' => startRecording,
        'STOP_RECORDING' => stopRecording,
        'SEND_VIDEO' => sendVideo,
        _ => unknown,
      };
}
