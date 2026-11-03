import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// Processing screen (Figma B12) - progress while the AI reads the notes.
///
/// Route: `/learn/upload/job/:jobId` (full screen)
///
// TODO(samni): build the real UI from Figma (upload/summarisation branch).
class UploadJobScreen extends StatelessWidget {
  const UploadJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: FeaturePlaceholder(
        title: 'Processing',
        owner: 'Samni',
        description: 'Reading and summarising your notes. (jobId: $jobId)',
      ),
    );
  }
}
