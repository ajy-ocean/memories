import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

// 1. Photo Folders Provider
final photoFoldersProvider = FutureProvider<List<AssetPathEntity>>((ref) async {
  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  if (!ps.isAuth) return [];
  
  return await PhotoManager.getAssetPathList(
    type: RequestType.image,
  );
});

// 2. Video Folders Provider
final videoFoldersProvider = FutureProvider<List<AssetPathEntity>>((ref) async {
  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  if (!ps.isAuth) return [];
  
  return await PhotoManager.getAssetPathList(
    type: RequestType.video,
  );
});

// 3. Document Picker Provider (Missing Link)
final docsProvider = StateNotifierProvider<DocsNotifier, List<File>>((ref) {
  return DocsNotifier();
});

class DocsNotifier extends StateNotifier<List<File>> {
  DocsNotifier() : super([]);

  Future<void> pickDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: true,
      );

      if (result != null && result.paths.isNotEmpty) {
        // Convert non-null paths into File objects safely
        state = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      }
    } catch (e) {
      // Fail silently or add logging depending on requirements
      state = [];
    }
  }
}