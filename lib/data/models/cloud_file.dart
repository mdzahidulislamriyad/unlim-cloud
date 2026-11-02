import '../models/cloud_folder.dart';

class CloudFile {
  final String id;
  final String name;
  final int size; // bytes
  final String type; // photo, video, audio, document, archive, other
  final String extension;
  final DateTime uploadDate;
  final String telegramFileId;
  final int telegramMessageId;
  final String? folderId;
  final bool isFavorite;
  final String? mimeType;
  final String? localPath;
  final String? directDownloadUrl;

  CloudFile({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.extension,
    required this.uploadDate,
    required this.telegramFileId,
    required this.telegramMessageId,
    this.folderId,
    this.isFavorite = false,
    this.mimeType,
    this.localPath,
    this.directDownloadUrl,
  });

  CloudFile copyWith({
    String? id,
    String? name,
    int? size,
    String? type,
    String? extension,
    DateTime? uploadDate,
    String? telegramFileId,
    int? telegramMessageId,
    String? folderId,
    bool? isFavorite,
    String? mimeType,
    String? localPath,
    String? directDownloadUrl,
  }) {
    return CloudFile(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      type: type ?? this.type,
      extension: extension ?? this.extension,
      uploadDate: uploadDate ?? this.uploadDate,
      telegramFileId: telegramFileId ?? this.telegramFileId,
      telegramMessageId: telegramMessageId ?? this.telegramMessageId,
      folderId: folderId ?? this.folderId,
      isFavorite: isFavorite ?? this.isFavorite,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      directDownloadUrl: directDownloadUrl ?? this.directDownloadUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'type': type,
      'extension': extension,
      'uploadDate': uploadDate.toIso8601String(),
      'telegramFileId': telegramFileId,
      'telegramMessageId': telegramMessageId,
      'folderId': folderId,
      'isFavorite': isFavorite,
      'mimeType': mimeType,
      'localPath': localPath,
      'directDownloadUrl': directDownloadUrl,
    };
  }

  factory CloudFile.fromJson(Map<String, dynamic> json) {
    return CloudFile(
      id: json['id'] as String,
      name: json['name'] as String,
      size: json['size'] as int? ?? 0,
      type: json['type'] as String? ?? 'other',
      extension: json['extension'] as String? ?? '',
      uploadDate: json['uploadDate'] != null 
          ? DateTime.parse(json['uploadDate'] as String) 
          : DateTime.now(),
      telegramFileId: json['telegramFileId'] as String? ?? '',
      telegramMessageId: json['telegramMessageId'] as int? ?? 0,
      folderId: json['folderId'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      mimeType: json['mimeType'] as String?,
      localPath: json['localPath'] as String?,
      directDownloadUrl: json['directDownloadUrl'] as String?,
    );
  }

  static String detectTypeFromExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'heic'].contains(e)) {
      return 'photo';
    } else if (['mp4', 'mkv', 'mov', 'avi', 'flv', 'webm', '3gp'].contains(e)) {
      return 'video';
    } else if (['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a', 'opus'].contains(e)) {
      return 'audio';
    } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(e)) {
      return 'document';
    } else if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(e)) {
      return 'archive';
    }
    return 'other';
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
