import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/permission_service.dart';
import 'features/media_gallery/presentation/screens/gallery_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MemoriesApplication()));
}

class MemoriesApplication extends StatefulWidget {
  const MemoriesApplication({super.key});

  @override
  State<MemoriesApplication> createState() => _MemoriesApplicationState();
}

class _MemoriesApplicationState extends State<MemoriesApplication> {
  final PermissionService _permissionService = ProductionPermissionService();
  bool _permissionsApproved = false;
  bool _evaluating = true;

  @override
  void initState() {
    super.initState();
    _executePermissionValidationProcess();
  }

  Future<void> _executePermissionValidationProcess() async {
    // Explicitly toggle evaluating state to show loading spinner if user re-triggers
    if (!_evaluating) {
      setState(() => _evaluating = true);
    }

    bool passed = await _permissionService.checkPermissionStatus();
    if (!passed) {
      passed = await _permissionService.requestGalleryAndStoragePermissions();
    }
    setState(() {
      _permissionsApproved = passed;
      _evaluating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkBaseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF64FFDA),
        surface: Color(0xFF0A0A0A),
      ),
    );

    // FIXED: Only one MaterialApp is returned. We alternate the target 'home' property layout instead.
    return MaterialApp(
      title: 'Memories',
      debugShowCheckedModeBanner: false,
      theme: darkBaseTheme,
      home: _buildCurrentScreenState(),
    );
  }

  Widget _buildCurrentScreenState() {
    if (_evaluating) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
        ),
      );
    }

    return _permissionsApproved
        ? const GalleryDashboard()
        : _buildAccessDeniedScreen();
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FIX: Swapped out undefined 'security_disabled' icon for a valid material token
            const Icon(
              Icons.no_encryption_gmailerrorred,
              size: 72,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              'Storage Permissions Needed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Memories requires storage access permissions to scan and show your local hardware images, videos, and documents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: Colors.black,
              ),
              onPressed: _executePermissionValidationProcess,
              child: const Text('Re-evaluate Storage Permissions'),
            )
          ],
        ),
      ),
    );
  }
}
