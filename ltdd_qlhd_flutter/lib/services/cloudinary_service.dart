import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final String resourceType;

  CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
  });
}

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  static const String cloudName = 'dfcw9ewtd';
  static const String uploadPreset = 'itconnect_unsigned';

  Future<CloudinaryUploadResult> uploadEvidence({
    required File file,
    required String userId,
    required String activityId,
    required bool isVideo,
  }) async {
    if (!await file.exists()) {
      throw Exception('Không tìm thấy file minh chứng');
    }

    final resourceType = isVideo ? 'video' : 'image';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] =
        'itconnect/check_in_evidences/$userId/$activityId';

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    Map<String, dynamic> data = {};

    try {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Cloudinary trả về dữ liệu không hợp lệ');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage =
          data['error']?['message']?.toString() ?? 'Upload Cloudinary thất bại';

      throw Exception(errorMessage);
    }

    final secureUrl = data['secure_url']?.toString() ?? '';
    final publicId = data['public_id']?.toString() ?? '';

    if (secureUrl.isEmpty) {
      throw Exception('Không lấy được URL minh chứng từ Cloudinary');
    }

    return CloudinaryUploadResult(
      secureUrl: secureUrl,
      publicId: publicId,
      resourceType: resourceType,
    );
  }

  Future<String> uploadNewsImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Không tìm thấy ảnh tin tức');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'itconnect/news_images';

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    Map<String, dynamic> data = {};

    try {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Cloudinary trả về dữ liệu không hợp lệ');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage =
          data['error']?['message']?.toString() ??
          'Upload ảnh tin tức thất bại';

      throw Exception(errorMessage);
    }

    final secureUrl = data['secure_url']?.toString() ?? '';

    if (secureUrl.isEmpty) {
      throw Exception('Không lấy được URL ảnh tin tức từ Cloudinary');
    }

    return secureUrl;
  }

  Future<String> uploadActivityImage({
    required File imageFile,
    required String activityId,
  }) async {
    if (!await imageFile.exists()) {
      throw Exception('Không tìm thấy ảnh hoạt động');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'itconnect/activities/$activityId';

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    Map<String, dynamic> data = {};

    try {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Cloudinary trả về dữ liệu không hợp lệ');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage =
          data['error']?['message']?.toString() ??
          'Upload ảnh hoạt động thất bại';

      throw Exception(errorMessage);
    }

    final secureUrl = data['secure_url']?.toString() ?? '';

    if (secureUrl.isEmpty) {
      throw Exception('Không lấy được URL ảnh hoạt động từ Cloudinary');
    }

    return secureUrl;
  }
}
