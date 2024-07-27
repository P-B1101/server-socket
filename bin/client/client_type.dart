enum ClientType {
  androidCamera,
  androidInterface,
  raspberrypi3DCamera,
  unknown;

  String get stringValue => switch (this) {
        androidCamera => 'ANDROID_CAMERA',
        androidInterface => 'ANDROID_INTERFACE',
        raspberrypi3DCamera => 'RASPBERRYPI_3D_CAMERA',
        unknown => '',
      };

  static ClientType fromString(String value) => switch (value) {
        'ANDROID_CAMERA' => androidCamera,
        'ANDROID_INTERFACE' => androidInterface,
        'RASPBERRYPI_3D_CAMERA' => raspberrypi3DCamera,
        _ => unknown,
      };
}
