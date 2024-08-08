enum CameraLocation {
  frontLeft,
  frontRight,
  backLeft,
  backRight,
  notSet;

  String get stringValue => switch (this) {
        frontLeft => 'FRONT_LEFT',
        frontRight => 'FRONT_RIGHT',
        backLeft => 'BACK_LEFT',
        backRight => 'BACK_RIGHT',
        notSet => '',
      };

  int? get intValue => switch (this) {
        frontLeft => 2,
        frontRight => 3,
        backLeft => 1,
        backRight => 4,
        notSet => null,
      };

  static CameraLocation fronInt(int? value) => switch (value) {
        2 => frontLeft,
        3 => frontRight,
        1 => backLeft,
        4 => backRight,
        _ => notSet,
      };

  static CameraLocation fromString(String value) => switch (value) {
        'FRONT_LEFT' => frontLeft,
        'FRONT_RIGHT' => frontRight,
        'BACK_LEFT' => backLeft,
        'BACK_RIGHT' => backRight,
        _ => notSet,
      };
}
