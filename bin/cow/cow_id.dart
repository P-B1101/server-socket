class CowId {
  final String? id;
  final String? rfId;
  const CowId({
    required this.id,
    required this.rfId,
  });

  String? get serialize {
    if (id == null && rfId == null) return null;
    if (id == null) return 'NULL:$rfId';
    if (rfId == null) return '$id:NULL';
    return '$id:$rfId';
  }
}
