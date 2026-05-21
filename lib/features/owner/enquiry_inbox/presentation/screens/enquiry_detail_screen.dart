/// Single enquiry conversation view with reply box.
library;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Phase 1 placeholder. Receives `enquiryId` from the GoRouter path parameter.
class EnquiryDetailScreen extends HookConsumerWidget {
  const EnquiryDetailScreen({super.key, required this.enquiryId});

  final String enquiryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(child: Text('EnquiryDetailScreen (id: $enquiryId)')),
    );
  }
}
