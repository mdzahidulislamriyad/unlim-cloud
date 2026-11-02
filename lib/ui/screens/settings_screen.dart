import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../view_models/storage_view_model.dart';
import 'setup_guide_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _tokenController;
  late final TextEditingController _chatIdController;
  late final TextEditingController _customServerController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<StorageViewModel>();
    _tokenController = TextEditingController(text: vm.botToken);
    _chatIdController = TextEditingController(text: vm.chatId);
    _customServerController = TextEditingController(text: vm.customApiServer);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _chatIdController.dispose();
    _customServerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StorageViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Telegram Cloud Storage',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text('Guide'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SetupGuideScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'Telegram Bot Token',
                      hintText: '123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ',
                      prefixIcon: const Icon(Icons.smart_toy_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chatIdController,
                    decoration: InputDecoration(
                      labelText: 'Storage Channel or Chat ID',
                      hintText: '-100xxxxxxxxxx or @your_channel',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customServerController,
                    decoration: InputDecoration(
                      labelText: 'Custom API Server (Optional - for 2GB files)',
                      hintText: 'https://api.telegram.org (Default: 50MB)',
                      prefixIcon: const Icon(Icons.dns_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (vm.connectionStatusMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: vm.isConnected
                            ? Colors.green.withOpacity(0.12)
                            : Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            vm.isConnected ? Icons.check_circle : Icons.error_outline,
                            color: vm.isConnected ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              vm.connectionStatusMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: vm.isConnected ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: vm.isConnecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        vm.isConnecting ? 'Testing Connection...' : 'Save & Test Connection',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: vm.isConnecting
                          ? null
                          : () async {
                              final success = await vm.saveCredentials(
                                botToken: _tokenController.text,
                                chatId: _chatIdController.text,
                                customApiServer: _customServerController.text,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Connection Successful!' : 'Connection Failed!'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Preferences Card
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use sleek dark theme'),
                  value: vm.isDarkMode,
                  onChanged: (_) => vm.toggleTheme(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.sync_rounded),
                  title: const Text('Auto-Backup Photos'),
                  subtitle: const Text('Automatically backup camera pictures'),
                  value: vm.isAutoBackup,
                  onChanged: (_) => vm.toggleAutoBackup(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Storage Management Card
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: Colors.orange),
                  title: const Text('Clear Local Cache'),
                  subtitle: const Text('Removes local index without deleting cloud files'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Local Cache?'),
                        content: const Text('This will reset your local file view. Your files on Telegram will NOT be deleted.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await vm.clearAllCache();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Local cache cleared!')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          Center(
            child: Column(
              children: [
                Text(
                  'UnLim Cloud v1.0.0',
                  style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Free Unlimited Cloud Storage powered by Telegram',
                  style: TextStyle(fontSize: 11, color: Colors.grey.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
