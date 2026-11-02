import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cloud_file.dart';
import '../view_models/storage_view_model.dart';

class ImageViewerScreen extends StatefulWidget {
  final CloudFile file;
  final String imageUrl;

  const ImageViewerScreen({
    super.key,
    required this.file,
    required this.imageUrl,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  Uint8List? _imageBytes;
  String? _localFilePath;
  String _statusMessage = 'Loading image preview...';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _statusMessage = 'Fetching from cloud...';
    });

    try {
      // 1. Try direct HTTP fetch
      final response = await http.get(Uri.parse(widget.imageUrl)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // 2. Fallback: Download file directly to local storage & display
    if (mounted) {
      setState(() {
        _statusMessage = 'Downloading image to view...';
      });
      final vm = context.read<StorageViewModel>();
      final path = await vm.downloadFile(widget.file);
      if (path != null && mounted) {
        setState(() {
          _localFilePath = path;
          _isLoading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'Could not load image';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<StorageViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        title: Text(widget.file.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(
              widget.file.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: widget.file.isFavorite ? Colors.amber : Colors.white,
            ),
            onPressed: () => vm.toggleFavorite(widget.file.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              if (_localFilePath != null) {
                Share.shareXFiles([XFile(_localFilePath!)]);
              } else {
                Share.share(widget.imageUrl);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading "${widget.file.name}"...')),
              );
              final path = await vm.downloadFile(widget.file);
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
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryTeal),
                  const SizedBox(height: 16),
                  Text(_statusMessage, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              )
            : _hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_statusMessage, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry Loading'),
                        onPressed: _loadImage,
                      ),
                    ],
                  )
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            fit: BoxFit.contain,
                          )
                        : _localFilePath != null
                            ? Image.file(
                                File(_localFilePath!),
                                fit: BoxFit.contain,
                              )
                            : Image.network(
                                widget.imageUrl,
                                fit: BoxFit.contain,
                              ),
                  ),
      ),
    );
  }
}
