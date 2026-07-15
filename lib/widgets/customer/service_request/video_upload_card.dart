import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class VideoUploadCard extends StatelessWidget {
  const VideoUploadCard({
    required this.fileName,
    required this.duration,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final String? fileName;
  final Duration? duration;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  String get _durationLabel {
    final seconds = duration?.inSeconds ?? 0;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final selected = fileName != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2DEEB)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.lightPurple,
                child: Icon(Icons.videocam_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected ? fileName! : 'Tap to record or upload',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selected
                          ? '$_durationLabel  ·  Tap to replace'
                          : 'Helps service professionals assess the issue better',
                      maxLines: 2,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Remove video',
                  icon: const Icon(Icons.close, color: AppColors.grey),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
