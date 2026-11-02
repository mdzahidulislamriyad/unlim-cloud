import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../view_models/storage_view_model.dart';
import '../widgets/folder_card.dart';
import '../widgets/file_card.dart';
import '../widgets/create_folder_dialog.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StorageViewModel>();
    final folders = vm.getCurrentFolders();
    final files = vm.getCurrentFiles();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Sort Menu
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort by',
            onSelected: (mode) => vm.setSortMode(mode),
            itemBuilder: (context) => [
              const PopupMenuItem(value: SortMode.dateDesc, child: Text('Date (Newest First)')),
              const PopupMenuItem(value: SortMode.dateAsc, child: Text('Date (Oldest First)')),
              const PopupMenuItem(value: SortMode.nameAsc, child: Text('Name (A-Z)')),
              const PopupMenuItem(value: SortMode.sizeDesc, child: Text('Size (Largest First)')),
            ],
          ),
          // New Folder Button
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Folder',
            onPressed: () async {
              final name = await showDialog<String>(
                context: context,
                builder: (_) => const CreateFolderDialog(),
              );
              if (name != null) vm.createFolder(name);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => vm.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search files and folders...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          vm.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),

          // Category Horizontal Scroll Tabs
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildFilterPill(vm, 'All', 'all'),
                _buildFilterPill(vm, 'Photos', 'photo'),
                _buildFilterPill(vm, 'Videos', 'video'),
                _buildFilterPill(vm, 'Audio', 'audio'),
                _buildFilterPill(vm, 'Documents', 'document'),
                _buildFilterPill(vm, 'Favorites', 'favorites'),
              ],
            ),
          ),

          // Breadcrumbs Bar (if inside folder)
          if (vm.breadcrumbs.isNotEmpty && vm.selectedCategory == 'all')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).cardColor.withOpacity(0.5),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => vm.navigateToRoot(),
                      child: const Row(
                        children: [
                          Icon(Icons.home_outlined, size: 18, color: AppTheme.primaryTeal),
                          SizedBox(width: 4),
                          Text('Root', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    for (int i = 0; i < vm.breadcrumbs.length; i++) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () => vm.navigateToBreadcrumb(i),
                        child: Text(
                          vm.breadcrumbs[i].name,
                          style: TextStyle(
                            fontWeight: i == vm.breadcrumbs.length - 1 ? FontWeight.bold : FontWeight.normal,
                            color: i == vm.breadcrumbs.length - 1 ? null : AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          // Files & Folders List
          Expanded(
            child: folders.isEmpty && files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 60, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'This folder is empty',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Upload files or create sub-folders',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 90, top: 6),
                    children: [
                      // Folders List
                      if (folders.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Text(
                            'FOLDERS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        ...folders.map(
                          (folder) => FolderCard(
                            folder: folder,
                            onTap: () => vm.openFolder(folder),
                            onRename: () async {
                              final name = await showDialog<String>(
                                context: context,
                                builder: (_) => CreateFolderDialog(initialName: folder.name, isRename: true),
                              );
                              if (name != null) vm.renameFolder(folder.id, name);
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Folder?'),
                                  content: Text('Delete "${folder.name}"? Files will be moved to root.'),
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
                              if (confirm == true) vm.deleteFolder(folder.id);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Files List
                      if (files.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Text(
                            'FILES (${files.length})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        ...files.map(
                          (file) => FileCard(
                            file: file,
                            onTap: () async {
                              if (file.type == 'photo') {
                                final url = await vm.getDownloadUrl(file);
                                if (url != null && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ImageViewerScreen(file: file, imageUrl: url)),
                                  );
                                }
                              } else if (file.type == 'video') {
                                final url = await vm.getDownloadUrl(file);
                                if (url != null && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => VideoPlayerScreen(file: file, videoUrl: url)),
                                  );
                                }
                              } else {
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
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(StorageViewModel vm, String label, String key) {
    final isSelected = vm.selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => vm.setCategory(key),
        selectedColor: AppTheme.primaryTeal.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryTeal,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryTeal : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
