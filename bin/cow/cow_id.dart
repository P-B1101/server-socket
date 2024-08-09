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

  String? get fileNameFormatted {
    if (id == null && rfId == null) return 'NULL__NULL';
    if (id == null) return 'NULL__$rfId';
    if (rfId == null) return '${id}__NULL';
    return '${id}__$rfId';
  }
}
