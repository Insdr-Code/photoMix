import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/gallery_providers.dart';
import '../../domain/gallery_models.dart';

class GalleryImageTile extends ConsumerStatefulWidget {
  const GalleryImageTile({
    required this.image,
    this.filePath,
    required this.onTap,
    required this.isBackground,
    required this.selectionIndex,
    super.key,
  });

  final GalleryImage image;
  final String? filePath;
  final VoidCallback onTap;
  final bool isBackground;
  final int? selectionIndex;

  @override
  ConsumerState<GalleryImageTile> createState() => _GalleryImageTileState();
}

class _GalleryImageTileState extends ConsumerState<GalleryImageTile> {
  late Future<Uint8List?> _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant GalleryImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.id != widget.image.id ||
        oldWidget.filePath != widget.filePath) {
      _thumbnail = _loadThumbnail();
    }
  }

  Future<Uint8List?> _loadThumbnail() {
    if (widget.filePath != null) return Future.value();
    return ref
        .read(galleryRepositoryProvider)
        .getThumbnail(widget.image, size: 320);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isBackground || widget.selectionIndex != null;

    return Semantics(
      button: true,
      selected: isSelected,
      label: widget.image.name,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<Uint8List?>(
                  future: _thumbnail,
                  builder: (context, snapshot) {
                    final filePath = widget.filePath;
                    if (filePath != null) {
                      return Image.file(
                        File(filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imagePlaceholder(),
                      );
                    }
                    final bytes = snapshot.data;
                    if (bytes == null) {
                      return _imagePlaceholder();
                    }
                    return Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  },
                ),
                if (isSelected)
                  ColoredBox(color: AppColors.primary.withValues(alpha: 0.16)),
                if (widget.isBackground)
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: _BackgroundBadge(),
                    ),
                  ),
                if (widget.selectionIndex case final index?)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _SelectionBadge(index: index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const ColoredBox(
      color: AppColors.background,
      child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
    );
  }
}

class _BackgroundBadge extends StatelessWidget {
  const _BackgroundBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'FONDO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$index',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
