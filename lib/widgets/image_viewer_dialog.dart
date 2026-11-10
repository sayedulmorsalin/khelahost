import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/theme.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageViewerDialog({
    super.key,
    required this.imageUrl,
    this.title = 'Winner Screenshot Proof',
  });

  static void show(BuildContext context, String imageUrl, {String title = 'Winner Screenshot Proof'}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => ImageViewerDialog(imageUrl: imageUrl, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy Link',
                  icon: const Icon(Icons.link_rounded, color: AppTheme.textSecondary, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: imageUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Screenshot URL copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_rounded, color: AppTheme.textSecondary, size: 18),
                  onPressed: () {
                    Share.share('Winner Proof Screenshot: $imageUrl');
                  },
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Zoomable image
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      final total = progress.expectedTotalBytes;
                      final loaded = progress.cumulativeBytesLoaded;
                      final ratio = total != null && total > 0 ? loaded / total : null;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: ratio,
                                color: AppTheme.primary,
                                strokeWidth: 2.5,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Loading high-res proof...',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image_rounded, color: AppTheme.accentRed, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Could not load screenshot preview',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                imageUrl,
                                style: GoogleFonts.inter(
                                  color: AppTheme.primaryLight,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

