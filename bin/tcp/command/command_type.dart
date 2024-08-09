enum CommandType {
  token,
  startRecording,
  stopRecording,
  rfId,
  dateTime,
  standby,
  sendLocation,
  ipAddress,
  visitId,
  unknown;

  String get stringValue => switch (this) {
        dateTime => 'DATE_TIME',
        standby => 'STANDBY',
        rfId => 'RFID',
        token => 'TOKEN',
        startRecording => 'START_RECORDING',
        stopRecording => 'STOP_RECORDING',
        sendLocation => 'SEND_LOCATION',
        ipAddress => 'IP_ADDRESS',
        visitId => 'VISIT_ID',
        unknown => 'UNKNOWN',
      };

  static CommandType fromString(String value) => switch (value) {
        'TOKEN' => token,
        'START_RECORDING' => startRecording,
        'STOP_RECORDING' => stopRecording,
        _ => () {
            if (value.startsWith('RFID')) return rfId;
            if (value.startsWith('START_RECORDING')) return startRecording;
            if (value.startsWith('DATE_TIME')) return dateTime;
            if (value.startsWith('STANDBY')) return standby;
            if (value.startsWith('SEND_LOCATION')) return sendLocation;
            if (value.startsWith('IP_ADDRESS')) return ipAddress;
            if (value.startsWith('VISIT_ID')) return visitId;
            return unknown;
          }(),
      };
}
