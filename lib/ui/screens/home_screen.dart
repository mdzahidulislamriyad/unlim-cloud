import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../view_models/storage_view_model.dart';
import '../widgets/stat_cards.dart';
import '../widgets/file_card.dart';
import '../widgets/create_folder_dialog.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';
import 'setup_guide_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int tabIndex) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StorageViewModel>();
    final stats = vm.getStats();
    final recentFiles = vm.getRecentFiles(6);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_circle_rounded, color: AppTheme.primaryTeal, size: 28),
            ),
            const SizedBox(width: 10),
            const Text('UnLim Cloud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          // Connection Status Pill
          GestureDetector(
            onTap: () {
              if (!vm.isConnected) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupGuideScreen()));
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: vm.isConnected
                    ? Colors.green.withOpacity(0.15)
                    : Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: vm.isConnected ? Colors.green : Colors.amber,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: vm.isConnected ? Colors.green : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vm.isConnected ? 'Connected' : 'Setup Bot',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: vm.isConnected ? Colors.green : Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger refresh
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            // Setup Banner if not configured
            if (!vm.isConnected)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryTeal.withOpacity(0.15),
                      AppTheme.primaryCyan.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryTeal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connect Telegram Cloud',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Get unlimited free storage via Telegram Bot in 2 minutes.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupGuideScreen()));
                      },
                      child: const Text('Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // Storage Overview Card
            StorageOverviewCard(stats: stats),

            // Category Quick Filter Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildCategoryChip(context, vm, 'Photos', 'photo', Icons.image_rounded, AppTheme.colorPhoto),
                      const SizedBox(width: 8),
                      _buildCategoryChip(context, vm, 'Videos', 'video', Icons.movie_rounded, AppTheme.colorVideo),
                      const SizedBox(width: 8),
                      _buildCategoryChip(context, vm, 'Audio', 'audio', Icons.audiotrack_rounded, AppTheme.colorAudio),
                      const SizedBox(width: 8),
                      _buildCategoryChip(context, vm, 'Docs', 'document', Icons.description_rounded, AppTheme.colorDocument),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Files Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Files',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      vm.setCategory('all');
                      onNavigateTab(1); // switch to Files tab
                    },
                    child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal)),
                  ),
                ],
              ),
            ),

            if (recentFiles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 54, color: Colors.grey.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'No files uploaded yet',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap the + button below to upload your first file to Telegram cloud!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentFiles.map(
                (file) => FileCard(
                  file: file,
                  onTap: () async {
                    if (file.type == 'photo') {
                      final url = await vm.getDownloadUrl(file);
                      if (url != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageViewerScreen(file: file, imageUrl: url),
                          ),
                        );
                      }
                    } else if (file.type == 'video') {
                      final url = await vm.getDownloadUrl(file);
                      if (url != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(file: file, videoUrl: url),
                          ),
                        );
                      }
                    } else {
                      // Trigger download or view
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading "${file.name}"...')),
                      );
                      await vm.downloadFile(file);
                    }
                  },
                  onFavorite: () => vm.toggleFavorite(file.id),
                  onDownload: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading "${file.name}"...')),
                    );
                    final path = await vm.downloadFile(file);
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved to Downloads!'),
                          action: SnackBarAction(label: 'Open', onPressed: () => vm.openFile(path)),
                        ),
                      );
                    }
                  },
                  onRename: () async {
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (_) => CreateFolderDialog(initialName: file.name, isRename: true),
                    );
                    if (newName != null) vm.renameFile(file.id, newName);
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete File?'),
                        content: Text('Delete "${file.name}" from Telegram cloud?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) vm.deleteFile(file.id);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    StorageViewModel vm,
    String label,
    String categoryKey,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          vm.setCategory(categoryKey);
          onNavigateTab(1); // Switch to files tab
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
