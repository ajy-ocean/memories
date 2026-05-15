import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class PermissionService {
  Future<bool> requestGalleryAndStoragePermissions();
  Future<bool> checkPermissionStatus();
}

class ProductionPermissionService implements PermissionService {
  @override
  Future<bool> checkPermissionStatus() async {
    if (Platform.isAndroid) {
      final photoStatus = await Permission.photos.status;
      final videoStatus = await Permission.videos.status;
      return photoStatus.isGranted && videoStatus.isGranted;
    } else {
      final status = await Permission.storage.status;
      return status.isGranted || status.isLimited;
    }
  }

  @override
  Future<bool> requestGalleryAndStoragePermissions() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    if (state.isAuth) return true;

    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.videos,
      ].request();
      return statuses[Permission.photos]!.isGranted && statuses[Permission.videos]!.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }
}