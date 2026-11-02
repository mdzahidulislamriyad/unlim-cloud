import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cloud_file.dart';
import '../view_models/storage_view_model.dart';
import 'package:provider/provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  final CloudFile file;
  final String videoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.file,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _statusMessage = 'Buffering video stream...';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startPlayback();
  }

  Future<void> _startPlayback() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _statusMessage = 'Connecting to video stream...';
    });

    final vm = context.read<StorageViewModel>();
    String streamUrl = widget.videoUrl;

    // 1. Attempt Direct Streaming via Network URL
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
      );

      await controller.initialize().timeout(const Duration(seconds: 10));
      _setupChewie(controller);
      return;
    } catch (_) {
      // Direct stream failed. Try fetching fresh URL in case of stale path
      try {
        final freshUrl = await vm.getDownloadUrl(widget.file);
        if (freshUrl != null && freshUrl != streamUrl) {
          streamUrl = freshUrl;
          final retryController = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
          await retryController.initialize().timeout(const Duration(seconds: 10));
          _setupChewie(retryController);
          return;
        }
      } catch (_) {}
    }

    // 2. Seamless Auto-Fallback: Download file locally and play smoothly
    if (mounted) {
      setState(() {
        _statusMessage = 'Buffering & preparing playback...';
      });

      final localPath = await vm.downloadFile(widget.file);

      if (localPath != null && mounted) {
        try {
          final fileController = VideoPlayerController.file(File(localPath));
          await fileController.initialize();
          _setupChewie(fileController);
          return;
        } catch (e) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = e.toString();
              _isLoading = false;
            });
          }
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Could not load video. Please verify connection.';
      });
    }
  }

  void _setupChewie(VideoPlayerController controller) {
    if (!mounted) return;

    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = controller;

    _chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppTheme.primaryTeal,
        handleColor: AppTheme.primaryTeal,
        backgroundColor: Colors.grey.withOpacity(0.5),
        bufferedColor: Colors.white.withOpacity(0.3),
      ),
    );

    setState(() {
      _isLoading = false;
      _hasError = false;
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<StorageViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        title: Text(
          widget.file.name,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download to Device',
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
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              )
            : _hasError
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_off_outlined, color: Colors.orange, size: 54),
                        const SizedBox(height: 16),
                        const Text(
                          'Playback Error',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry Playback'),
                          onPressed: _startPlayback,
                        ),
                      ],
                    ),
                  )
                : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                    ? Chewie(controller: _chewieController!)
                    : const SizedBox.shrink(),
      ),
    );
  }
}
