enum CommandType {
  token,
  startRecording,
  stopRecording,
  cancelRecording,
  rfId,
  dateTime,
  standby,
  sendLocation,
  ipAddress,
  visitId,
  config,
  version,
  startStatus,
  stopStatus,
  cancelStatus,
  unknown;

  bool get isRecordingType => switch (this) {
        startRecording || stopRecording || cancelRecording => true,
        _ => false,
      };

  String get stringValue => switch (this) {
        dateTime => 'DATE_TIME',
        standby => 'STANDBY',
        rfId => 'RFID',
        token => 'TOKEN',
        startRecording => 'START_RECORDING',
        stopRecording => 'STOP_RECORDING',
        cancelRecording => 'CANCEL_RECORDING',
        sendLocation => 'SEND_LOCATION',
        ipAddress => 'IP_ADDRESS',
        visitId => 'VISIT_ID',
        config => 'CONFIG',
        version => 'VERSION',
        startStatus => 'START_STATUS',
        stopStatus => 'STOP_STATUS',
        cancelStatus => 'CANCEL_STATUS',
        unknown => 'UNKNOWN',
      };

  static CommandType fromString(String value) => switch (value) {
        'STOP_RECORDING' => stopRecording,
        'CANCEL_RECORDONG' => cancelRecording,
        _ => () {
            if (value.startsWith('TOKEN')) return token;
            if (value.startsWith('RFID')) return rfId;
            if (value.startsWith('START_RECORDING')) return startRecording;
            if (value.startsWith('DATE_TIME')) return dateTime;
            if (value.startsWith('STANDBY')) return standby;
            if (value.startsWith('SEND_LOCATION')) return sendLocation;
            if (value.startsWith('IP_ADDRESS')) return ipAddress;
            if (value.startsWith('VISIT_ID')) return visitId;
            if (value.startsWith('CONFIG')) return config;
            if (value.startsWith('VERSION')) return version;
            if (value.startsWith('START_STATUS')) return startStatus;
            if (value.startsWith('STOP_STATUS')) return stopStatus;
            if (value.startsWith('CANCEL_RECORDING')) return cancelRecording;
            return unknown;
          }(),
      };
}
