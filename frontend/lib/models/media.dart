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

  /// Whether this media is audio (by mime).
  bool get isAudio => _isAudioMime(mime);

  /// Whether this media is image (by mime).
  bool get isImage => _isImageMime(mime);

  /// Placeholder prefix for entry value: "audio" or "image". Use to build [audio:id] / [image:id].
  String get placeholderPrefix => _placeholderPrefix(mime);

  /// Suggested suffix for field name: "audio" or "img".
  String get fieldNameSuffix => _fieldNameSuffix(mime);

  /// Entry value for this media, e.g. [audio:abc123] or [image:abc123].
  String get entryPlaceholder => '[$placeholderPrefix:$id]';

  static bool _isAudioMime(String mime) =>
      mime.isNotEmpty && mime.toLowerCase().startsWith('audio/');

  static bool _isImageMime(String mime) =>
      mime.isNotEmpty && mime.toLowerCase().startsWith('image/');

  static String _placeholderPrefix(String mime) =>
      _isAudioMime(mime) ? 'audio' : 'image';

  static String _fieldNameSuffix(String mime) =>
      _isAudioMime(mime) ? 'audio' : 'img';

  /// Mime-based helpers for use before having a MediaItem (e.g. from file picker).
  static bool isAudioMime(String mime) => _isAudioMime(mime);
  static bool isImageMime(String mime) => _isImageMime(mime);
  static String placeholderPrefixForMime(String mime) =>
      _placeholderPrefix(mime);
  static String fieldNameSuffixForMime(String mime) => _fieldNameSuffix(mime);

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
