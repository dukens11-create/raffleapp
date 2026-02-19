import 'dart:io';
import 'package:flutter/material.dart';
import '../services/photo_service.dart';

/// Reusable photo picker widget with camera and gallery options
/// 
/// Features:
/// - Camera capture
/// - Gallery selection
/// - Photo preview
/// - Remove photo option
class PhotoPickerWidget extends StatefulWidget {
  final File? initialPhoto;
  final ValueChanged<File?> onPhotoChanged;
  final String? labelText;
  final bool enabled;

  const PhotoPickerWidget({
    super.key,
    this.initialPhoto,
    required this.onPhotoChanged,
    this.labelText = 'Photo',
    this.enabled = true,
  });

  @override
  State<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends State<PhotoPickerWidget> {
  final PhotoService _photoService = PhotoService();
  File? _photo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _photo = widget.initialPhoto;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (!widget.enabled) return;

    setState(() => _isLoading = true);

    try {
      File? photo;
      if (source == ImageSource.camera) {
        photo = await _photoService.takePhoto();
      } else {
        photo = await _photoService.pickFromGallery();
      }

      if (photo != null) {
        // Check file size
        final sizeMB = await _photoService.getFileSizeMB(photo);
        if (sizeMB > 2.0) {
          // Compress if too large
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compressing large image...'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          photo = await _photoService.compressImage(photo);
        }

        setState(() => _photo = photo);
        widget.onPhotoChanged(photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removePhoto() {
    setState(() => _photo = null);
    widget.onPhotoChanged(null);
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_photo != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.labelText!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        
        InkWell(
          onTap: widget.enabled ? _showPhotoOptions : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _photo != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _photo!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (widget.enabled)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                                onPressed: _removePhoto,
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}

// Import for ImageSource
import 'package:image_picker/image_picker.dart';
