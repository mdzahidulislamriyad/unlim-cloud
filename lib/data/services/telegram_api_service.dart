import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';

class TelegramUploadResult {
  final bool success;
  final String? fileId;
  final int? messageId;
  final String? directUrl;
  final String? error;

  TelegramUploadResult({
    required this.success,
    this.fileId,
    this.messageId,
    this.directUrl,
    this.error,
  });
}

class TelegramApiService {
  String _botToken;
  String _chatId;
  String _apiEndpoint;

  TelegramApiService({
    String botToken = '',
    String chatId = '',
    String apiEndpoint = AppConstants.defaultTelegramApi,
  })  : _botToken = botToken.trim(),
        _chatId = chatId.trim(),
        _apiEndpoint = apiEndpoint.trim().isEmpty 
            ? AppConstants.defaultTelegramApi 
            : apiEndpoint.trim();

  void updateCredentials({
    required String botToken,
    required String chatId,
    String? apiEndpoint,
  }) {
    _botToken = botToken.trim();
    _chatId = chatId.trim();
    if (apiEndpoint != null && apiEndpoint.trim().isNotEmpty) {
      _apiEndpoint = apiEndpoint.trim();
    } else {
      _apiEndpoint = AppConstants.defaultTelegramApi;
    }
  }

  bool get isConfigured => _botToken.isNotEmpty && _chatId.isNotEmpty;

  String get _baseUrl => '$_apiEndpoint/bot$_botToken';
  String get _fileBaseUrl => '$_apiEndpoint/file/bot$_botToken';

  /// Test bot token and chat connection
  Future<Map<String, dynamic>> testConnection() async {
    if (!isConfigured) {
      return {'success': false, 'message': 'Bot Token or Chat ID is missing'};
    }

    try {
      // 1. Verify Bot Token via getMe
      final meUri = Uri.parse('$_baseUrl/getMe');
      final meRes = await http.get(meUri).timeout(const Duration(seconds: 15));
      if (meRes.statusCode != 200) {
        final err = jsonDecode(meRes.body);
        return {
          'success': false,
          'message': 'Invalid Bot Token: ${err['description'] ?? 'Unauthorized'}'
        };
      }
      final meData = jsonDecode(meRes.body);
      final botUsername = meData['result']?['username'] ?? 'UnknownBot';

      // 2. Verify Chat ID via getChat
      final chatUri = Uri.parse('$_baseUrl/getChat?chat_id=$_chatId');
      final chatRes = await http.get(chatUri).timeout(const Duration(seconds: 15));
      if (chatRes.statusCode != 200) {
        final err = jsonDecode(chatRes.body);
        return {
          'success': false,
          'message': 'Chat Access Error: ${err['description'] ?? 'Bot cannot access this chat/channel. Make sure bot is an Admin!'}'
        };
      }
      final chatData = jsonDecode(chatRes.body);
      final chatTitle = chatData['result']?['title'] ?? chatData['result']?['username'] ?? 'Storage Channel';

      return {
        'success': true,
        'botUsername': botUsername,
        'chatTitle': chatTitle,
        'message': 'Connected to @$botUsername and "$chatTitle"'
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection Failed: ${e.toString()}'};
    }
  }

  /// Upload any file with real-time progress callback
  Future<TelegramUploadResult> uploadFile({
    required File file,
    required String fileName,
    String? mimeType,
    Function(double progress)? onProgress,
  }) async {
    if (!isConfigured) {
      return TelegramUploadResult(
        success: false,
        error: 'Telegram Bot Token or Chat ID not configured. Go to Settings.',
      );
    }

    try {
      final fileLength = await file.length();
      final uri = Uri.parse('$_baseUrl/sendDocument');

      // Setup multipart request
      final request = http.MultipartRequest('POST', uri);
      request.fields['chat_id'] = _chatId;
      request.fields['caption'] = '📁 $fileName\n⚡ Stored via UnLim Cloud';

      final fileStream = file.openRead();
      int bytesSent = 0;

      // Stream with progress listener
      final streamWithProgress = fileStream.transform(
        StreamTransformer.fromHandlers(
          handleData: (List<int> data, EventSink<List<int>> sink) {
            bytesSent += data.length;
            if (onProgress != null && fileLength > 0) {
              onProgress(bytesSent / fileLength);
            }
            sink.add(data);
          },
        ),
      );

      final multipartFile = http.MultipartFile(
        'document',
        streamWithProgress,
        fileLength,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final result = data['result'];
        final messageId = result['message_id'] as int;
        
        // Extract fileId from document or other media
        String fileId = '';
        if (result['document'] != null) {
          fileId = result['document']['file_id'];
        } else if (result['photo'] != null && (result['photo'] as List).isNotEmpty) {
          fileId = (result['photo'] as List).last['file_id'];
        } else if (result['video'] != null) {
          fileId = result['video']['file_id'];
        } else if (result['audio'] != null) {
          fileId = result['audio']['file_id'];
        }

        // Fetch direct download path
        final directUrl = await getFileDownloadUrl(fileId);

        return TelegramUploadResult(
          success: true,
          fileId: fileId,
          messageId: messageId,
          directUrl: directUrl,
        );
      } else {
        final err = jsonDecode(responseBody);
        return TelegramUploadResult(
          success: false,
          error: err['description'] ?? 'Upload failed (HTTP ${streamedResponse.statusCode})',
        );
      }
    } catch (e) {
      return TelegramUploadResult(
        success: false,
        error: 'Upload error: ${e.toString()}',
      );
    }
  }

  /// Get direct streaming/download URL for a fileId
  Future<String?> getFileDownloadUrl(String fileId) async {
    if (!isConfigured || fileId.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/getFile?file_id=$fileId');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final filePath = data['result']?['file_path'];
        if (filePath != null) {
          return '$_fileBaseUrl/$filePath';
        }
      }
    } catch (_) {}
    return null;
  }

  /// Delete file from Telegram cloud
  Future<bool> deleteMessage(int messageId) async {
    if (!isConfigured || messageId == 0) return false;

    try {
      final uri = Uri.parse('$_baseUrl/deleteMessage?chat_id=$_chatId&message_id=$messageId');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
