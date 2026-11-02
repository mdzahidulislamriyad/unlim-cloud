import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/cloud_file.dart';
import '../models/cloud_folder.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Credentials
  String getBotToken() => _prefs.getString(AppConstants.keyBotToken) ?? '';
  Future<bool> setBotToken(String token) => _prefs.setString(AppConstants.keyBotToken, token.trim());

  String getChatId() => _prefs.getString(AppConstants.keyChatId) ?? '';
  Future<bool> setChatId(String id) => _prefs.setString(AppConstants.keyChatId, id.trim());

  String getCustomApiServer() => _prefs.getString(AppConstants.keyCustomApiServer) ?? '';
  Future<bool> setCustomApiServer(String server) => _prefs.setString(AppConstants.keyCustomApiServer, server.trim());

  // Settings
  bool isDarkMode() => _prefs.getBool(AppConstants.keyDarkMode) ?? true;
  Future<bool> setDarkMode(bool isDark) => _prefs.setBool(AppConstants.keyDarkMode, isDark);

  bool isAutoBackup() => _prefs.getBool(AppConstants.keyAutoBackup) ?? false;
  Future<bool> setAutoBackup(bool enabled) => _prefs.setBool(AppConstants.keyAutoBackup, enabled);

  // Files
  List<CloudFile> loadFiles() {
    final raw = _prefs.getString(AppConstants.keyFilesList);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => CloudFile.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveFiles(List<CloudFile> files) {
    final encoded = jsonEncode(files.map((f) => f.toJson()).toList());
    return _prefs.setString(AppConstants.keyFilesList, encoded);
  }

  // Folders
  List<CloudFolder> loadFolders() {
    final raw = _prefs.getString(AppConstants.keyFoldersList);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => CloudFolder.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveFolders(List<CloudFolder> folders) {
    final encoded = jsonEncode(folders.map((f) => f.toJson()).toList());
    return _prefs.setString(AppConstants.keyFoldersList, encoded);
  }

  // Clear All
  Future<bool> clearAllData() async {
    await _prefs.remove(AppConstants.keyFilesList);
    await _prefs.remove(AppConstants.keyFoldersList);
    return true;
  }
}
