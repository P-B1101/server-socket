enum ClientType {
  androidCamera,
  androidInterface,
  unknown;

  String get stringValue => switch (this) {
        androidCamera => 'ANDROID_CAMERA',
        androidInterface => 'ANDROID_INTERFACE',
        unknown => '',
      };

  static ClientType fromString(String value) => switch (value) {
        'ANDROID_CAMERA' => androidCamera,
        'ANDROID_INTERFACE' => androidInterface,
        _ => unknown,
      };
}
