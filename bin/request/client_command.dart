enum ClientCommand {
  token,
  startRecording,
  stopRecording,
  rfId,
  dateTime,
  standby,
  unknown;

  String get stringValue => switch (this) {
        dateTime => 'DATE_TIME',
        standby => 'STANDBY',
        rfId => 'RF_ID',
        token => 'TOKEN',
        startRecording => 'START_RECORDING',
        stopRecording => 'STOP_RECORDING',
        unknown => 'UNKNOWN',
      };

  static ClientCommand fromString(String value) => switch (value) {
        'TOKEN' => token,
        'START_RECORDING' => startRecording,
        'STOP_RECORDING' => stopRecording,
        _ => () {
            if (value.startsWith('RF_ID')) return rfId;
            if (value.startsWith('START_RECORDING')) return startRecording;
            if (value.startsWith('DATE_TIME')) return dateTime;
            if (value.startsWith('STANDBY')) return standby;
            return unknown;
          }(),
      };
}
