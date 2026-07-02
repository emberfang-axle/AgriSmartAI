import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../main.dart' show cameras;
import '../providers/detection_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;
  FlashMode _flashMode = FlashMode.off;
  int _selectedCamera = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_selectedCamera);
    }
  }

  Future<void> _initCamera() async {
    // On web, browser handles permission via getUserMedia — skip PermissionHandler
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        if (mounted) setState(() => _permissionPermanentlyDenied = true);
        return;
      }
      if (status.isDenied) {
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }
    }

    if (cameras.isEmpty) {
      if (mounted) {
        setState(() => _errorMessage = 'No camera found on this device.');
      }
      return;
    }

    await _startCamera(_selectedCamera);
  }

  Future<void> _startCamera(int index) async {
    final camera = cameras[index];
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = 'Camera initialization failed: ${e.toString()}');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    _controller?.dispose();
    setState(() => _isInitialized = false);
    _selectedCamera = (_selectedCamera + 1) % cameras.length;
    await _startCamera(_selectedCamera);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_isInitialized || _isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    try {
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();
      await _analyzeImage(bytes);
    } catch (e) {
      if (mounted) {
        _showError('Capture failed: ${e.toString()}');
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _analyzeImage(Uint8List bytes) async {
    try {
      final result = await ApiService().detectDisease(bytes);

      // Persist result
      if (mounted) {
        context.read<DetectionProvider>().addResult(result);
        context.read<NotificationProvider>().addDetectionNotification(result);
      }

      // Fire local push notification
      await NotificationService.showDiseaseAlert(
        disease: result.disease,
        confidence: result.confidence,
        severity: result.severity,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(result: result, imageBytes: bytes),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Analysis failed. Check server connection.');
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kErrorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData get _flashIcon => _flashMode == FlashMode.off
      ? Icons.flash_off_rounded
      : Icons.flash_on_rounded;

  @override
  Widget build(BuildContext context) {
    if (_permissionPermanentlyDenied) {
      return _PermissionDeniedView(
        permanent: true,
        onRetry: () async {
          await openAppSettings();
        },
      );
    }

    if (_permissionDenied) {
      return _PermissionDeniedView(
        permanent: false,
        onRetry: () {
          setState(() => _permissionDenied = false);
          _initCamera();
        },
      );
    }

    if (_errorMessage != null) {
      return _ErrorView(message: _errorMessage!);
    }

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kWarmGold),
              SizedBox(height: 16),
              Text('Starting camera...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Live camera preview ──────────────────────────────────────────
          CameraPreview(_controller!),

          // ── Top controls ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _CameraIconBtn(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Scan Rice Leaf',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _CameraIconBtn(
                        icon: _flashIcon,
                        onTap: _toggleFlash,
                        active: _flashMode == FlashMode.torch,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Position camera over the affected leaf',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scan frame overlay ────────────────────────────────────────────
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kWarmGold, width: 2.5),
              ),
              child: Stack(
                children: [
                  _Corner(top: 0, left: 0, tl: true),
                  _Corner(top: 0, right: 0, tr: true),
                  _Corner(bottom: 0, left: 0, bl: true),
                  _Corner(bottom: 0, right: 0, br: true),
                ],
              ),
            ),
          ),

          // ── Bottom controls ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Gallery placeholder (future feature)
                    const SizedBox(width: 56),

                    // Capture button
                    GestureDetector(
                      onTap: _isAnalyzing ? null : _captureAndAnalyze,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAnalyzing ? Colors.white38 : Colors.white,
                          border: Border.all(
                              color: Colors.white54, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isAnalyzing
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: kDeepGreen,
                                ),
                              )
                            : null,
                      ),
                    ),

                    // Camera switch
                    if (cameras.length > 1)
                      _CameraIconBtn(
                        icon: Icons.flip_camera_ios_rounded,
                        onTap: _switchCamera,
                      )
                    else
                      const SizedBox(width: 56),
                  ],
                ),
              ),
            ),
          ),

          // ── Analyzing overlay ─────────────────────────────────────────────
          if (_isAnalyzing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        color: kWarmGold,
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Analyzing Leaf...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI is detecting diseases',
                      style: TextStyle(color: Colors.white60, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _CameraIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  const _CameraIconBtn({
    required this.icon,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: active ? kWarmGold.withOpacity(0.85) : Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final double? top, bottom, left, right;
  final bool tl, tr, bl, br;
  const _Corner({
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: tl || tr ? const BorderSide(color: kWarmGold, width: 3) : BorderSide.none,
            bottom: bl || br ? const BorderSide(color: kWarmGold, width: 3) : BorderSide.none,
            left: tl || bl ? const BorderSide(color: kWarmGold, width: 3) : BorderSide.none,
            right: tr || br ? const BorderSide(color: kWarmGold, width: 3) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: tl ? const Radius.circular(4) : Radius.zero,
            topRight: tr ? const Radius.circular(4) : Radius.zero,
            bottomLeft: bl ? const Radius.circular(4) : Radius.zero,
            bottomRight: br ? const Radius.circular(4) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

// ── Permission denied view ────────────────────────────────────────────────────

class _PermissionDeniedView extends StatelessWidget {
  final bool permanent;
  final VoidCallback onRetry;

  const _PermissionDeniedView(
      {required this.permanent, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Camera Permission'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.grey, size: 80),
            const SizedBox(height: 24),
            Text(
              permanent
                  ? 'Camera Access Blocked'
                  : 'Camera Permission Required',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kDeepGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              permanent
                  ? 'Camera access was permanently denied. Please enable it in your device Settings to scan rice leaves.'
                  : 'AgriSmartAI needs camera access to scan and detect diseases on your rice leaves.',
              style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(permanent ? Icons.settings : Icons.refresh),
              label: Text(permanent ? 'Open Settings' : 'Grant Permission'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Camera Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: kErrorRed, size: 64),
              const SizedBox(height: 16),
              const Text('Camera Error',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kDeepGreen)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
