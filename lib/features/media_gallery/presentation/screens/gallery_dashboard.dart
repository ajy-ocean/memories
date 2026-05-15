import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:memories/features/media_gallery/presentation/controllers/media_fetcher.dart';
import 'package:video_player/video_player.dart';
import 'package:open_filex/open_filex.dart';

class GalleryDashboard extends ConsumerWidget {
  const GalleryDashboard({super.key});

  static const Color brandRed = Color(0xFFD32F2F);
  static const Color lightBg = Color(0xFFFDFDFD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the folder-based providers
    final photoFoldersAsync = ref.watch(photoFoldersProvider);
    final videoFoldersAsync = ref.watch(videoFoldersProvider);
    final docs = ref.watch(docsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: lightBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'MEMORIES ENGINE',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: brandRed,
            labelColor: brandRed,
            unselectedLabelColor: Colors.grey,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.photo_library_outlined), text: 'PHOTOS'),
              Tab(icon: Icon(Icons.video_library_outlined), text: 'VIDEOS'),
              Tab(icon: Icon(Icons.description_outlined), text: 'DOCS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. PHOTOS TAB (Grouped by Folder)
            photoFoldersAsync.when(
              data: (folders) => _buildFolderListView(folders, isVideo: false),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: brandRed)),
              error: (err, stack) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: brandRed))),
            ),

            // 2. VIDEOS TAB (Grouped by Folder)
            videoFoldersAsync.when(
              data: (folders) => _buildFolderListView(folders, isVideo: true),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: brandRed)),
              error: (err, stack) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: brandRed))),
            ),

            // 3. DOCUMENTS TAB
            _buildDocsTab(context, ref, docs),
          ],
        ),
      ),
    );
  }

  // Loops through device folders and creates a dedicated section for each one
  Widget _buildFolderListView(List<AssetPathEntity> folders,
      {required bool isVideo}) {
    final activeFolders = folders;

    if (activeFolders.isEmpty) {
      return const Center(
        child: Text('NO ALBUMS FOUND',
            style: TextStyle(color: Colors.grey, letterSpacing: 1.0)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      itemCount: activeFolders.length,
      itemBuilder: (context, index) {
        final folder = activeFolders[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Title Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    folder.name.toUpperCase(), // e.g., RECENT, CAMERA
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                        color: Colors.black87),
                  ),
                  FutureBuilder<int>(
                    future: folder.assetCountAsync,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count',
                        style: const TextStyle(
                            color: brandRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Horizontal container displaying thumbnails within that folder
            SizedBox(
              height: 120,
              child: FutureBuilder<List<AssetEntity>>(
                future: folder.getAssetListRange(
                    start: 0, end: 50), // Get first 50 items
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }
                  final assets = snapshot.data!;

                  if (assets.isEmpty) {
                    return const SizedBox(); // Don't show empty folder rails
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: assets.length,
                    itemBuilder: (context, assetIndex) {
                      final asset = assets[assetIndex];
                      return GestureDetector(
                        // Intercepts click events and routes to full viewports
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => isVideo
                                  ? FullScreenVideoViewer(asset: asset)
                                  : FullScreenPhotoViewer(asset: asset),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image(
                                  image: AssetEntityImageProvider(asset,
                                      isOriginal: false),
                                  fit: BoxFit.cover,
                                ),
                                if (isVideo)
                                  const Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: CircleAvatar(
                                      backgroundColor: Color(
                                          0xCCFFFFFF), // Soft 80% opacity translucent white overlay
                                      radius: 10,
                                      child: Icon(Icons.play_arrow,
                                          size: 12, color: brandRed),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(
                height: 24, thickness: 0.5, indent: 16, endIndent: 16),
          ],
        );
      },
    );
  }

  // Implementation for Document indexing and manual importing matching your theme rules
  // Updated Implementation for Document indexing with native opening triggers
  Widget _buildDocsTab(BuildContext context, WidgetRef ref, List<File> docs) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandRed,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
              elevation: 0,
            ),
            onPressed: () => ref.read(docsProvider.notifier).pickDocuments(),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('IMPORT DOCUMENTS',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: docs.isEmpty
                ? const Center(
                    child: Text('NO DOCUMENTS IMPORTED',
                        style:
                            TextStyle(color: Colors.grey, letterSpacing: 1.0)))
                : ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final file = docs[index];
                      final fileName = file.path.split('/').last;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border:
                              Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          // 👇 THIS TRIPPERS THE NATIVE OS FILE VIEWER
                          onTap: () async {
                            final result = await OpenFilex.open(file.path);

                            // Optional: Alert the user if the file couldn't be opened
                            if (result.type != ResultType.done &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Could not open file: ${result.message}'),
                                  backgroundColor: brandRed,
                                ),
                              );
                            }
                          },
                          child: ListTile(
                            leading: const Icon(Icons.article_outlined,
                                color: brandRed),
                            title: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                            subtitle: Text(
                              '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: const Icon(
                                Icons
                                    .open_in_new, // Changed to "open" icon indication
                                size: 16,
                                color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FULL SCREEN PHOTO VIEWER OVERLAY WIDGET
// ==========================================
class FullScreenPhotoViewer extends StatelessWidget {
  final AssetEntity asset;
  const FullScreenPhotoViewer({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark canvas for content isolation
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'IMAGE PREVIEW',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Center(
        child: FutureBuilder<File?>(
          future: asset.file,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                  color: GalleryDashboard.brandRed);
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Text('UNABLE TO RESOLVE FILE PATH',
                  style: TextStyle(color: Colors.white));
            }
            return Image.file(snapshot.data!, fit: BoxFit.contain);
          },
        ),
      ),
    );
  }
}

// ==========================================
// FULL SCREEN VIDEO VIEWER OVERLAY WIDGET
// ==========================================
class FullScreenVideoViewer extends StatefulWidget {
  final AssetEntity asset;
  const FullScreenVideoViewer({super.key, required this.asset});

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final File? file = await widget.asset.file;
    if (file != null) {
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller!.play(); // Start playback instantly upon entry
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'VIDEO PREVIEW',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Center(
        child: _isInitialized && _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller!),
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: GalleryDashboard.brandRed,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.black26,
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: GalleryDashboard.brandRed),
      ),
      floatingActionButton: _isInitialized && _controller != null
          ? FloatingActionButton(
              backgroundColor: GalleryDashboard.brandRed,
              foregroundColor: Colors.white,
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
