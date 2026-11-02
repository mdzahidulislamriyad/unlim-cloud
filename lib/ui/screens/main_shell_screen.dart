import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/download_manager_service.dart';
import '../view_models/storage_view_model.dart';
import '../widgets/create_folder_dialog.dart';
import 'home_screen.dart';
import 'files_screen.dart';
import 'transfers_screen.dart';
import 'settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _onNavigateTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showAddBottomSheet(BuildContext context, StorageViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add to Telegram Cloud',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryTeal),
              ),
              title: const Text('Upload Files', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Photos, videos, audio, documents, archives'),
              onTap: () async {
                Navigator.pop(ctx);
                if (!vm.isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please configure your Telegram Bot in Settings first!')),
                  );
                  _onNavigateTab(3); // Go to Settings
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uploading file(s) to Telegram cloud...')),
                );
                final uploaded = await vm.pickAndUploadFiles();
                if (uploaded > 0 && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully uploaded $uploaded file(s)!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.colorArchive.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.drive_folder_upload_rounded, color: AppTheme.colorArchive),
              ),
              title: const Text('Upload Folder', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Upload an entire folder and all its files'),
              onTap: () async {
                Navigator.pop(ctx);
                if (!vm.isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please configure your Telegram Bot in Settings first!')),
                  );
                  _onNavigateTab(3);
                  return;
                }

                final folderName = await showDialog<String>(
                  context: context,
                  builder: (dCtx) {
                    final controller = TextEditingController(text: 'New Folder');
                    return AlertDialog(
                      title: const Text('Create & Upload Folder'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Folder Name',
                          hintText: 'e.g. Vacation, Documents',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dCtx, controller.text.trim()),
                          child: const Text('Select Files'),
                        ),
                      ],
                    );
                  },
                );

                if (folderName != null && folderName.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Select files for "$folderName"...')),
                  );
                  final count = await vm.pickAndUploadFilesToFolder(folderName);
                  if (count > 0 && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Uploaded $count file(s) into "$folderName"!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.create_new_folder_rounded, color: AppTheme.primaryCyan),
              ),
              title: const Text('Create Folder', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Organize your files into virtual folders'),
              onTap: () async {
                Navigator.pop(ctx);
                final name = await showDialog<String>(
                  context: context,
                  builder: (_) => const CreateFolderDialog(),
                );
                if (name != null) vm.createFolder(name);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StorageViewModel>();

    final screens = [
      HomeScreen(onNavigateTab: _onNavigateTab),
      const FilesScreen(),
      const TransfersScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          if (vm.activeTransfer != null && _currentIndex != 2)
            _buildActiveTransferBar(context, vm.activeTransfer!),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBottomSheet(context, vm),
        tooltip: 'Upload or Create Folder',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder_rounded),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: vm.hasActiveTransfer,
              backgroundColor: AppTheme.primaryTeal,
              smallSize: 8,
              child: const Icon(Icons.swap_vert_rounded),
            ),
            activeIcon: Badge(
              isLabelVisible: vm.hasActiveTransfer,
              backgroundColor: AppTheme.primaryTeal,
              smallSize: 8,
              child: const Icon(Icons.swap_vert_rounded),
            ),
            label: 'Transfers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTransferBar(BuildContext context, TransferItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNavigateTab(2), // Switch to Transfers tab
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF131D2A),
            border: Border(
              top: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.3), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.isUpload ? Icons.cloud_upload_rounded : Icons.cloud_download_rounded,
                      color: AppTheme.primaryTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isUpload ? 'Uploading ${item.fileName}' : 'Downloading ${item.fileName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.formattedProgress} • ${(item.bytesTransferred / (1024 * 1024)).toStringAsFixed(1)} MB / ${(item.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.formattedProgress,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primaryTeal),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress > 0 ? item.progress : null,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  color: AppTheme.primaryTeal,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
