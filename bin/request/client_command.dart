enum ClientCommand {
  token,
  startRecording,
  stopRecording,
  refId,
  unknown;

  String get stringValue => switch (this) {
        refId => 'REF_ID',
        token => 'TOKEN',
        startRecording => 'START_RECORDING',
        stopRecording => 'STOP_RECORDING',
        unknown => 'UNKNOWN',
      };

  static ClientCommand fromString(String value) => switch (value) {
        'TOKEN' => token,
        'START_RECORDING' => startRecording,
        'STOP_RECORDING' => stopRecording,
        _ => value.startsWith('REF_ID') ? refId : unknown,
      };
}
