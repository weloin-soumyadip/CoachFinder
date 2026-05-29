/// Single enquiry conversation view: contact header, message thread, status
/// actions, and a reply box.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../data/controllers/enquiry_provider.dart';
import '../../data/mock_enquiry_data.dart';
import '../widgets/reply_input_widget.dart';

/// Owner enquiry detail / conversation screen. Receives `enquiryId` from the
/// GoRouter path parameter and reads the matching [Enquiry] from
/// [enquiriesProvider], so replies and archive actions update the shared state
/// (and the inbox) live. Renders within the owner shell; its app-bar back
/// button pops if possible, else falls back to the inbox.
class EnquiryDetailScreen extends HookConsumerWidget {
  const EnquiryDetailScreen({super.key, required this.enquiryId});

  final String enquiryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Enquiry> enquiries = ref.watch(enquiriesProvider);
    final EnquiryNotifier notifier = ref.read(enquiriesProvider.notifier);
    final palette = context.palette;

    final Iterable<Enquiry> matches =
        enquiries.where((Enquiry e) => e.id == enquiryId);
    final Enquiry? enquiry = matches.isEmpty ? null : matches.first;

    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.ownerEnquiryInbox);
      }
    }

    if (enquiry == null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          leading: BackButton(onPressed: goBack),
          backgroundColor: palette.surface,
        ),
        body: Center(
          child: Text(
            AppStrings.enquiryNotFound,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: palette.textMuted),
          ),
        ),
      );
    }

    void stub() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.stubComingSoon)),
        );
    }

    final bool isArchived = enquiry.status == EnquiryStatus.archived;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: goBack),
        title: Text(
          enquiry.studentName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: isArchived
                ? AppStrings.enquiryActionUnarchive
                : AppStrings.enquiryActionArchive,
            icon: Icon(
              isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: palette.textSecondary,
            ),
            onPressed: () => isArchived
                ? notifier.unarchive(enquiry.id)
                : notifier.archive(enquiry.id),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sp16,
                    AppSpacing.sp16,
                    AppSpacing.sp16,
                    AppSpacing.sp24,
                  ),
                  children: <Widget>[
                    _ContactCard(
                      enquiry: enquiry,
                      onCall: stub,
                      onEmail: stub,
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    Text(
                      AppStrings.enquiryConversationLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sp12),
                    for (final EnquiryMessage m in enquiry.thread) ...<Widget>[
                      _MessageBubble(message: m),
                      const SizedBox(height: AppSpacing.sp12),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: floatingNavClearance(context),
                ),
                child: ReplyInputWidget(
                  onSend: (String text) => notifier.addReply(enquiry.id, text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header card: avatar, course tag, status chip, contact rows, and Call/Email
/// action buttons.
class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.enquiry,
    required this.onCall,
    required this.onEmail,
  });

  final Enquiry enquiry;
  final VoidCallback onCall;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: enquiry.avatarColor,
                child: Text(
                  enquiry.initial,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.neutralWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(child: _CourseChip(course: enquiry.course)),
              const SizedBox(width: AppSpacing.sp8),
              _StatusChip(status: enquiry.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sp16),
          _ContactRow(icon: Icons.phone_outlined, value: enquiry.phone),
          const SizedBox(height: AppSpacing.sp8),
          _ContactRow(icon: Icons.email_outlined, value: enquiry.email),
          const SizedBox(height: AppSpacing.sp16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text(AppStrings.enquiryContactCall),
                  style: _actionStyle,
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEmail,
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text(AppStrings.enquiryContactEmail),
                  style: _actionStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final ButtonStyle _actionStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.ownerAccent,
    side: const BorderSide(color: AppColors.ownerAccent),
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSpacing.sp12)),
    ),
  );
}

/// Labelled icon + value row used for phone and email.
class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: palette.textMuted),
        const SizedBox(width: AppSpacing.sp8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Accent-tinted pill naming the course/subject the enquiry is about.
class _CourseChip extends StatelessWidget {
  const _CourseChip({required this.course});

  final String course;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp8,
          vertical: AppSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: AppColors.ownerAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.sp8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.menu_book_outlined,
              size: 14,
              color: AppColors.ownerAccent,
            ),
            const SizedBox(width: AppSpacing.sp4),
            Flexible(
              child: Text(
                course,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.ownerAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status pill - accent for new, green for replied, muted for archived.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final EnquiryStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (Color color, String label) = switch (status) {
      EnquiryStatus.newEnquiry => (
          AppColors.ownerAccent,
          AppStrings.enquiryStatusNew,
        ),
      EnquiryStatus.replied => (
          AppColors.success,
          AppStrings.enquiryStatusReplied,
        ),
      EnquiryStatus.archived => (
          palette.textMuted,
          AppStrings.enquiryStatusArchived,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp8,
        vertical: AppSpacing.sp4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.sp8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// A single chat bubble: student messages sit left on a surface bubble, owner
/// replies sit right on an accent bubble, each with a timestamp beneath.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final EnquiryMessage message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final bool owner = message.fromOwner;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          mainAxisAlignment:
              owner ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: constraints.maxWidth * 0.78),
              child: Column(
                crossAxisAlignment:
                    owner ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp12,
                      vertical: AppSpacing.sp12,
                    ),
                    decoration: BoxDecoration(
                      color: owner ? AppColors.ownerAccent : palette.surface,
                      border: owner
                          ? null
                          : Border.all(color: palette.borderSubtle),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppSpacing.sp16),
                        topRight: const Radius.circular(AppSpacing.sp16),
                        bottomLeft: Radius.circular(
                          owner ? AppSpacing.sp16 : AppSpacing.sp4,
                        ),
                        bottomRight: Radius.circular(
                          owner ? AppSpacing.sp4 : AppSpacing.sp16,
                        ),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: owner
                            ? AppColors.neutralWhite
                            : palette.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp4),
                  Text(
                    message.timeLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
