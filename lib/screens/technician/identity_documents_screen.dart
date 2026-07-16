import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/colors.dart';

class IdentityDocumentsResult {
  const IdentityDocumentsResult({
    required this.hasCitizenshipFront,
    required this.hasCitizenshipBack,
    this.citizenshipFrontBytes,
    this.citizenshipFrontName,
    this.citizenshipBackBytes,
    this.citizenshipBackName,
    this.experienceCertificateBytes,
    this.experienceCertificateName,
  });

  final bool hasCitizenshipFront;
  final bool hasCitizenshipBack;
  final Uint8List? citizenshipFrontBytes;
  final String? citizenshipFrontName;
  final Uint8List? citizenshipBackBytes;
  final String? citizenshipBackName;
  final Uint8List? experienceCertificateBytes;
  final String? experienceCertificateName;
}

class IdentityDocumentsScreen extends StatefulWidget {
  const IdentityDocumentsScreen({
    super.key,
    this.hasExistingFront = false,
    this.hasExistingBack = false,
    this.existingExperienceCertificateUrl,
    this.citizenshipFrontBytes,
    this.citizenshipFrontName,
    this.citizenshipBackBytes,
    this.citizenshipBackName,
    this.experienceCertificateBytes,
    this.experienceCertificateName,
  });

  final bool hasExistingFront;
  final bool hasExistingBack;
  final String? existingExperienceCertificateUrl;
  final Uint8List? citizenshipFrontBytes;
  final String? citizenshipFrontName;
  final Uint8List? citizenshipBackBytes;
  final String? citizenshipBackName;
  final Uint8List? experienceCertificateBytes;
  final String? experienceCertificateName;

  @override
  State<IdentityDocumentsScreen> createState() =>
      _IdentityDocumentsScreenState();
}

class _IdentityDocumentsScreenState extends State<IdentityDocumentsScreen> {
  // Maximum allowed size for citizenship and certificate photos: 5 MB.
  // Large enough for high-resolution document scans, small enough to keep
  // uploads fast on mobile networks.
  static const _maxBytes = 5 * 1024 * 1024;
  final _picker = ImagePicker();
  _SelectedDocument? _front;
  _SelectedDocument? _back;
  _SelectedDocument? _certificate;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    if (widget.citizenshipFrontBytes?.isNotEmpty ?? false) {
      _front = _SelectedDocument(
        name: widget.citizenshipFrontName ?? 'citizenship-front.jpg',
        bytes: widget.citizenshipFrontBytes!,
      );
    }
    if (widget.citizenshipBackBytes?.isNotEmpty ?? false) {
      _back = _SelectedDocument(
        name: widget.citizenshipBackName ?? 'citizenship-back.jpg',
        bytes: widget.citizenshipBackBytes!,
      );
    }
    if (widget.experienceCertificateBytes?.isNotEmpty ?? false) {
      _certificate = _SelectedDocument(
        name: widget.experienceCertificateName ?? 'experience-certificate.jpg',
        bytes: widget.experienceCertificateBytes!,
      );
    }
  }

  bool get _hasFront => widget.hasExistingFront || _front != null;
  bool get _hasBack => widget.hasExistingBack || _back != null;

  Future<void> _pick(_DocumentType type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a clear photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final file = source == ImageSource.gallery
          ? await _picker.pickMedia(imageQuality: 90)
          : await _picker.pickImage(source: source, imageQuality: 90);
      if (!mounted || file == null) return;
      final extension = file.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png'}.contains(extension)) {
        _showMessage('Please choose a JPG or PNG image.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        _showMessage('The selected image is empty. Please choose another.');
        return;
      }
      if (bytes.length > _maxBytes) {
        _showMessage('The image must be smaller than 5 MB.');
        return;
      }
      final document = _SelectedDocument(name: file.name, bytes: bytes);
      setState(() {
        switch (type) {
          case _DocumentType.front:
            _front = document;
          case _DocumentType.back:
            _back = document;
          case _DocumentType.certificate:
            _certificate = document;
        }
        _showErrors = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code.contains('access_denied')
            ? 'Photo access was denied. Enable it in device settings.'
            : 'Unable to select the document (${error.code}).',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to select this document. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!_hasFront || !_hasBack) {
      setState(() => _showErrors = true);
      return;
    }
    // BACKEND TODO: Upload the image bytes securely with multipart requests,
    // then let the backend/manual verification process confirm that the images
    // are genuine, readable Nepali citizenship documents. Local file checks
    // are not proof of identity and must never set status to verified.
    Navigator.pop(
      context,
      IdentityDocumentsResult(
        hasCitizenshipFront: _hasFront,
        hasCitizenshipBack: _hasBack,
        citizenshipFrontBytes: _front?.bytes,
        citizenshipFrontName: _front?.name,
        citizenshipBackBytes: _back?.bytes,
        citizenshipBackName: _back?.name,
        experienceCertificateBytes: _certificate?.bytes,
        experienceCertificateName: _certificate?.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Identity Documents')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload clear front and back images of your Nepali citizenship. Both sides are required before accepting jobs. Documents remain pending until verified.',
                        style: TextStyle(color: AppColors.black, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DocumentCard(
                title: 'Nepali Citizenship – Front',
                requiredDocument: true,
                document: _front,
                hasExistingFile: widget.hasExistingFront,
                error: _showErrors && !_hasFront
                    ? 'Citizenship front image is required.'
                    : null,
                onPick: () => _pick(_DocumentType.front),
                onRemove: _front == null
                    ? null
                    : () => setState(() => _front = null),
              ),
              _DocumentCard(
                title: 'Nepali Citizenship – Back',
                requiredDocument: true,
                document: _back,
                hasExistingFile: widget.hasExistingBack,
                error: _showErrors && !_hasBack
                    ? 'Citizenship back image is required.'
                    : null,
                onPick: () => _pick(_DocumentType.back),
                onRemove: _back == null
                    ? null
                    : () => setState(() => _back = null),
              ),
              _DocumentCard(
                title: 'Experience Certificate (Optional)',
                requiredDocument: false,
                document: _certificate,
                hasExistingFile:
                    widget.existingExperienceCertificateUrl?.isNotEmpty ??
                    false,
                onPick: () => _pick(_DocumentType.certificate),
                onRemove: _certificate == null
                    ? null
                    : () => setState(() => _certificate = null),
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Submit Documents'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DocumentType { front, back, certificate }

class _SelectedDocument {
  const _SelectedDocument({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.title,
    required this.requiredDocument,
    required this.document,
    required this.hasExistingFile,
    required this.onPick,
    this.onRemove,
    this.error,
  });

  final String title;
  final bool requiredDocument;
  final _SelectedDocument? document;
  final bool hasExistingFile;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final selected = document != null || hasExistingFile;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEAF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                requiredDocument ? 'Required' : 'Optional',
                style: TextStyle(
                  color: requiredDocument ? AppColors.red : AppColors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (document != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _viewDocument(context),
                child: Image.memory(
                  document!.bytes,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              document!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ] else if (hasExistingFile) ...[
            const SizedBox(height: 10),
            const Text(
              'Document uploaded • Verification status from backend',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_outlined),
                label: Text(selected ? 'Replace' : 'Choose Image'),
              ),
              if (document != null)
                TextButton.icon(
                  onPressed: () => _viewDocument(context),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
              if (onRemove != null)
                TextButton(onPressed: onRemove, child: const Text('Remove')),
            ],
          ),
          if (document != null)
            const Text(
              'Selected locally • Pending secure upload and verification',
              style: TextStyle(color: AppColors.primary, fontSize: 11),
            ),
        ],
      ),
    );
  }

  void _viewDocument(BuildContext context) {
    if (document == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.memory(document!.bytes, fit: BoxFit.contain),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
