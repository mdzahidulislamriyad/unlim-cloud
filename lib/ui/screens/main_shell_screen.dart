import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBottomSheet(context, vm),
        tooltip: 'Upload or Create Folder',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder_rounded),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_vert_rounded),
            activeIcon: Icon(Icons.swap_vert_rounded),
            label: 'Transfers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
