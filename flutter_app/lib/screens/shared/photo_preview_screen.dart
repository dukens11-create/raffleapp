import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/photo_service.dart';

/// Photo preview screen before upload
/// 
/// Features:
/// - Full-screen photo preview
/// - Confirm or retake options
/// - Upload progress indicator
/// - File size display
class PhotoPreviewScreen extends StatefulWidget {
  final File photoFile;
  final String? title;
  final Function(File)? onConfirm;
  final Function()? onRetake;

  const PhotoPreviewScreen({
    super.key,
    required this.photoFile,
    this.title = 'Photo Preview',
    this.onConfirm,
    this.onRetake,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  final PhotoService _photoService = PhotoService();
  double? _fileSizeMB;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFileSize();
  }

  Future<void> _loadFileSize() async {
    final sizeMB = await _photoService.getFileSizeMB(widget.photoFile);
    setState(() => _fileSizeMB = sizeMB);
  }

  void _handleConfirm() {
    if (widget.onConfirm != null) {
      widget.onConfirm!(widget.photoFile);
    } else {
      Navigator.of(context).pop(widget.photoFile);
    }
  }

  void _handleRetake() {
    if (widget.onRetake != null) {
      widget.onRetake!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title ?? 'Photo Preview'),
        backgroundColor: Colors.black,
        actions: [
          if (_fileSizeMB != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '${_fileSizeMB!.toStringAsFixed(2)} MB',
                  style: TextStyle(
                    color: _fileSizeMB! > 2.0 ? Colors.orange : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Photo preview
                Expanded(
                  child: InteractiveViewer(
                    child: Center(
                      child: Image.file(
                        widget.photoFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black,
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Retake button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleRetake,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Retake'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Confirm button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleConfirm,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
