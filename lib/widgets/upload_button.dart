import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../theme/app_theme.dart';

class UploadButton extends StatelessWidget {
  const UploadButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _handleUpload(context),
      icon: const Icon(Icons.upload_file_rounded, size: 18),
      label: const Text('Upload New Recording'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.uploadButton,
        side: const BorderSide(color: AppColors.uploadButton, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _handleUpload(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && context.mounted) {
        final fileName = result.files.first.name;
        final filePath = result.files.first.path;
        await context.read<SleepProvider>().handleUpload(fileName, filePath: filePath);
      }
    } catch (_) {
      // File picker cancelled or error - generate demo data instead
      if (context.mounted) {
        await context.read<SleepProvider>().handleUpload('demo_recording.wav');
      }
    }
  }
}
