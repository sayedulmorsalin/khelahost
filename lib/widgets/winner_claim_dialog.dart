import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/winner_claim.dart';
import 'package:khelahost/services/image_upload_service.dart';
import 'package:khelahost/services/room_service.dart';
import 'package:khelahost/widgets/claim_window_timer.dart';

class WinnerClaimDialog extends StatefulWidget {
  final String roomId;
  final String playerUid;
  final String playerName;
  final WinnerClaim? existingClaim;
  final DateTime? claimDeadline;

  const WinnerClaimDialog({
    super.key,
    required this.roomId,
    required this.playerUid,
    required this.playerName,
    this.existingClaim,
    this.claimDeadline,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String roomId,
    required String playerUid,
    required String playerName,
    WinnerClaim? existingClaim,
    DateTime? claimDeadline,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WinnerClaimDialog(
        roomId: roomId,
        playerUid: playerUid,
        playerName: playerName,
        existingClaim: existingClaim,
        claimDeadline: claimDeadline,
      ),
    );
  }

  @override
  State<WinnerClaimDialog> createState() => _WinnerClaimDialogState();
}

class _WinnerClaimDialogState extends State<WinnerClaimDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  final _service = RoomService();

  final List<String> _paymentMethods = [
    'bKash',
    'Nagad',
    'Rocket',
    'Upay',
    'Bank',
    'Other',
  ];

  late String _selectedMethod;
  XFile? _pickedFile;
  Uint8List? _previewBytes;
  bool _isUploading = false;
  String _uploadStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.existingClaim?.paymentMethod ?? 'bKash';
    _phoneController.text = widget.existingClaim?.phoneNumber ?? '';
    _noteController.text = widget.existingClaim?.note ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedFile = picked;
          _previewBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.claimDeadline != null &&
        DateTime.now().isAfter(widget.claimDeadline!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'The 3-hour submission window has expired. Submissions are now closed.'),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_pickedFile == null &&
        (widget.existingClaim?.screenshotUrl == null ||
            widget.existingClaim!.screenshotUrl.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a winner victory screenshot proof.'),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatusMessage = 'Uploading screenshot to free image host...';
    });

    try {
      String finalScreenshotUrl = widget.existingClaim?.screenshotUrl ?? '';

      if (_pickedFile != null) {
        finalScreenshotUrl = await ImageUploadService.uploadXFile(_pickedFile!);
      }

      if (mounted) {
        setState(() {
          _uploadStatusMessage = 'Saving winner claim...';
        });
      }

      final claim = WinnerClaim(
        id: widget.playerUid,
        roomId: widget.roomId,
        playerUid: widget.playerUid,
        playerName: widget.playerName,
        phoneNumber: _phoneController.text.trim(),
        paymentMethod: _selectedMethod,
        screenshotUrl: finalScreenshotUrl,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        status: 'pending',
        submittedAt: DateTime.now(),
      );

      await _service.submitWinnerClaim(widget.roomId, claim);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Winner proof & payment info submitted! Host notified.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading proof: $e'),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppTheme.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingClaim == null
                              ? 'Submit Winner Proof'
                              : 'Update Winner Proof',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Upload victory screenshot & phone number to receive payment',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (widget.claimDeadline != null) ...[
                          const SizedBox(height: 6),
                          ClaimWindowTimer(
                            deadline: widget.claimDeadline!,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Screenshot upload card
              Text(
                'VICTORY SCREENSHOT PROOF *',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              _buildScreenshotPicker(),

              const SizedBox(height: 18),

              // Phone number
              Text(
                'PHONE NUMBER WHERE TO PAY *',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. 017XXXXXXXX',
                  prefixIcon: const Icon(
                    Icons.phone_android_rounded,
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
                  helperText: 'Host will send the tournament prize to this number',
                  helperStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your payment phone number';
                  }
                  if (val.trim().length < 6) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Payment Method Chips
              Text(
                'PAYMENT METHOD / WALLET',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paymentMethods.map((method) {
                  final isSelected = _selectedMethod == method;
                  return ChoiceChip(
                    label: Text(method),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMethod = method);
                      }
                    },
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.bgSurface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Note / Tag (Optional)
              Text(
                'IN-GAME TAG OR EXTRA NOTE (OPTIONAL)',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g. In-game name: KingBooyah, Rank #1 (12 kills)',
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              if (_isUploading) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _uploadStatusMessage,
                        style: GoogleFonts.inter(
                          color: AppTheme.goldLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          side: const BorderSide(color: AppTheme.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          widget.existingClaim == null
                              ? 'Submit & Claim Prize'
                              : 'Update Claim',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenshotPicker() {
    final hasNewFile = _previewBytes != null;
    final hasExistingUrl = widget.existingClaim?.screenshotUrl != null &&
        widget.existingClaim!.screenshotUrl.isNotEmpty;

    if (hasNewFile || hasExistingUrl) {
      return Container(
        decoration: AppTheme.glassCard(borderRadius: 14),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasNewFile
                        ? Image.memory(
                            _previewBytes!,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            widget.existingClaim!.screenshotUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppTheme.bgSurface,
                              child: const Center(
                                child: Icon(Icons.broken_image_rounded,
                                    color: AppTheme.textMuted),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.accentGreen, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            hasNewFile ? 'Ready to upload' : 'Saved screenshot',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: const Text('Change Screenshot'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cardBorder,
          style: BorderStyle.solid,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: AppTheme.primaryLight,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select Winner Victory Screenshot',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a screenshot of the victory / Booyah screen and upload it',
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 16),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.bgCard,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.bgCard,
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

