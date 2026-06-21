import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../utils/utils.dart';

// ─── Status Badge ────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: StatusHelper.getColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StatusHelper.getColor(status), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StatusHelper.getIcon(status),
              size: fontSize + 2, color: StatusHelper.getColor(status)),
          const SizedBox(width: 4),
          Text(
            StatusHelper.getLabel(status),
            style: TextStyle(
              color: StatusHelper.getColor(status),
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase Progress Card ──────────────────────────────────────────────────────
class PhaseProgressCard extends StatelessWidget {
  final PhaseModel phase;
  final bool isCurrent;
  final VoidCallback? onTap;

  const PhaseProgressCard({
    super.key,
    required this.phase,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatusHelper.getColor(phase.status);
    return Card(
      elevation: isCurrent ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: phase.isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: phase.isLocked
                      ? Icon(Icons.lock, color: color, size: 20)
                      : Text(
                          '${phase.phaseNo}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phase ${phase.phaseNo}: ${phase.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phase.duration,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (phase.submittedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Submitted: ${DateFormatter.format(phase.submittedAt)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge(status: phase.status),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay(
      {super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Audit Trail Tile ─────────────────────────────────────────────────────────
class AuditTrailTile extends StatelessWidget {
  final AuditTrailModel audit;

  const AuditTrailTile({super.key, required this.audit});

  IconData _getIcon() {
    switch (audit.action) {
      case 'phase_submitted':
        return Icons.upload_file;
      case 'phase_resubmitted':
        return Icons.replay;
      case 'phase_approved':
        return Icons.check_circle;
      case 'changes_requested':
        return Icons.edit_note;
      case 'phase_unlocked':
        return Icons.lock_open;
      case 'project_created':
        return Icons.create_new_folder;
      case 'comment_added':
        return Icons.comment;
      default:
        return Icons.history;
    }
  }

  Color _getColor() {
    switch (audit.action) {
      case 'phase_approved':
      case 'phase_unlocked':
        return AppColors.approved;
      case 'changes_requested':
        return AppColors.changesRequested;
      case 'phase_submitted':
      case 'phase_resubmitted':
        return AppColors.submitted;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(audit.message,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.format(audit.timestamp),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comment Bubble ───────────────────────────────────────────────────────────
class CommentBubble extends StatelessWidget {
  final CommentModel comment;
  final bool isMe;

  const CommentBubble({super.key, required this.comment, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              '${comment.senderName} (${comment.senderRole})',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary.withValues(alpha: 0.9)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                comment.message,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormatter.format(comment.timestamp),
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Card ───────────────────────────────────────────────────────────────
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Notification Tile ───────────────────────────────────────────────────────
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile(
      {super.key, required this.notification, required this.onTap});

  IconData _getIcon() {
    switch (notification.type) {
      case 'phase_approved':
        return Icons.check_circle;
      case 'changes_requested':
        return Icons.edit_note;
      case 'phase_submitted':
      case 'phase_resubmitted':
        return Icons.upload_file;
      case 'phase_unlocked':
        return Icons.lock_open;
      case 'project_created':
        return Icons.create_new_folder;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'phase_approved':
      case 'phase_unlocked':
        return AppColors.approved;
      case 'changes_requested':
        return AppColors.changesRequested;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(_getIcon(), color: color, size: 20),
      ),
      title: Text(
        notification.message,
        style: TextStyle(
          fontWeight:
              notification.isRead ? FontWeight.normal : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        DateFormatter.format(notification.timestamp),
        style: const TextStyle(fontSize: 11),
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
      tileColor: notification.isRead ? null : AppColors.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

// ─── File Attachment Row ──────────────────────────────────────────────────────
class FileAttachmentRow extends StatelessWidget {
  final String? fileName;
  final String? fileUrl;
  final VoidCallback? onRemove;
  final bool showRemove;

  const FileAttachmentRow({
    super.key,
    this.fileName,
    this.fileUrl,
    this.onRemove,
    this.showRemove = false,
  });

  @override
  Widget build(BuildContext context) {
    if (fileName == null && fileUrl == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName ?? 'Attached file',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showRemove && onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onRemove,
              color: AppColors.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
