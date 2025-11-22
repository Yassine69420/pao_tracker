import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPicker extends StatefulWidget {
  final String? photoPath;
  final void Function(String?) onPick;
  final VoidCallback? onRemove;
  const PhotoPicker({
    super.key,
    required this.photoPath,
    required this.onPick,
    this.onRemove,
  });

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) widget.onPick(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;
    final p = widget.photoPath;

    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline, width: 1.5),
          ),
          child: p != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(p), fit: BoxFit.cover),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 20,

                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      if (widget.onRemove !=
                          null) // Only show remove if callback is provided
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: widget.onRemove,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withOpacity(0.95),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 20,

                                color: colorScheme.onError,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 44,

                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
