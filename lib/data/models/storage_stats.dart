import 'cloud_file.dart';

class StorageStats {
  final int totalFiles;
  final int totalBytes;
  final int photoBytes;
  final int videoBytes;
  final int audioBytes;
  final int documentBytes;
  final int otherBytes;

  StorageStats({
    required this.totalFiles,
    required this.totalBytes,
    required this.photoBytes,
    required this.videoBytes,
    required this.audioBytes,
    required this.documentBytes,
    required this.otherBytes,
  });

  factory StorageStats.calculate(List<CloudFile> files) {
    int total = 0;
    int photo = 0;
    int video = 0;
    int audio = 0;
    int doc = 0;
    int other = 0;

    for (final f in files) {
      total += f.size;
      switch (f.type) {
        case 'photo':
          photo += f.size;
          break;
        case 'video':
          video += f.size;
          break;
        case 'audio':
          audio += f.size;
          break;
        case 'document':
          doc += f.size;
          break;
        default:
          other += f.size;
          break;
      }
    }

    return StorageStats(
      totalFiles: files.length,
      totalBytes: total,
      photoBytes: photo,
      videoBytes: video,
      audioBytes: audio,
      documentBytes: doc,
      otherBytes: other,
    );
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
