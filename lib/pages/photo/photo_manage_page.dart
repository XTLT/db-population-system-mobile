import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/photo_service.dart';
import '../../api/batch_operation_api.dart';
import '../../api/api_client.dart';
import '../../config/app_config.dart';
import '../../services/connectivity_service.dart';
import '../../models/offline_operation.dart';
import '../../widgets/secure_image.dart';

class PhotoManagePage extends StatefulWidget {
  final String idCard;
  final String personName;
  
  const PhotoManagePage({
    super.key,
    required this.idCard,
    required this.personName,
  });

  @override
  State<PhotoManagePage> createState() => _PhotoManagePageState();
}

class _PhotoManagePageState extends State<PhotoManagePage> {
  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _offlinePhotos = [];
  bool _isLoading = true;
  bool _isUploading = false;
  int _uploadProgress = 0;

  bool _isSelectionMode = false;
  Set<String> _selectedPhotoTypes = {};
  int _cacheBuster = DateTime.now().millisecondsSinceEpoch; 
  
  final List<String> _photoTypes = ['身份证', '社保卡1', '社保卡2', '社保卡3'];
  
  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }
  
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPhotoTypes.clear();
      }
    });
  }
  
  void _togglePhotoSelection(String photoType) {
    setState(() {
      if (_selectedPhotoTypes.contains(photoType)) {
        _selectedPhotoTypes.remove(photoType);
      } else {
        _selectedPhotoTypes.add(photoType);
      }
    });
  }
  
  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    
    final photos = await PhotoService.getPhotoList(widget.idCard);

    
    final offlinePhotos = await PhotoService.getOfflinePhotos(widget.idCard);

    setState(() {
      _photos = photos;
      _offlinePhotos = offlinePhotos;
      _isLoading = false;
    });
  }
  
  Future<void> _pickAndUploadPhoto(String photoType, {bool fromCamera = false}) async {
    final photo = await PhotoService.pickPhoto(fromCamera: fromCamera);

    if (photo == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      
      final isConnected = await ConnectivityService().isConnected();

      if (!isConnected) {
        
        final success = await PhotoService.addPhotoOffline(
          personId: widget.idCard,
          photo: File(photo.path),
          photoType: photoType,
        );

        setState(() {
          _isUploading = false;
        });

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已保存到离线队列，将在网络恢复后上传'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          _loadPhotos();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存离线照片失败')),
          );
        }
        return;
      }

      
      final result = await PhotoService.uploadPhoto(
        idCard: widget.idCard,
        photoType: photoType,
        photoFile: File(photo.path),
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = (sent / total * 100).toInt();
          });
        },
      );

      setState(() {
        _isUploading = false;
      });

      if (result['success'] == true) {
        
        setState(() {
          _cacheBuster = DateTime.now().millisecondsSinceEpoch;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('上传成功')),
          );
        }
        _loadPhotos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? '上传失败')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }
  
  Future<void> _deletePhoto(String photoType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 $photoType 照片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final success = await PhotoService.deletePhoto(widget.idCard, photoType);
    
    if (success) {
      
      setState(() {
        _cacheBuster = DateTime.now().millisecondsSinceEpoch;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
      _loadPhotos();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败')),
        );
      }
    }
  }
  
  void _showPhotoOptions(String photoType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(photoType, fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(photoType, fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _batchDeletePhotos() {
    if (_selectedPhotoTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一张照片')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要删除选中的 ${_selectedPhotoTypes.length} 张照片吗？',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此操作不可撤销，删除后照片将无法恢复！',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeBatchDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _executeBatchDelete() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final photosToDelete = _selectedPhotoTypes.map((photoType) => {
        'id_card': widget.idCard,
        'photo_type': photoType,
      }).toList();
      
      final result = await BatchOperationApi.batchDeletePhotos(photosToDelete);
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (result['success'] == true && mounted) {
        final message = '成功删除 ${result['deleted']} 张照片';
        if (result['not_found'] > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$message，${result['not_found']} 张未找到')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        
        setState(() {
          _isSelectionMode = false;
          _selectedPhotoTypes.clear();
        });
        
        _loadPhotos();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量删除失败: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '已选择 ${_selectedPhotoTypes.length} 张' 
            : '${widget.personName} - 照片管理'),
        actions: [
          if (_isSelectionMode)
            TextButton(
              onPressed: _toggleSelectionMode,
              child: const Text('取消', style: TextStyle(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadPhotos,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _photoTypes.length,
                  itemBuilder: (context, index) {
                    final photoType = _photoTypes[index];
                    final photo = _photos.firstWhere(
                      (p) => p['photo_type'] == photoType,
                      orElse: () => <String, dynamic>{},
                    );
                    
                    return _buildPhotoCard(photoType, photo);
                  },
                ),
                
                
                if (_isUploading)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text('上传中... $_uploadProgress%'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: _isSelectionMode && _selectedPhotoTypes.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _batchDeletePhotos,
                  icon: const Icon(Icons.delete),
                  label: Text('删除选中 (${_selectedPhotoTypes.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            )
          : null,
    );
  }
  
  Widget _buildPhotoCard(String photoType, Map<String, dynamic> photo) {
    final hasPhoto = photo.isNotEmpty;
    final isSelected = _selectedPhotoTypes.contains(photoType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: hasPhoto
                        ? (value) => _togglePhotoSelection(photoType)
                        : null,
                  ),
                if (!_isSelectionMode) ...[
                  Icon(
                    hasPhoto ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: hasPhoto ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  photoType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isSelectionMode && hasPhoto) ...[
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletePhoto(photoType),
                    tooltip: '删除',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showPhotoOptions(photoType),
                    tooltip: '更换',
                  ),
                ] else if (!_isSelectionMode && !hasPhoto)
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                    onPressed: () => _showPhotoOptions(photoType),
                    tooltip: '上传',
                  ),
              ],
            ),
          ),
          
          
          if (hasPhoto)
            GestureDetector(
              onTap: _isSelectionMode
                  ? () => _togglePhotoSelection(photoType)
                  : () => _showPhotoPreview(photo),
              onLongPress: !_isSelectionMode
                  ? () {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedPhotoTypes.add(photoType);
                      });
                    }
                  : null,
              child: Container(
                width: double.infinity,
                height: 200,
                color: isSelected ? Colors.blue.shade50 : Colors.grey.shade200,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasPhoto && photo['url'] != null
                          ? SecureImage(
                              url: '${photo['url']}?t=$_cacheBuster',
                              fit: BoxFit.cover,
                              placeholder: const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error, size: 48, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text('加载失败', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.photo_camera,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                            ),
                    ),
                    if (_isSelectionMode && isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _isSelectionMode
                  ? null
                  : () => _showPhotoOptions(photoType),
              child: Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击上传照片',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showPhotoPreview(Map<String, dynamic> photo) {
    
    final photoUrl = '${AppConfig.apiBaseUrl}${photo['url']}?t=$_cacheBuster';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoPreviewPage(
          photoUrl: photoUrl,
          photoType: photo['photo_type'],
        ),
      ),
    );
  }
}


class _PhotoPreviewPage extends StatelessWidget {
  final String photoUrl;
  final String photoType;
  
  const _PhotoPreviewPage({
    required this.photoUrl,
    required this.photoType,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(photoType),
      ),
      body: Center(
        child: InteractiveViewer(
          child: SecureImage(
            url: photoUrl,
            fit: BoxFit.contain,
            placeholder: const Center(child: CircularProgressIndicator()),
            errorWidget: const Center(child: Icon(Icons.error, size: 48)),
          ),
        ),
      ),
    );
  }
}
