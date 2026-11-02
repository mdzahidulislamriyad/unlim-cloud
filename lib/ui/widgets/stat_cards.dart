import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/storage_stats.dart';

class StorageOverviewCard extends StatelessWidget {
  final StorageStats stats;

  const StorageOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats.totalBytes > 0 ? stats.totalBytes : 1;

    final pPhoto = (stats.photoBytes / total).clamp(0.0, 1.0);
    final pVideo = (stats.videoBytes / total).clamp(0.0, 1.0);
    final pAudio = (stats.audioBytes / total).clamp(0.0, 1.0);
    final pDoc = (stats.documentBytes / total).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cloud Storage Used',
                      style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.formatBytes(stats.totalBytes),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.all_inclusive, size: 16, color: AppTheme.primaryTeal),
                      SizedBox(width: 6),
                      Text(
                        'Unlimited',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Multi-segment progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: stats.totalBytes == 0
                    ? Container(color: Colors.grey.withOpacity(0.2))
                    : Row(
                        children: [
                          if (pPhoto > 0)
                            Expanded(flex: (pPhoto * 1000).toInt(), child: Container(color: AppTheme.colorPhoto)),
                          if (pVideo > 0)
                            Expanded(flex: (pVideo * 1000).toInt(), child: Container(color: AppTheme.colorVideo)),
                          if (pAudio > 0)
                            Expanded(flex: (pAudio * 1000).toInt(), child: Container(color: AppTheme.colorAudio)),
                          if (pDoc > 0)
                            Expanded(flex: (pDoc * 1000).toInt(), child: Container(color: AppTheme.colorDocument)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendItem('Photos', stats.formatBytes(stats.photoBytes), AppTheme.colorPhoto),
                _buildLegendItem('Videos', stats.formatBytes(stats.videoBytes), AppTheme.colorVideo),
                _buildLegendItem('Audio', stats.formatBytes(stats.audioBytes), AppTheme.colorAudio),
                _buildLegendItem('Docs', stats.formatBytes(stats.documentBytes), AppTheme.colorDocument),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, String size, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(size, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
