class MediaItem {
  final String id;
  final String owner;
  final String filename;
  final String mime;
  final int size;
  final String checksum;
  final int createdAt;

  const MediaItem({
    required this.id,
    required this.owner,
    required this.filename,
    required this.mime,
    required this.size,
    required this.checksum,
    required this.createdAt,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
    id: json['id']?.toString() ?? '',
    owner: json['owner']?.toString() ?? '',
    filename: json['filename']?.toString() ?? '',
    mime: json['mime']?.toString() ?? '',
    size: (json['size'] as num?)?.toInt() ?? 0,
    checksum: json['checksum']?.toString() ?? '',
    createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner': owner,
    'filename': filename,
    'mime': mime,
    'size': size,
    'checksum': checksum,
    'created_at': createdAt,
  };
}
