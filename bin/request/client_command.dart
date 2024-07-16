enum ClientCommand {
  authentication,
  token,
  openCamera,
  startRecording,
  stopRecording,
  sendVideo,
  unknown;

  String get stringValue => switch (this) {
        authentication => 'AUTHENTICATION',
        token => 'TOKEN',
        startRecording => 'START_RECORDING',
        openCamera => 'OPEN_CAMERA',
        stopRecording => 'STOP_RECORDING',
        sendVideo => 'SEND_VIDEO',
        unknown => 'UNKNOWN',
      };

  static ClientCommand fromString(String value) => switch (value) {
        'AUTHENTICATION' => authentication,
        'TOKEN' => token,
        'OPEN_CAMERA' => openCamera,
        'START_RECORDING' => startRecording,
        'STOP_RECORDING' => stopRecording,
        'SEND_VIDEO' => sendVideo,
        _ => unknown,
      };
}
