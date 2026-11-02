import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cloud_file.dart';
import '../view_models/storage_view_model.dart';

class ImageViewerScreen extends StatelessWidget {
  final CloudFile file;
  final String imageUrl;

  const ImageViewerScreen({
    super.key,
    required this.file,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<StorageViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        foregroundColor: Colors.white,
        title: Text(file.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(
              file.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: file.isFavorite ? Colors.amber : Colors.white,
            ),
            onPressed: () => vm.toggleFavorite(file.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Share.share(imageUrl);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading "${file.name}"...')),
              );
              final path = await vm.downloadFile(file);
              if (path != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Saved to Downloads!'),
                    action: SnackBarAction(label: 'Open', onPressed: () => vm.openFile(path)),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
            errorWidget: (context, url, error) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Failed to load image preview', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => vm.downloadFile(file),
                    child: const Text('Download Full File'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
