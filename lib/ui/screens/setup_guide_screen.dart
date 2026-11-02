import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class SetupGuideScreen extends StatelessWidget {
  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Setup Guide', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: AppTheme.primaryTeal, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Setup takes less than 2 minutes and gives you 100% free, unlimited storage forever!',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildStepCard(
            context,
            stepNumber: '1',
            title: 'Create Your Telegram Bot',
            description: '1. Open the Telegram app on your phone.\n'
                '2. Search for "@BotFather" (official verified bot).\n'
                '3. Send the command: /newbot\n'
                '4. Give your bot a display name (e.g. "My Personal Drive").\n'
                '5. Give it a unique username ending in "bot" (e.g. "my_drive_storage_bot").\n'
                '6. BotFather will reply with your HTTP API Token. Copy it!',
            copyText: '/newbot',
            buttonLabel: 'Copy "/newbot"',
          ),

          const SizedBox(height: 16),

          _buildStepCard(
            context,
            stepNumber: '2',
            title: 'Create a Private Storage Channel',
            description: '1. In Telegram, tap the pencil icon -> "New Channel".\n'
                '2. Name it (e.g. "My Cloud Files") and set it to "Private".\n'
                '3. Open Channel Settings -> Administrators -> "Add Admin".\n'
                '4. Search for your bot username and add it as Admin with "Post Messages" permission enabled.',
          ),

          const SizedBox(height: 16),

          _buildStepCard(
            context,
            stepNumber: '3',
            title: 'Get Your Channel ID',
            description: '1. Send any test message in your new channel.\n'
                '2. Forward that message to "@JsonDumpBot" or "@userinfobot".\n'
                '3. It will reply with the chat ID (starts with -100, e.g. -1001987654321).\n'
                '4. Copy that ID.',
            copyText: '@JsonDumpBot',
            buttonLabel: 'Copy "@JsonDumpBot"',
          ),

          const SizedBox(height: 16),

          _buildStepCard(
            context,
            stepNumber: '4',
            title: 'Connect & Enjoy Unlimited Drive',
            description: 'Go to Settings in UnLim Cloud, paste your Bot Token & Channel ID, and tap "Save & Test Connection". You are ready to store unlimited files!',
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
    String? copyText,
    String? buttonLabel,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepNumber,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
            ),
            if (copyText != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: Text(buttonLabel ?? 'Copy'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: copyText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied "$copyText" to clipboard!')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
