
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../api/api_client.dart';
import '../models/offline_operation.dart';
import 'offline_data_service.dart';

class PhotoService {
  static final _dio = ApiClient().dio;
  static final _imagePicker = ImagePicker();
  
  
  static Future<XFile?> pickPhoto({required bool fromCamera}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      return image;
    } catch (e) {
      debugPrint('选择照片失败: $e');
      return null;
    }
  }
  
  
  static Future<List<XFile>> pickMultiplePhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      return images;
    } catch (e) {
      debugPrint('批量选择照片失败: $e');
      return [];
    }
  }
  
  
  static Future<Map<String, dynamic>> uploadPhoto({
    required String idCard,
    required String photoType,
    required File photoFile,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final fileName = '${idCard}_$photoType${_getFileExtension(photoFile.path)}';
      
      final formData = FormData.fromMap({
        'id_card': idCard,
        'photo_type': photoType,
        'photo': await MultipartFile.fromFile(
          photoFile.path,
          filename: fileName,
        ),
      });
      
      final response = await _dio.post(
        '/api/upload_photo',
        data: formData,
        onSendProgress: onProgress,
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': response.data['url'],
          'message': '上传成功',
        };
      } else {
        return {
          'success': false,
          'message': '上传失败',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '上传失败: $e',
      };
    }
  }
  
  
  static Future<List<Map<String, dynamic>>> uploadMultiplePhotos({
    required String idCard,
    required List<XFile> photos,
    required String photoType,
    void Function(int, int)? onProgress,
  }) async {
    final results = <Map<String, dynamic>>[];
    
    for (int i = 0; i < photos.length; i++) {
      final result = await uploadPhoto(
        idCard: idCard,
        photoType: photoType,
        photoFile: File(photos[i].path),
        onProgress: onProgress,
      );
      
      results.add({
        'index': i,
        'success': result['success'],
        'message': result['message'],
        'url': result['url'],
      });
    }
    
    return results;
  }
  
  
  static Future<List<Map<String, dynamic>>> getPhotoList(String idCard) async {
    try {
      final response = await _dio.get('/api/photos/$idCard');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['photos'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  
  static Future<bool> deletePhoto(String idCard, String photoType) async {
    try {
      final response = await _dio.delete('/api/photo/$idCard/$photoType');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
  
  
  static String getPhotoUrl(String idCard, String photoType) {
    final baseUrl = AppConfig.apiBaseUrl;
    return '$baseUrl/api/photo/$idCard/$photoType';
  }
  
  
  static String _getFileExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return '.$ext';
  }
  
  
  static Future<File?> compressImage(File imageFile) async {
    
    
    return imageFile;
  }

  

  
  static Future<bool> addPhotoOffline({
    required String personId,
    required File photo,
    required String photoType,
  }) async {
    try {
      
      final localPath = await _savePhotoLocally(photo, personId, photoType);

      
      final operation = OfflineOperation(
        id: OfflineDataService().generateId(),
        type: OperationType.addPhoto,
        entityType: 'person',
        entityId: personId,
        data: {
          'local_path': localPath,
          'photo_type': photoType,
          'original_filename': photo.path.split('/').last,
        },
        createdAt: DateTime.now(),
      );

      
      await OfflineDataService().queueOperation(operation);

      return true;
    } catch (e) {
      debugPrint('离线添加照片失败: $e');
      return false;
    }
  }

  
  static Future<String> _savePhotoLocally(
    File photo,
    String personId,
    String photoType,
  ) async {
    try {
      
      final appDir = await getApplicationDocumentsDirectory();
      final offlinePhotosDir = Directory('${appDir.path}/offline_photos');

      
      if (!await offlinePhotosDir.exists()) {
        await offlinePhotosDir.create(recursive: true);
      }

      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = photo.path.split('.').last;
      final fileName = '${personId}_${photoType}_$timestamp.$extension';
      final localPath = '${offlinePhotosDir.path}/$fileName';

      
      await photo.copy(localPath);

      return localPath;
    } catch (e) {
      debugPrint('保存照片到本地失败: $e');
      rethrow;
    }
  }

  
  static Future<bool> deletePhotoOffline({
    required String personId,
    required String photoType,
  }) async {
    try {
      
      final operation = OfflineOperation(
        id: OfflineDataService().generateId(),
        type: OperationType.deletePhoto,
        entityType: 'person',
        entityId: personId,
        data: {
          'photo_type': photoType,
        },
        createdAt: DateTime.now(),
      );

      
      await OfflineDataService().queueOperation(operation);

      return true;
    } catch (e) {
      debugPrint('离线删除照片失败: $e');
      return false;
    }
  }

  
  static Future<List<Map<String, dynamic>>> getOfflinePhotos(
    String personId,
  ) async {
    try {
      final operations = await OfflineDataService().getPendingOperations();

      return operations
          .where((op) =>
              op.type == OperationType.addPhoto && op.entityId == personId)
          .map((op) => {
                'local_path': op.data['local_path'],
                'photo_type': op.data['photo_type'],
                'status': op.status.name,
                'created_at': op.createdAt.toIso8601String(),
              })
          .toList();
    } catch (e) {
      debugPrint('获取离线照片列表失败: $e');
      return [];
    }
  }

  
  static Future<void> cleanSyncedOfflinePhotos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final offlinePhotosDir = Directory('${appDir.path}/offline_photos');

      if (await offlinePhotosDir.exists()) {
        
        final operations = await OfflineDataService().getPendingOperations();
        final syncedOperations = operations
            .where((op) =>
                op.type == OperationType.addPhoto &&
                op.status == SyncStatus.synced)
            .toList();

        
        for (final op in syncedOperations) {
          final localPath = op.data['local_path'] as String?;
          if (localPath != null) {
            final file = File(localPath);
            if (await file.exists()) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('清理离线照片失败: $e');
    }
  }
}
