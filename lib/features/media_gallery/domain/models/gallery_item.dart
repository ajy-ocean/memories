import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

enum GalleryItemType { photo, video, rawPhoto, pdf, plainText, unknown }

class GalleryItem {
  final String id;
  final String name;
  final GalleryItemType type;
  final DateTime creationDate;
  final int size;
  final AssetEntity? mediaEntity;
  final File? documentFile;

  GalleryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.creationDate,
    required this.size,
    this.mediaEntity,
    this.documentFile,
  });

  factory GalleryItem.fromMediaEntity(AssetEntity entity) {
    GalleryItemType t = GalleryItemType.unknown;
    if (entity.type == AssetType.image) {
      // Check if it's a RAW image format
      final titleLower = entity.title?.toLowerCase() ?? '';
      if (titleLower.endsWith('.dng')) {
        t = GalleryItemType.rawPhoto;
      } else {
        t = GalleryItemType.photo;
      }
    } else if (entity.type == AssetType.video) {
      t = GalleryItemType.video;
    }

    return GalleryItem(
      id: 'media_${entity.id}',
      name: entity.title ?? 'Unknown Media',
      type: t,
      creationDate: entity.createDateTime,
      size: 0,
      mediaEntity: entity,
    );
  }

  factory GalleryItem.fromFile(File file, GalleryItemType docType) {
    final stats = file.statSync();
    return GalleryItem(
      id: 'doc_${file.path.hashCode}',
      name: file.path.split('/').last,
      type: docType,
      creationDate: stats.modified,
      size: stats.size,
      documentFile: file,
    );
  }
}
