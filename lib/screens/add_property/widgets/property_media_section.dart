import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Section for uploading and managing property images
/// 
/// Features:
/// - Upload up to 10 images
/// - Preview thumbnails
/// - Reorder images (drag to reorder)
/// - Remove images
/// - Set cover image
class PropertyMediaSection extends StatelessWidget {
  final List<XFile> images;
  final int coverImageIndex;
  final VoidCallback onPickImages;
  final Function(int) onRemoveImage;
  final Function(int) onSetCoverImage;
  final Function(int, int) onReorderImage;

  const PropertyMediaSection({
    super.key,
    required this.images,
    required this.coverImageIndex,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSetCoverImage,
    required this.onReorderImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Photos',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Double tap to set cover • Drag to reorder',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        // Image Grid - 3 photos per row, max 18 photos, with drag to reorder
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final spacing = 12.0;
            final itemWidth = (screenWidth - (spacing * 2)) / 3; // 3 items per row
            
            // Reorder images so cover is first
            final orderedImages = List<XFile>.from(images);
            if (orderedImages.isNotEmpty && coverImageIndex < orderedImages.length && coverImageIndex > 0) {
              final coverImage = orderedImages.removeAt(coverImageIndex);
              orderedImages.insert(0, coverImage);
            }
            
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                // Add Image Button
                if (images.length < 18)
                  SizedBox(
                    width: itemWidth,
                    height: itemWidth,
                    child: _AddImageButton(
                      onTap: onPickImages,
                      colorScheme: colorScheme,
                    ),
                  ),
                // Image Thumbnails - display 3 per row with drag to reorder
                ...orderedImages.take(18).toList().asMap().entries.map((entry) {
                  final displayIndex = entry.key;
                  final image = entry.value;
                  // Find original index
                  final originalIndex = images.indexOf(image);
                  final isCover = originalIndex == coverImageIndex;
                  
                  return SizedBox(
                    key: ValueKey('image_$originalIndex'),
                    width: itemWidth,
                    height: itemWidth,
                    child: _ImageThumbnail(
                      image: image,
                      index: originalIndex,
                      isCover: isCover,
                      onRemove: () => onRemoveImage(originalIndex),
                      onSetCover: () => onSetCoverImage(originalIndex),
                      onReorder: (newIndex) => onReorderImage(originalIndex, newIndex),
                      totalImages: images.length,
                      colorScheme: colorScheme,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _AddImageButton({
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatefulWidget {
  final XFile image;
  final int index;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback onSetCover;
  final Function(int) onReorder;
  final int totalImages;
  final ColorScheme colorScheme;

  const _ImageThumbnail({
    super.key,
    required this.image,
    required this.index,
    required this.isCover,
    required this.onRemove,
    required this.onSetCover,
    required this.onReorder,
    required this.totalImages,
    required this.colorScheme,
  });

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  bool _isDragging = false;
  Offset? _dragStartPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.onSetCover,
      onLongPressStart: (details) {
        setState(() {
          _isDragging = true;
          _dragStartPosition = details.localPosition;
        });
      },
      onLongPressEnd: (details) {
        setState(() {
          _isDragging = false;
          _dragStartPosition = null;
        });
      },
      onLongPressMoveUpdate: (details) {
        if (_dragStartPosition == null) return;
        
        final deltaY = details.localPosition.dy - _dragStartPosition!.dy;
        final threshold = 30.0;
        
        if (deltaY < -threshold && widget.index > 0) {
          // Move up
          widget.onReorder(widget.index - 1);
          _dragStartPosition = details.localPosition;
        } else if (deltaY > threshold && widget.index < widget.totalImages - 1) {
          // Move down
          widget.onReorder(widget.index + 1);
          _dragStartPosition = details.localPosition;
        }
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isCover
                    ? widget.colorScheme.primary
                    : widget.colorScheme.outline.withValues(alpha: 0.3),
                width: widget.isCover ? 2.5 : 1.5,
              ),
              boxShadow: _isDragging
                  ? [
                      BoxShadow(
                        color: widget.colorScheme.primary.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: _isDragging ? 0.7 : 1.0,
                child: Image.file(
                  File(widget.image.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: widget.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        color: widget.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Cover Badge
          if (widget.isCover)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Cover',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: widget.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          // Remove Button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Drag indicator
          if (_isDragging)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.drag_handle,
                    color: widget.colorScheme.primary,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

