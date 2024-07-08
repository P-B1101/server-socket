enum BodyType {
  file,
  json,
  unknown;

  String get stringValue => switch (this) {
        file => 'FILE',
        json => 'JSON',
        unknown => 'UNKNOWN',
      };

  static BodyType fromJson(String value) => switch (value) {
        'FILE' => file,
        'JSON' => json,
        _ => unknown,
      };
}
