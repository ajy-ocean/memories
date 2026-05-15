import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../domain/models/gallery_item.dart';

class GalleryState {
  final List<AssetPathEntity> albums;
  final AssetPathEntity? selectedAlbum;
  final List<GalleryItem> items;
  final List<GalleryItem> importedDocuments;
  final bool isLoading;
  final int currentMediaPage;
  final bool hasMoreMedia;
  final bool viewDocumentsOnly;

  GalleryState({
    this.albums = const [],
    this.selectedAlbum,
    this.items = const [],
    this.importedDocuments = const [],
    this.isLoading = false,
    this.currentMediaPage = 0,
    this.hasMoreMedia = true,
    this.viewDocumentsOnly = false,
  });

  GalleryState copyWith({
    List<AssetPathEntity>? albums,
    AssetPathEntity? selectedAlbum,
    List<GalleryItem>? items,
    List<GalleryItem>? importedDocuments,
    bool? isLoading,
    int? currentMediaPage,
    bool? hasMoreMedia,
    bool? viewDocumentsOnly,
  }) {
    return GalleryState(
      albums: albums ?? this.albums,
      selectedAlbum: selectedAlbum ?? this.selectedAlbum,
      items: items ?? this.items,
      importedDocuments: importedDocuments ?? this.importedDocuments,
      isLoading: isLoading ?? this.isLoading,
      currentMediaPage: currentMediaPage ?? this.currentMediaPage,
      hasMoreMedia: hasMoreMedia ?? this.hasMoreMedia,
      viewDocumentsOnly: viewDocumentsOnly ?? this.viewDocumentsOnly,
    );
  }
}

class GalleryNotifier extends StateNotifier<GalleryState> {
  final GalleryRepository _repository;
  static const int _pageSize = 60;

  GalleryNotifier(this._repository) : super(GalleryState());

  Future<void> initializeEngine() async {
    state = state.copyWith(isLoading: true);
    try {
      final albums = await _repository.fetchMediaAlbums();
      if (albums.isNotEmpty) {
        state = state.copyWith(albums: albums, selectedAlbum: albums.first);
        await fetchNextPage(reset: true);
      } else {
        state = state.copyWith(isLoading: false, hasMoreMedia: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextPage({bool reset = false}) async {
    if (state.viewDocumentsOnly) return;
    if (!state.hasMoreMedia && !reset) return;
    if (state.selectedAlbum == null) return;

    final targetPage = reset ? 0 : state.currentMediaPage + 1;
    final nextItems = await _repository.fetchMediaFromAlbum(
      state.selectedAlbum!,
      page: targetPage,
      pageSize: _pageSize,
    );

    if (nextItems.isEmpty) {
      state = state.copyWith(hasMoreMedia: false);
      return;
    }

    state = state.copyWith(
      items: reset ? nextItems : [...state.items, ...nextItems],
      currentMediaPage: targetPage,
      hasMoreMedia: nextItems.length == _pageSize,
      isLoading: false,
    );
  }

  Future<void> switchAlbum(AssetPathEntity album) async {
    state = state.copyWith(
      selectedAlbum: album,
      items: [],
      currentMediaPage: 0,
      hasMoreMedia: true,
      viewDocumentsOnly: false,
    );
    await fetchNextPage(reset: true);
  }

  Future<void> importDocumentsPipeline() async {
    final docs = await _repository.pickExternalDocuments();
    if (docs.isNotEmpty) {
      state = state.copyWith(
        importedDocuments: [...state.importedDocuments, ...docs],
      );
    }
  }

  void toggleViewMode(bool docsOnly) {
    state = state.copyWith(viewDocumentsOnly: docsOnly);
  }
}

final galleryEngineProvider =
    StateNotifierProvider<GalleryNotifier, GalleryState>((ref) {
  return GalleryNotifier(GalleryRepository());
});
