import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/cloud_file.dart';
import '../models/cloud_folder.dart';
import '../models/storage_stats.dart';
import '../services/telegram_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/download_manager_service.dart';

class CloudStorageRepository {
  final TelegramApiService _telegramApi;
  final LocalStorageService _localStorage;
  final DownloadManagerService _downloadManager;

  List<CloudFile> _files = [];
  List<CloudFolder> _folders = [];

  CloudStorageRepository({
    required TelegramApiService telegramApi,
    required LocalStorageService localStorage,
    required DownloadManagerService downloadManager,
  })  : _telegramApi = telegramApi,
        _localStorage = localStorage,
        _downloadManager = downloadManager {
    _loadFromLocal();
  }

  void _loadFromLocal() {
    _files = _localStorage.loadFiles();
    _folders = _localStorage.loadFolders();
  }

  List<CloudFile> get allFiles => List.unmodifiable(_files);
  List<CloudFolder> get allFolders => List.unmodifiable(_folders);

  // Folders
  Future<CloudFolder> createFolder(String name, {String? parentId}) async {
    final folder = CloudFolder(
      id: 'fld_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    _folders.add(folder);
    await _localStorage.saveFolders(_folders);
    return folder;
  }

  Future<void> renameFolder(String folderId, String newName) async {
    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx != -1) {
      final old = _folders[idx];
      _folders[idx] = CloudFolder(
        id: old.id,
        name: newName.trim(),
        parentId: old.parentId,
        createdAt: old.createdAt,
      );
      await _localStorage.saveFolders(_folders);
    }
  }

  Future<void> deleteFolder(String folderId) async {
    _folders.removeWhere((f) => f.id == folderId);
    // Move files in this folder to root
    for (int i = 0; i < _files.length; i++) {
      if (_files[i].folderId == folderId) {
        _files[i] = _files[i].copyWith(folderId: null);
      }
    }
    await _localStorage.saveFolders(_folders);
    await _localStorage.saveFiles(_files);
  }

  // Upload
  Future<CloudFile?> uploadFile({
    required File file,
    String? folderId,
  }) async {
    final fileName = p.basename(file.path);
    final ext = p.extension(file.path).replaceAll('.', '');
    final type = CloudFile.detectTypeFromExtension(ext);
    final fileSize = await file.length();

    final transferId = 'up_${DateTime.now().millisecondsSinceEpoch}';
    final transferItem = TransferItem(
      id: transferId,
      fileName: fileName,
      totalBytes: fileSize,
      isUpload: true,
      status: TransferStatus.inProgress,
    );
    _downloadManager.addUploadTransfer(transferItem);

    final result = await _telegramApi.uploadFile(
      file: file,
      fileName: fileName,
      onProgress: (prog) {
        _downloadManager.updateTransferProgress(
          transferId,
          prog,
          (fileSize * prog).toInt(),
        );
      },
    );

    if (result.success && result.fileId != null) {
      final cloudFile = CloudFile(
        id: 'file_${DateTime.now().millisecondsSinceEpoch}',
        name: fileName,
        size: fileSize,
        type: type,
        extension: ext,
        uploadDate: DateTime.now(),
        telegramFileId: result.fileId!,
        telegramMessageId: result.messageId ?? 0,
        folderId: folderId,
        directDownloadUrl: result.directUrl,
      );

      _files.insert(0, cloudFile);
      await _localStorage.saveFiles(_files);
      _downloadManager.markCompleted(transferId);
      return cloudFile;
    } else {
      _downloadManager.markFailed(transferId, result.error ?? 'Upload failed');
      return null;
    }
  }

  // Delete
  Future<bool> deleteFile(String fileId) async {
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx != -1) {
      final file = _files[idx];
      if (file.telegramMessageId > 0) {
        await _telegramApi.deleteMessage(file.telegramMessageId);
      }
      _files.removeAt(idx);
      await _localStorage.saveFiles(_files);
      return true;
    }
    return false;
  }

  // Toggle Favorite
  Future<void> toggleFavorite(String fileId) async {
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx != -1) {
      _files[idx] = _files[idx].copyWith(isFavorite: !_files[idx].isFavorite);
      await _localStorage.saveFiles(_files);
    }
  }

  // Rename File
  Future<void> renameFile(String fileId, String newName) async {
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx != -1) {
      _files[idx] = _files[idx].copyWith(name: newName.trim());
      await _localStorage.saveFiles(_files);
    }
  }

  // Get File Download URL
  Future<String?> getDownloadUrl(CloudFile file) async {
    final cached = file.directDownloadUrl;
    if (cached != null &&
        cached.isNotEmpty &&
        !cached.contains(':8081/file/') &&
        !cached.contains('/tg-bot-api-temp/') &&
        !cached.contains('%2Ftg-bot-api-temp%2F')) {
      return cached;
    }
    final url = await _telegramApi.getFileDownloadUrl(file.telegramFileId);
    if (url != null) {
      final idx = _files.indexWhere((f) => f.id == file.id);
      if (idx != -1) {
        _files[idx] = _files[idx].copyWith(directDownloadUrl: url);
        await _localStorage.saveFiles(_files);
      }
    }
    return url;
  }

  // Download
  Future<String?> downloadFile(CloudFile file) async {
    String? url = await getDownloadUrl(file);
    if (url == null) return null;

    String? path = await _downloadManager.downloadFile(file: file, downloadUrl: url);
    // If download failed (e.g. 404 or connection reset), force refresh URL and retry once
    if (path == null) {
      final freshUrl = await _telegramApi.getFileDownloadUrl(file.telegramFileId);
      if (freshUrl != null && freshUrl != url) {
        final idx = _files.indexWhere((f) => f.id == file.id);
        if (idx != -1) {
          _files[idx] = _files[idx].copyWith(directDownloadUrl: freshUrl);
          await _localStorage.saveFiles(_files);
        }
        path = await _downloadManager.downloadFile(file: file, downloadUrl: freshUrl);
      }
    }
    return path;
  }

  StorageStats getStats() {
    return StorageStats.calculate(_files);
  }

  Future<void> clearAll() async {
    _files.clear();
    _folders.clear();
    await _localStorage.clearAllData();
  }
}
