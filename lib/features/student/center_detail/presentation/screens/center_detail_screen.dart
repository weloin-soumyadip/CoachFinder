/// Center detail screen - gallery, info, reviews, and CTAs.
library;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Phase 1 placeholder. Receives `centerId` from the GoRouter path parameter.
class CenterDetailScreen extends HookConsumerWidget {
  const CenterDetailScreen({super.key, required this.centerId});

  final String centerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(child: Text('CenterDetailScreen (id: $centerId)')),
    );
  }
}
