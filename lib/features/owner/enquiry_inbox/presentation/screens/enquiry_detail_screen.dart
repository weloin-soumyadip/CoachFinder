/// Single enquiry detail — wired to `GET`/`PATCH /api/owners/enquiries/:id` via
/// [enquiryDetailControllerProvider]. Shows the student contact + message, a
/// status control (New/Contacted/Closed), and a private owner-notes editor.
/// There is no reply/conversation on the backend.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../data/controllers/enquiry_provider.dart';
import '../../data/models/enquiry_model.dart';
import '../widgets/enquiry_tile_widget.dart' show enquiryAvatarColor;

/// Owner enquiry detail screen. Receives `enquiryId` from the route.
class EnquiryDetailScreen extends HookConsumerWidget {
  /// Creates the detail screen for [enquiryId].
  const EnquiryDetailScreen({super.key, required this.enquiryId});

  /// The enquiry `_id`.
  final String enquiryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final EnquiryDetailState state =
        ref.watch(enquiryDetailControllerProvider(enquiryId));
    final Enquiry? enquiry = state.enquiry;

    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.ownerEnquiryInbox);
      }
    }

    Widget body;
    if (enquiry == null && state.status == EnquiryDetailStatus.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (enquiry == null) {
      body = Center(
        child: Text(
          state.errorMessage ?? AppStrings.enquiryNotFound,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: palette.textMuted),
        ),
      );
    } else {
      body = _DetailContent(enquiryId: enquiryId);
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: goBack),
        title: Text(
          enquiry?.studentName ?? AppStrings.enquiriesTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
      ),
      body: body,
    );
  }
}

/// The loaded-enquiry content (seeds the notes field once from the enquiry).
class _DetailContent extends HookConsumerWidget {
  const _DetailContent({required this.enquiryId});

  final String enquiryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final EnquiryDetailState state =
        ref.watch(enquiryDetailControllerProvider(enquiryId));
    final EnquiryDetailController controller =
        ref.read(enquiryDetailControllerProvider(enquiryId).notifier);
    final Enquiry enquiry = state.enquiry!;
    final TextEditingController notesC =
        useTextEditingController(text: enquiry.ownerNotes ?? '');

    void snack(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> changeStatus(EnquiryStatus status) async {
      if (status == enquiry.status || state.saving) return;
      final bool ok = await controller.setStatus(status);
      if (!context.mounted) return;
      snack(ok
          ? AppStrings.enquiryStatusUpdatedSnack
          : (ref
                  .read(enquiryDetailControllerProvider(enquiryId))
                  .errorMessage ??
              AppStrings.enquiryUpdateError));
    }

    Future<void> saveNotes() async {
      final bool ok = await controller.saveNotes(notesC.text);
      if (!context.mounted) return;
      snack(ok
          ? AppStrings.enquiryNotesSavedSnack
          : (ref
                  .read(enquiryDetailControllerProvider(enquiryId))
                  .errorMessage ??
              AppStrings.enquiryUpdateError));
    }

    void stub() => snack(AppStrings.stubComingSoon);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sp16,
            AppSpacing.sp16,
            AppSpacing.sp16,
            floatingNavClearance(context),
          ),
          children: <Widget>[
            _ContactCard(enquiry: enquiry, onCall: stub, onEmail: stub),
            const SizedBox(height: AppSpacing.sp24),
            _SectionTitle(title: AppStrings.enquiryMessageLabel),
            const SizedBox(height: AppSpacing.sp12),
            _Card(
              child: Text(
                enquiry.message,
                style: textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp24),
            _SectionTitle(title: AppStrings.enquiryStatusLabel),
            const SizedBox(height: AppSpacing.sp12),
            _StatusControl(
              current: enquiry.status,
              enabled: !state.saving,
              onSelect: changeStatus,
            ),
            const SizedBox(height: AppSpacing.sp24),
            _SectionTitle(title: AppStrings.enquiryNotesLabel),
            const SizedBox(height: AppSpacing.sp12),
            TextField(
              controller: notesC,
              maxLines: 4,
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: AppStrings.enquiryNotesHint,
                hintStyle: TextStyle(color: palette.textMuted),
                filled: true,
                fillColor: palette.inputFill,
                contentPadding: const EdgeInsets.all(AppSpacing.sp16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sp12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp12),
            FilledButton(
              onPressed: state.saving ? null : saveNotes,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ownerAccent,
                foregroundColor: AppColors.neutralWhite,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sp12),
                ),
              ),
              child: state.saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.neutralWhite,
                      ),
                    )
                  : const Text(
                      AppStrings.enquiryNotesSave,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header card: avatar, subject chip, status chip, contact rows, Call/Email.
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
    final bool hasPhone = (enquiry.studentPhone ?? '').isNotEmpty;
    final bool hasEmail = (enquiry.studentEmail ?? '').isNotEmpty;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: enquiryAvatarColor(enquiry.id),
                child: Text(
                  enquiry.initial,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.neutralWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Expanded(
                child: (enquiry.subjectName ?? '').isEmpty
                    ? Text(
                        enquiry.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      )
                    : _SubjectChip(subject: enquiry.subjectName!),
              ),
              const SizedBox(width: AppSpacing.sp8),
              _StatusChip(status: enquiry.status),
            ],
          ),
          if (hasPhone) ...<Widget>[
            const SizedBox(height: AppSpacing.sp16),
            _ContactRow(
                icon: Icons.phone_outlined, value: enquiry.studentPhone!),
          ],
          if (hasEmail) ...<Widget>[
            const SizedBox(height: AppSpacing.sp8),
            _ContactRow(
                icon: Icons.email_outlined, value: enquiry.studentEmail!),
          ],
          if (hasPhone || hasEmail) ...<Widget>[
            const SizedBox(height: AppSpacing.sp16),
            Row(
              children: <Widget>[
                if (hasPhone)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text(AppStrings.enquiryContactCall),
                      style: _actionStyle,
                    ),
                  ),
                if (hasPhone && hasEmail)
                  const SizedBox(width: AppSpacing.sp12),
                if (hasEmail)
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

/// New / Contacted / Closed segmented control.
class _StatusControl extends StatelessWidget {
  const _StatusControl({
    required this.current,
    required this.enabled,
    required this.onSelect,
  });

  final EnquiryStatus current;
  final bool enabled;
  final ValueChanged<EnquiryStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final EnquiryStatus s in EnquiryStatus.values) ...<Widget>[
          if (s != EnquiryStatus.values.first)
            const SizedBox(width: AppSpacing.sp8),
          Expanded(
            child: _StatusOption(
              label: _statusLabel(s),
              selected: s == current,
              onTap: enabled ? () => onSelect(s) : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? AppColors.ownerAccent : palette.surface,
      borderRadius: BorderRadius.circular(AppSpacing.sp12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp12),
            border: Border.all(
              color: selected ? AppColors.ownerAccent : palette.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color:
                      selected ? AppColors.neutralWhite : palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

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

/// Accent-tinted pill naming the subject the enquiry is about.
class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.subject});

  final String subject;

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
            const Icon(Icons.menu_book_outlined,
                size: 14, color: AppColors.ownerAccent),
            const SizedBox(width: AppSpacing.sp4),
            Flexible(
              child: Text(
                subject,
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

/// Status pill — accent (new), info (contacted), success (closed).
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final EnquiryStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      EnquiryStatus.newEnquiry => (
          AppColors.ownerAccent,
          AppStrings.enquiryStatusNew
        ),
      EnquiryStatus.contacted => (
          AppColors.info,
          AppStrings.enquiryStatusContacted
        ),
      EnquiryStatus.closed => (
          AppColors.success,
          AppStrings.enquiryStatusClosed
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

/// Bold section title.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.palette.textPrimary,
          ),
    );
  }
}

/// Flat surface card.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: child,
    );
  }
}

/// Maps a status to its display label.
String _statusLabel(EnquiryStatus s) => switch (s) {
      EnquiryStatus.newEnquiry => AppStrings.enquiryStatusNew,
      EnquiryStatus.contacted => AppStrings.enquiryStatusContacted,
      EnquiryStatus.closed => AppStrings.enquiryStatusClosed,
    };
