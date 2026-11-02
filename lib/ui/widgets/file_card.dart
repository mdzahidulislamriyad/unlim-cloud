import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cloud_file.dart';

class FileCard extends StatelessWidget {
  final CloudFile file;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const FileCard({
    super.key,
    required this.file,
    required this.onTap,
    required this.onFavorite,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
  });

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'photo':
        return Icons.image_outlined;
      case 'video':
        return Icons.movie_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'archive':
        return Icons.archive_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'photo':
        return AppTheme.colorPhoto;
      case 'video':
        return AppTheme.colorVideo;
      case 'audio':
        return AppTheme.colorAudio;
      case 'document':
        return AppTheme.colorDocument;
      case 'archive':
        return AppTheme.colorArchive;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(file.type);
    final dateStr = DateFormat('MMM dd, yyyy').format(file.uploadDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getTypeIcon(file.type), color: typeColor, size: 24),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(file.formattedSize, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                file.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: file.isFavorite ? Colors.amber : Colors.grey,
                size: 22,
              ),
              onPressed: onFavorite,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) {
                if (val == 'download') onDownload();
                if (val == 'rename') onRename();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Download'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
