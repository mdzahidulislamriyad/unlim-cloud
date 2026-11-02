import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/cloud_file.dart';

enum TransferStatus { pending, inProgress, completed, failed, cancelled }

class TransferItem {
  final String id;
  final String fileName;
  final int totalBytes;
  int bytesTransferred;
  double progress; // 0.0 to 1.0
  TransferStatus status;
  final bool isUpload;
  String? localPath;
  String? error;
  DateTime timestamp;

  TransferItem({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    this.bytesTransferred = 0,
    this.progress = 0.0,
    this.status = TransferStatus.pending,
    required this.isUpload,
    this.localPath,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedProgress => '${(progress * 100).toStringAsFixed(0)}%';
}

class DownloadManagerService {
  final List<TransferItem> _transfers = [];
  final StreamController<List<TransferItem>> _streamController = StreamController<List<TransferItem>>.broadcast();

  List<TransferItem> get transfers => List.unmodifiable(_transfers);
  Stream<List<TransferItem>> get transfersStream => _streamController.stream;

  void _notify() {
    _streamController.add(List.unmodifiable(_transfers));
  }

  void addUploadTransfer(TransferItem item) {
    _transfers.insert(0, item);
    _notify();
  }

  void updateTransferProgress(String id, double progress, int bytesTransferred) {
    final idx = _transfers.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _transfers[idx].progress = progress.clamp(0.0, 1.0);
      _transfers[idx].bytesTransferred = bytesTransferred;
      _transfers[idx].status = TransferStatus.inProgress;
      _notify();
    }
  }

  void markCompleted(String id, {String? localPath}) {
    final idx = _transfers.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _transfers[idx].progress = 1.0;
      _transfers[idx].status = TransferStatus.completed;
      if (localPath != null) _transfers[idx].localPath = localPath;
      _notify();
    }
  }

  void markFailed(String id, String error) {
    final idx = _transfers.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _transfers[idx].status = TransferStatus.failed;
      _transfers[idx].error = error;
      _notify();
    }
  }

  /// Download file to public Downloads or App storage directory
  Future<String?> downloadFile({
    required CloudFile file,
    required String downloadUrl,
  }) async {
    final transferId = 'down_${file.id}_${DateTime.now().millisecondsSinceEpoch}';
    final item = TransferItem(
      id: transferId,
      fileName: file.name,
      totalBytes: file.size,
      isUpload: false,
      status: TransferStatus.inProgress,
    );
    _transfers.insert(0, item);
    _notify();

    try {
      Directory? saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          saveDir = await getExternalStorageDirectory();
        }
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }

      saveDir ??= await getApplicationDocumentsDirectory();
      final destinationPath = p.join(saveDir.path, file.name);
      final destFile = File(destinationPath);

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        markFailed(transferId, 'HTTP ${response.statusCode}');
        return null;
      }

      final totalBytes = response.contentLength ?? file.size;
      int receivedBytes = 0;
      final sink = destFile.openWrite();

      await response.stream.listen((chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          updateTransferProgress(transferId, receivedBytes / totalBytes, receivedBytes);
        }
      }).asFuture();

      await sink.flush();
      await sink.close();

      markCompleted(transferId, localPath: destinationPath);
      return destinationPath;
    } catch (e) {
      markFailed(transferId, e.toString());
      return null;
    }
  }

  /// Open downloaded file in Android native app
  Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }

  void clearCompleted() {
    _transfers.removeWhere((t) => t.status == TransferStatus.completed);
    _notify();
  }
}
