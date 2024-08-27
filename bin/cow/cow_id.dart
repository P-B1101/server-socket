import 'dart:math';

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
    if (id == null && rfId == null) return '0__0';
    if (id == null) return '0__$rfId';
    if (rfId == null) return '${id}__0';
    return '${id!.substring(0, min(id!.length, 4))}__${rfId!.substring(0, min(rfId!.length, 15))}';
  }
}
