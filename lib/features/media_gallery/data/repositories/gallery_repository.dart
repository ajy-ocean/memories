import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/models/gallery_item.dart';

class GalleryRepository {
  Future<List<AssetPathEntity>> fetchMediaAlbums() async {
    return await PhotoManager.getAssetPathList(
      type: RequestType.common, // Fetches Images (including DNG if system indexed) and Videos (MOV)
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(minWidth: 10, minHeight: 10),
          // Cleaned: Removed invalid 'needLivePhotos' parameter causing compilation crash
        ),
      ),
    );
  }

  Future<List<GalleryItem>> fetchMediaFromAlbum(
    AssetPathEntity album, {
    required int page,
    required int pageSize,
  }) async {
    final entities = await album.getAssetListPaged(page: page, size: pageSize);
    return entities.map((e) => GalleryItem.fromMediaEntity(e)).toList();
  }

  Future<List<GalleryItem>> pickExternalDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'json', 'md', 'dng', 'mov'], // Added tracking parameters
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    List<GalleryItem> documents = [];
    for (var fileData in result.files) {
      if (fileData.path != null) {
        final file = File(fileData.path!);
        final ext = fileData.extension?.toLowerCase();
        
        GalleryItemType type = GalleryItemType.plainText;
        if (ext == 'pdf') type = GalleryItemType.pdf;
        if (ext == 'dng') type = GalleryItemType.rawPhoto;
        if (ext == 'mov') type = GalleryItemType.video;

        documents.add(GalleryItem.fromFile(file, type));
      }
    }
    return documents;
  }
}