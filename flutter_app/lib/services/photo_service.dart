import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service for photo capture, compression, and upload
/// 
/// Features:
/// - Camera and gallery access
/// - Image compression to < 2MB
/// - Upload to backend API
/// - Support for ticket and profile photos
class PhotoService {
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();
  
  // Maximum file size in bytes (2MB)
  static const int maxFileSizeBytes = 2 * 1024 * 1024;
  
  // Target quality for compression (0-100)
  static const int compressionQuality = 85;

  /// Pick photo from camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: compressionQuality,
      );

      if (photo == null) return null;

      return File(photo.path);
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Pick photo from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: compressionQuality,
      );

      if (photo == null) return null;

      return File(photo.path);
    } catch (e) {
      throw Exception('Failed to pick photo: $e');
    }
  }

  /// Compress image to target size
  /// Returns compressed image file
  Future<File> compressImage(File imageFile) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // If already small enough, return original
      if (bytes.length <= maxFileSizeBytes) {
        return imageFile;
      }

      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate target dimensions maintaining aspect ratio
      int width = image.width;
      int height = image.height;
      
      // Scale down if too large
      const maxDimension = 1920;
      if (width > maxDimension || height > maxDimension) {
        if (width > height) {
          height = (height * maxDimension / width).round();
          width = maxDimension;
        } else {
          width = (width * maxDimension / height).round();
          height = maxDimension;
        }
      }

      // Resize image
      final resized = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      // Compress to JPEG with quality
      int quality = compressionQuality;
      List<int> compressed;
      
      do {
        compressed = img.encodeJpg(resized, quality: quality);
        if (compressed.length <= maxFileSizeBytes || quality <= 50) {
          break;
        }
        quality -= 10;
      } while (quality > 50);

      // Write to temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);

      return tempFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Upload photo to backend API
  /// 
  /// [photoFile] - The photo file to upload
  /// [type] - Photo type ('ticket' or 'profile')
  /// [associatedId] - Associated entity ID (ticket ID, user ID, etc.)
  Future<PhotoUploadResult> uploadPhoto({
    required File photoFile,
    required String type,
    String? associatedId,
  }) async {
    try {
      // Compress image first
      final compressedFile = await compressImage(photoFile);

      // Prepare form data
      final fileName = photoFile.path.split('/').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          compressedFile.path,
          filename: fileName,
        ),
        'type': type,
        if (associatedId != null) 'associated_id': associatedId,
      });

      // Upload to API
      final response = await _api.post(
        '${ApiConfig.apiVersion}/upload-photo',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PhotoUploadResult.fromJson(response.data);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Upload ticket photo
  Future<PhotoUploadResult> uploadTicketPhoto(File photoFile, String ticketId) async {
    return uploadPhoto(
      photoFile: photoFile,
      type: 'ticket',
      associatedId: ticketId,
    );
  }

  /// Upload profile photo
  Future<PhotoUploadResult> uploadProfilePhoto(File photoFile, String userId) async {
    return uploadPhoto(
      photoFile: photoFile,
      type: 'profile',
      associatedId: userId,
    );
  }

  /// Get file size in MB
  Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Check if file size is acceptable
  Future<bool> isFileSizeAcceptable(File file) async {
    final bytes = await file.length();
    return bytes <= maxFileSizeBytes;
  }
}

/// Photo upload result from API
class PhotoUploadResult {
  final bool success;
  final String? photoUrl;
  final String? photoId;
  final String? message;
  final String? error;

  PhotoUploadResult({
    required this.success,
    this.photoUrl,
    this.photoId,
    this.message,
    this.error,
  });

  factory PhotoUploadResult.fromJson(Map<String, dynamic> json) {
    return PhotoUploadResult(
      success: json['success'] ?? false,
      photoUrl: json['photo_url'] ?? json['photoUrl'] ?? json['url'],
      photoId: json['photo_id'] ?? json['photoId'] ?? json['id'],
      message: json['message'],
      error: json['error'],
    );
  }
}
