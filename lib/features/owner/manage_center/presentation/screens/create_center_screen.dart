/// First-time center creation wizard.
library;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Phase 1 placeholder.
class CreateCenterScreen extends HookConsumerWidget {
  const CreateCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: Center(child: Text('CreateCenterScreen')));
  }
}
