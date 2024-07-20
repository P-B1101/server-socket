class CowId {
  final String? id;
  final String? refId;
  const CowId({
    required this.id,
    required this.refId,
  });

  String? get serialize {
    if (id == null && refId == null) return null;
    if (id == null) return 'NULL:$refId';
    if (refId == null) return '$id:NULL';
    return '$id:$refId';
  }
}
