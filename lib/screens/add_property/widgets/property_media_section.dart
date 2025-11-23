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
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to 10 photos. Tap and hold to reorder.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        // Image Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Add Image Button
            if (images.length < 10)
              _AddImageButton(
                onTap: onPickImages,
                colorScheme: colorScheme,
              ),
            // Image Thumbnails
            ...images.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return _ImageThumbnail(
                image: image,
                index: index,
                isCover: index == coverImageIndex,
                onRemove: () => onRemoveImage(index),
                onSetCover: () => onSetCoverImage(index),
                colorScheme: colorScheme,
              );
            }),
          ],
        ),
        // Cover Image Indicator
        if (images.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Cover image: Tap a photo to set as cover',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
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
        width: 100,
        height: 100,
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

class _ImageThumbnail extends StatelessWidget {
  final XFile image;
  final int index;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback onSetCover;
  final ColorScheme colorScheme;

  const _ImageThumbnail({
    required this.image,
    required this.index,
    required this.isCover,
    required this.onRemove,
    required this.onSetCover,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSetCover,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCover
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isCover ? 2.5 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(image.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          // Cover Badge
          if (isCover)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Cover',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          // Remove Button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
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
        ],
      ),
    );
  }
}

