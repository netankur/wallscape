import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:async_wallpaper/async_wallpaper.dart'; // <--- Added wallpaper package
import '../main.dart';

class DetailScreen extends StatefulWidget {
  final dynamic wallpaper;
  const DetailScreen({Key? key, required this.wallpaper}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isProcessing = false;
  double processProgress = 0.0;
  String processText = "";

  // ------------------------------------
  // 1. NATIVE WALLPAPER SETTER (ANDROID ONLY)
  // ------------------------------------
  Future<void> _setWallpaper(WallpaperTarget location) async {
    Navigator.pop(context); // Close the modal
    setState(() { isProcessing = true; processProgress = 0.0; processText = "Applying Wallpaper..."; });
    
    try {
      var tempDir = await getTemporaryDirectory();
      String savePath = "${tempDir.path}/wallscape_temp_${widget.wallpaper['id']}.jpg";

      // Always use high quality for direct wallpaper application
      String downloadUrl = widget.wallpaper['src']['large2x'] ?? widget.wallpaper['src']['original'];

      await Dio().download(downloadUrl, savePath, onReceiveProgress: (received, total) {
        if (total != -1) setState(() => processProgress = received / total);
      });

      await AsyncWallpaper.setWallpaper(
        WallpaperRequest(
          source: savePath,
          sourceType: WallpaperSourceType.file,
          target: location,
          goToHome: false,
        )
      );

      setState(() => isProcessing = false);
      _showCustomToast("Wallpaper applied successfully!", isSuccess: true);
    } catch (e) {
      setState(() => isProcessing = false);
      _showCustomToast("Failed to apply wallpaper.", isSuccess: false);
    }
  }

  // ------------------------------------
  // 2. DOWNLOAD TO GALLERY
  // ------------------------------------
  Future<void> _downloadImage() async {
    setState(() { isProcessing = true; processProgress = 0.0; processText = "Downloading ${imageQualityConfig.value}..."; });
    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      var tempDir = await getTemporaryDirectory();
      String savePath = "${tempDir.path}/wallscape_${widget.wallpaper['id']}.jpg";

      String downloadUrl = widget.wallpaper['src']['original'];
      if (imageQualityConfig.value == 'Large (4K)') downloadUrl = widget.wallpaper['src']['large2x'] ?? downloadUrl;
      else if (imageQualityConfig.value == 'Medium (HD)') downloadUrl = widget.wallpaper['src']['large'] ?? downloadUrl;

      await Dio().download(downloadUrl, savePath, onReceiveProgress: (received, total) {
        if (total != -1) setState(() => processProgress = received / total);
      });

      await Gal.putImage(savePath);
      setState(() => isProcessing = false);
      _showCustomToast("Saved in ${imageQualityConfig.value}", isSuccess: true);
    } catch (e) {
      setState(() => isProcessing = false);
      _showCustomToast("Error downloading image.", isSuccess: false);
    }
  }

  // ------------------------------------
  // 3. UI HELPERS & MODALS
  // ------------------------------------
  void _showCustomToast(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.exclamationmark_circle_fill, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF2C2C2C) : Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 110, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite() {
    final currentList = List<dynamic>.from(favoriteWallpapers.value);
    final exists = currentList.any((w) => w['id'] == widget.wallpaper['id']);
    
    if (exists) {
      currentList.removeWhere((w) => w['id'] == widget.wallpaper['id']);
      _showCustomToast("Removed from Favorites", isSuccess: false);
    } else {
      currentList.add(widget.wallpaper);
      _showCustomToast("Added to Favorites", isSuccess: true);
    }
    
    favoriteWallpapers.value = currentList;
    prefs.setString('wallscape_favorites', jsonEncode(currentList));
  }

  void _showSetWallpaperModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF070707).withOpacity(0.8),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 30),
                  const Text("Apply Wallpaper", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  _buildModalOption(CupertinoIcons.home, "Home Screen", () => _setWallpaper(WallpaperTarget.home)),
                  const SizedBox(height: 12),
                  _buildModalOption(CupertinoIcons.lock, "Lock Screen", () => _setWallpaper(WallpaperTarget.lock)),
                  const SizedBox(height: 12),
                  _buildModalOption(CupertinoIcons.device_phone_portrait, "Both Screens", () => _setWallpaper(WallpaperTarget.both)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Info Panel Modal (Kept exactly as you had it)
  void _showInfoPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: const Color(0xFF070707).withOpacity(0.7), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 30),
                  const Text("Image Information", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  _buildInfoRow(CupertinoIcons.camera, "Photographer", widget.wallpaper['photographer'] ?? "Unknown"),
                  const SizedBox(height: 16),
                  _buildInfoRow(CupertinoIcons.arrow_up_left_arrow_down_right, "Resolution", "${widget.wallpaper['width']} x ${widget.wallpaper['height']}"),
                  const SizedBox(height: 16),
                  _buildInfoRow(CupertinoIcons.paintbrush, "Hex Color", widget.wallpaper['avg_color'] ?? "#000000"),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ])
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          Hero(
            tag: '${widget.wallpaper['id']}',
            child: SizedBox(
              width: double.infinity, height: double.infinity,
              child: CachedNetworkImage(
                imageUrl: widget.wallpaper['src']['large2x'],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFF070707)),
              ),
            ),
          ),
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopButton(CupertinoIcons.back, () => Navigator.pop(context)),
                _buildTopButton(CupertinoIcons.info, _showInfoPanel),
              ],
            ),
          ),
          
          // Bottom Control Bar
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(color: const Color(0xFF070707).withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
                  child: isProcessing
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(processText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(value: processProgress, minHeight: 4, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ValueListenableBuilder<List<dynamic>>(
                                  valueListenable: favoriteWallpapers,
                                  builder: (context, favorites, _) {
                                    final isFav = favorites.any((w) => w['id'] == widget.wallpaper['id']);
                                    return IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                        child: Icon(isFav ? CupertinoIcons.heart_solid : CupertinoIcons.heart, key: ValueKey(isFav), color: isFav ? Theme.of(context).colorScheme.primary : Colors.white, size: 28),
                                      ),
                                      onPressed: _toggleFavorite,
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                // Download to Gallery Icon
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(CupertinoIcons.cloud_download, color: Colors.white, size: 28),
                                  onPressed: _downloadImage,
                                ),
                              ],
                            ),
                            // Apply Wallpaper Button
                            InkWell(
                              onTap: _showSetWallpaperModal,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
                                ),
                                child: const Row(
                                  children: [
                                    Icon(CupertinoIcons.paintbrush, color: Colors.black87, size: 18),
                                    SizedBox(width: 8),
                                    Text("Apply", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.15))),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
