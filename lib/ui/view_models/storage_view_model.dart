import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/cloud_file.dart';
import '../../data/models/cloud_folder.dart';
import '../../data/models/storage_stats.dart';
import '../../data/repositories/cloud_storage_repository.dart';
import '../../data/services/telegram_api_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/download_manager_service.dart';

enum SortMode { dateDesc, dateAsc, nameAsc, sizeDesc }

class StorageViewModel extends ChangeNotifier {
  final CloudStorageRepository _repository;
  final TelegramApiService _telegramApi;
  final LocalStorageService _localStorage;
  final DownloadManagerService _downloadManager;

  // Navigation State
  String? _currentFolderId;
  final List<CloudFolder> _breadcrumbStack = [];

  // Filter & Search
  String _selectedCategory = 'all'; // all, photo, video, audio, document, favorites
  String _searchQuery = '';
  SortMode _sortMode = SortMode.dateDesc;
  bool _isGridView = false;

  // App Settings State
  bool _isDarkMode = true;
  bool _isAutoBackup = false;
  bool _isConnecting = false;
  String? _connectionStatusMessage;
  bool _isConnected = false;

  StorageViewModel({
    required CloudStorageRepository repository,
    required TelegramApiService telegramApi,
    required LocalStorageService localStorage,
    required DownloadManagerService downloadManager,
  })  : _repository = repository,
        _telegramApi = telegramApi,
        _localStorage = localStorage,
        _downloadManager = downloadManager {
    _isDarkMode = _localStorage.isDarkMode();
    _isAutoBackup = _localStorage.isAutoBackup();
    _checkInitialConnection();

    // Listen to real-time upload/download progress updates
    _downloadManager.transfersStream.listen((_) {
      notifyListeners();
    });
  }

  // Getters
  String? get currentFolderId => _currentFolderId;
  List<CloudFolder> get breadcrumbs => List.unmodifiable(_breadcrumbStack);
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  SortMode get sortMode => _sortMode;
  bool get isGridView => _isGridView;
  bool get isDarkMode => _isDarkMode;
  bool get isAutoBackup => _isAutoBackup;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get connectionStatusMessage => _connectionStatusMessage;

  String get botToken => _localStorage.getBotToken();
  String get chatId => _localStorage.getChatId();
  String get customApiServer => _localStorage.getCustomApiServer();

  List<TransferItem> get transfers => _downloadManager.transfers;

  TransferItem? get activeTransfer {
    try {
      return _downloadManager.transfers.firstWhere((t) => t.status == TransferStatus.inProgress);
    } catch (_) {
      return null;
    }
  }

  bool get hasActiveTransfer => _downloadManager.transfers.any((t) => t.status == TransferStatus.inProgress);

  Future<void> _checkInitialConnection() async {
    if (_telegramApi.isConfigured) {
      final res = await _telegramApi.testConnection();
      _isConnected = res['success'] == true;
      _connectionStatusMessage = res['message'];
      notifyListeners();
    }
  }

  // Folders Navigation
  void openFolder(CloudFolder folder) {
    _currentFolderId = folder.id;
    _breadcrumbStack.add(folder);
    notifyListeners();
  }

  void navigateBack() {
    if (_breadcrumbStack.isNotEmpty) {
      _breadcrumbStack.removeLast();
      _currentFolderId = _breadcrumbStack.isNotEmpty ? _breadcrumbStack.last.id : null;
      notifyListeners();
    }
  }

  void navigateToRoot() {
    _currentFolderId = null;
    _breadcrumbStack.clear();
    notifyListeners();
  }

  void navigateToBreadcrumb(int index) {
    if (index < _breadcrumbStack.length - 1) {
      _breadcrumbStack.removeRange(index + 1, _breadcrumbStack.length);
      _currentFolderId = _breadcrumbStack.isNotEmpty ? _breadcrumbStack.last.id : null;
      notifyListeners();
    }
  }

  // UI Filtering & Sorting
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  // Folder Items for Current View
  List<CloudFolder> getCurrentFolders() {
    if (_selectedCategory != 'all' || _searchQuery.isNotEmpty) {
      return []; // Hide folder tree when filtering or searching
    }
    return _repository.allFolders
        .where((f) => f.parentId == _currentFolderId)
        .toList();
  }

  // Files for Current View
  List<CloudFile> getCurrentFiles() {
    List<CloudFile> list = _repository.allFiles;

    // Filter by Category
    if (_selectedCategory == 'favorites') {
      list = list.where((f) => f.isFavorite).toList();
    } else if (_selectedCategory != 'all') {
      list = list.where((f) => f.type == _selectedCategory).toList();
    } else if (_searchQuery.isEmpty) {
      // In normal folder navigation, only show files in current folder
      list = list.where((f) => f.folderId == _currentFolderId).toList();
    }

    // Filter by Search
    if (_searchQuery.isNotEmpty) {
      list = list.where((f) => f.name.toLowerCase().contains(_searchQuery)).toList();
    }

    // Sort
    list = List.of(list);
    switch (_sortMode) {
      case SortMode.dateDesc:
        list.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
        break;
      case SortMode.dateAsc:
        list.sort((a, b) => a.uploadDate.compareTo(b.uploadDate));
        break;
      case SortMode.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortMode.sizeDesc:
        list.sort((a, b) => b.size.compareTo(a.size));
        break;
    }

    return list;
  }

  StorageStats getStats() => _repository.getStats();

  List<CloudFile> getRecentFiles([int limit = 10]) {
    final list = List<CloudFile>.from(_repository.allFiles);
    list.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    return list.take(limit).toList();
  }

  // Pick & Upload Multiple Files
  Future<int> pickAndUploadFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isEmpty) return 0;

      int count = 0;
      for (final f in files) {
        if (f.path != null) {
          final file = File(f.path!);
          final uploaded = await _repository.uploadFile(
            file: file,
            folderId: _currentFolderId,
          );
          if (uploaded != null) {
            count++;
            notifyListeners();
          }
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  // Pick & Upload an Entire Folder with Files
  Future<int> pickAndUploadFilesToFolder(String folderName) async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (pickedFiles.isEmpty) return 0;

      final files = pickedFiles
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();

      if (files.isEmpty) return 0;

      final newFolder = await _repository.createFolder(
        folderName.trim().isEmpty ? 'New Folder' : folderName.trim(),
        parentId: _currentFolderId,
      );

      int count = 0;
      for (final file in files) {
        final uploaded = await _repository.uploadFile(
          file: file,
          folderId: newFolder.id,
        );
        if (uploaded != null) {
          count++;
          notifyListeners();
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  // Pick & Upload an Entire Directory (if supported by system)
  Future<int> pickAndUploadFolder() async {
    try {
      final folderPath = await FilePicker.getDirectoryPath();
      if (folderPath == null || folderPath.isEmpty) return 0;

      final dir = Directory(folderPath);
      if (!await dir.exists()) return 0;

      final folderName = folderPath.split(Platform.pathSeparator).last;
      final newFolder = await _repository.createFolder(
        folderName,
        parentId: _currentFolderId,
      );

      int count = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final uploaded = await _repository.uploadFile(
            file: entity,
            folderId: newFolder.id,
          );
          if (uploaded != null) {
            count++;
            notifyListeners();
          }
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  // Create Folder
  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    await _repository.createFolder(name, parentId: _currentFolderId);
    notifyListeners();
  }

  // Rename Folder
  Future<void> renameFolder(String folderId, String newName) async {
    await _repository.renameFolder(folderId, newName);
    notifyListeners();
  }

  // Delete Folder
  Future<void> deleteFolder(String folderId) async {
    await _repository.deleteFolder(folderId);
    notifyListeners();
  }

  // Rename File
  Future<void> renameFile(String fileId, String newName) async {
    await _repository.renameFile(fileId, newName);
    notifyListeners();
  }

  // Delete File
  Future<void> deleteFile(String fileId) async {
    await _repository.deleteFile(fileId);
    notifyListeners();
  }

  // Toggle Favorite
  Future<void> toggleFavorite(String fileId) async {
    await _repository.toggleFavorite(fileId);
    notifyListeners();
  }

  // Download File
  Future<String?> downloadFile(CloudFile file) async {
    return await _repository.downloadFile(file);
  }

  Future<String?> getDownloadUrl(CloudFile file) async {
    return await _repository.getDownloadUrl(file);
  }

  // Open Local File
  Future<void> openFile(String path) async {
    await _downloadManager.openFile(path);
  }

  void clearCompletedTransfers() {
    _downloadManager.clearCompleted();
    notifyListeners();
  }

  // Settings & Credentials
  Future<bool> saveCredentials({
    required String botToken,
    required String chatId,
    String? customApiServer,
  }) async {
    _isConnecting = true;
    notifyListeners();

    await _localStorage.setBotToken(botToken);
    await _localStorage.setChatId(chatId);
    if (customApiServer != null) {
      await _localStorage.setCustomApiServer(customApiServer);
    }

    _telegramApi.updateCredentials(
      botToken: botToken,
      chatId: chatId,
      apiEndpoint: customApiServer,
    );

    final res = await _telegramApi.testConnection();
    _isConnected = res['success'] == true;
    _connectionStatusMessage = res['message'];
    _isConnecting = false;
    notifyListeners();
    return _isConnected;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _localStorage.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  void toggleAutoBackup() {
    _isAutoBackup = !_isAutoBackup;
    _localStorage.setAutoBackup(_isAutoBackup);
    notifyListeners();
  }

  Future<void> clearAllCache() async {
    await _repository.clearAll();
    navigateToRoot();
    notifyListeners();
  }
}
