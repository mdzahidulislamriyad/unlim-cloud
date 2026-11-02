import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/download_manager_service.dart';
import '../view_models/storage_view_model.dart';

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StorageViewModel>();
    final transfers = vm.transfers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (transfers.any((t) => t.status == TransferStatus.completed))
            TextButton(
              onPressed: () => vm.clearCompletedTransfers(),
              child: const Text('Clear Finished', style: TextStyle(color: AppTheme.primaryTeal)),
            ),
        ],
      ),
      body: transfers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_vert_circle_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No active or recent transfers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Uploaded or downloaded files will show here',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transfers.length,
              itemBuilder: (context, index) {
                final item = transfers[index];
                return _buildTransferTile(context, vm, item);
              },
            ),
    );
  }

  Widget _buildTransferTile(BuildContext context, StorageViewModel vm, TransferItem item) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (item.status) {
      case TransferStatus.inProgress:
        statusColor = AppTheme.primaryTeal;
        statusText = item.isUpload ? 'Uploading...' : 'Downloading...';
        statusIcon = item.isUpload ? Icons.cloud_upload_outlined : Icons.cloud_download_outlined;
        break;
      case TransferStatus.completed:
        statusColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.check_circle_outline;
        break;
      case TransferStatus.failed:
        statusColor = Colors.red;
        statusText = 'Failed: ${item.error ?? 'Unknown error'}';
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Pending...';
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (item.status == TransferStatus.completed && item.localPath != null)
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () => vm.openFile(item.localPath!),
                    child: const Text('Open', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            if (item.status == TransferStatus.inProgress) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress > 0 ? item.progress : null,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: AppTheme.primaryTeal,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(item.bytesTransferred / (1024 * 1024)).toStringAsFixed(1)} MB / ${(item.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    item.formattedProgress,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
