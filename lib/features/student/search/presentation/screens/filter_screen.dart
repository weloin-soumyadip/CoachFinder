/// Full-screen filter editor - subjects, distance, rating, board.
library;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Phase 1 placeholder.
class FilterScreen extends HookConsumerWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: Center(child: Text('FilterScreen')));
  }
}
