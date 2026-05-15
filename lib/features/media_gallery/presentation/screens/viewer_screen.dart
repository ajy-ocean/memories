import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../domain/models/gallery_item.dart';

class ViewerScreen extends StatelessWidget {
  final GalleryItem item;

  const ViewerScreen({super.key, required this.item});

  Future<void> _triggerShare() async {
    if (item.mediaEntity != null) {
      final file = await item.mediaEntity!.file;
      if (file != null) {
        await Share.shareXFiles([XFile(file.path)], text: item.name);
      }
    } else if (item.documentFile != null) {
      await Share.shareXFiles([XFile(item.documentFile!.path)],
          text: item.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(item.name,
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        actions: [
          IconButton(
              icon: const Icon(Icons.share_outlined), onPressed: _triggerShare),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        color: Colors.black,
        child: _buildViewportTarget(),
      ),
    );
  }

  Widget _buildViewportTarget() {
    if (item.mediaEntity != null && item.type != GalleryItemType.video) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: AssetEntityImage(
            item.mediaEntity!,
            isOriginal: true,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Color(0xFF64FFDA))),
            errorBuilder: (_, __, ___) => const Center(
              child: Text('Failed to render raw image resolution.',
                  style: TextStyle(color: Colors.white54)),
            ),
          ),
        ),
      );
    }

    if (item.type == GalleryItemType.video) {
      return _ProductionVideoPlayerEngine(item: item);
    }

    if (item.type == GalleryItemType.pdf && item.documentFile != null) {
      return PDFView(
        filePath: item.documentFile!.path,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: true,
        onError: (error) => Center(
            child: Text('PDF Error: $error',
                style: const TextStyle(color: Colors.white))),
      );
    }

    if (item.documentFile != null) {
      if (item.type == GalleryItemType.rawPhoto) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.raw_on, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(item.name, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              const Text('RAW imported file isolated outside MediaStore cache.',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        );
      }

      return FutureBuilder<String>(
        future: item.documentFile!.readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF64FFDA)));
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text(
                    'Unreadable binary configuration or metadata format.',
                    style: TextStyle(color: Colors.white)));
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18.0),
              child: Text(
                snapshot.data ?? '',
                // FIX: Converted illegal native getter 'Colors.whiteE6' into raw hexadecimal instantiation
                style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontFamily: 'monospace',
                    fontSize: 13),
              ),
            ),
          );
        },
      );
    }

    return const Center(
        child: Text('Unsupported viewport configuration.',
            style: TextStyle(color: Colors.white)));
  }
}

class _ProductionVideoPlayerEngine extends StatefulWidget {
  final GalleryItem item;
  const _ProductionVideoPlayerEngine({required this.item});

  @override
  State<_ProductionVideoPlayerEngine> createState() =>
      _ProductionVideoPlayerEngineState();
}

class _ProductionVideoPlayerEngineState
    extends State<_ProductionVideoPlayerEngine> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlaybackEngine();
  }

  Future<void> _initializePlaybackEngine() async {
    try {
      if (widget.item.mediaEntity != null) {
        final file = await widget.item.mediaEntity!.file;
        if (file != null) {
          _controller = VideoPlayerController.file(file);
        }
      } else if (widget.item.documentFile != null) {
        _controller = VideoPlayerController.file(widget.item.documentFile!);
      }

      if (_controller != null) {
        await _controller!.initialize();
        setState(() {
          _initialized = true;
        });
        _controller!.play();
        _controller!.setLooping(true);
      } else {
        setState(() => _hasError = true);
      }
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
          child: Text('Codec error: Unsupported video encoding.',
              style: TextStyle(color: Colors.white54)));
    }
    if (!_initialized) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF64FFDA)));
    }
    return GestureDetector(
      onTap: () {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
        setState(() {});
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),
              if (!_controller!.value.isPlaying)
                const CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: Icon(Icons.play_arrow, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
