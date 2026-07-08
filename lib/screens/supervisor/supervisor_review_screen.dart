/// ------------------------------------------------------------------
/// File: supervisor_review_screen.dart
/// Role: User Interface (View)
///
/// Description:
/// Renders the visual elements of the application. Listens to Providers for state changes to display data dynamically. Contains purely presentation logic without direct database manipulation.
///
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';
import '../../utils/utils.dart';
import '../shared/comment_thread_screen.dart';
import '../student/project_history_screen.dart';
import 'custom_phases_management_screen.dart';

/// ------------------------------------------------------------------
/// SupervisorReviewScreen (Evaluation Workspace)
/// ------------------------------------------------------------------
/// This screen acts as the Supervisor's control center for a specific student's project.
///
/// Functionality features:
/// 1. Unified Timeline View: Displays all 5 phases in a scrollable list, highlighting
///    the current active phase and providing historical context of past phases.
/// 2. Evaluation Mechanics: Supervisors can accept or reject a phase.
///    - Approving triggers the `ProjectProvider` to unlock the next phase.
///    - Requesting changes requires a mandatory comment explaining the rejection.
/// 3. Resource Fetching: Securely downloads and opens files (Cloudinary URLs) via the OS browser.
/// 4. Direct Communication: Embeds a comment thread specific to each phase, keeping
///    all project discussions tightly coupled to their relevant deliverables.
/// ------------------------------------------------------------------
class SupervisorReviewScreen extends StatefulWidget {
  final ProjectModel project;
  final UserModel? student;

  const SupervisorReviewScreen(
      {super.key, required this.project, this.student});

  @override
  State<SupervisorReviewScreen> createState() => _SupervisorReviewScreenState();
}

class _SupervisorReviewScreenState extends State<SupervisorReviewScreen> {
  final PhaseRepository _phaseRepo = PhaseRepository();
  final AuditTrailRepository _auditRepo = AuditTrailRepository();
  final NotificationRepository _notifRepo = NotificationRepository();
  final ProjectRepository _projectRepo = ProjectRepository();
  bool _loading = false;
  String? _error;

  /// -----------------------------------------
  /// Method: _approvePhase
  /// Purpose: Executes logic for _approvePhase and handles state or UI updates.
  /// -----------------------------------------
  Future<void> _approvePhase(PhaseModel phase, int totalPhases) async {
    final supervisor = context.read<AuthProvider>().currentUser;
    if (supervisor == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Mark phase as approved
      await _phaseRepo.approvePhase(
        phaseId: phase.id,
        reviewedBy: supervisor.id,
      );

      // 2. Audit entry
      await _auditRepo.addAuditEntry(
        projectId: widget.project.id,
        phaseNo: phase.phaseNo,
        action: 'phase_approved',
        performedBy: supervisor.id,
        role: 'supervisor',
        message: '${supervisor.name} approved Phase ${phase.phaseNo}',
      );

      // 3. Notify student
      await _notifRepo.sendNotification(
        userId: widget.project.studentId,
        message: 'Phase ${phase.phaseNo} approved by ${supervisor.name}',
        type: 'phase_approved',
        projectId: widget.project.id,
        phaseNo: phase.phaseNo,
      );

      // 4. Unlock next phase OR mark project complete
      if (phase.phaseNo < totalPhases) {
        await _phaseRepo.unlockNextPhase(
          projectId: widget.project.id,
          nextPhaseNo: phase.phaseNo + 1,
        );
        await _projectRepo.updateProject(
          widget.project.id,
          {'currentPhase': phase.phaseNo + 1},
        );
        await _auditRepo.addAuditEntry(
          projectId: widget.project.id,
          phaseNo: phase.phaseNo + 1,
          action: 'phase_unlocked',
          performedBy: supervisor.id,
          role: 'supervisor',
          message: 'Phase ${phase.phaseNo + 1} unlocked by ${supervisor.name}',
        );
        await _notifRepo.sendNotification(
          userId: widget.project.studentId,
          message: 'Phase ${phase.phaseNo + 1} is now unlocked!',
          type: 'phase_unlocked',
          projectId: widget.project.id,
          phaseNo: phase.phaseNo + 1,
        );
      } else {
        await _projectRepo.updateProject(
          widget.project.id,
          {'status': 'completed'},
        );
        await _notifRepo.sendNotification(
          userId: widget.project.studentId,
          message:
              'Congratulations! Your FYP project has been completed successfully.',
          type: 'project_completed',
          projectId: widget.project.id,
          phaseNo: phase.phaseNo,
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phase.phaseNo < totalPhases
              ? 'Phase ${phase.phaseNo} approved! Phase ${phase.phaseNo + 1} unlocked.'
              : 'Final phase approved! Project completed!'),
          backgroundColor: AppColors.approved,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Approval failed. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approval failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// -----------------------------------------
  /// Method: _requestChanges
  /// Purpose: Executes logic for _requestChanges and handles state or UI updates.
  /// -----------------------------------------
  Future<void> _requestChanges(PhaseModel phase) async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.changesRequested),
            SizedBox(width: 8),
            Text('Request Changes'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Phase ${phase.phaseNo}: ${phase.title}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Reason for changes *',
                  hintText: 'Explain what needs to be improved or corrected...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  if (v.trim().length < 10) {
                    return 'Please be more specific (min 10 chars)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.changesRequested),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Feedback'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, reasonCtrl.text.trim());
              }
            },
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    if (!mounted) return;
    final supervisor = context.read<AuthProvider>().currentUser;
    if (supervisor == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _phaseRepo.requestChanges(
        phaseId: phase.id,
        reason: result,
        reviewedBy: supervisor.id,
      );
      await _auditRepo.addAuditEntry(
        projectId: widget.project.id,
        phaseNo: phase.phaseNo,
        action: 'changes_requested',
        performedBy: supervisor.id,
        role: 'supervisor',
        message:
            '${supervisor.name} requested changes on Phase ${phase.phaseNo}: $result',
      );
      await _notifRepo.sendNotification(
        userId: widget.project.studentId,
        message:
            'Changes requested for Phase ${phase.phaseNo} by ${supervisor.name}',
        type: 'changes_requested',
        projectId: widget.project.id,
        phaseNo: phase.phaseNo,
      );

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Change request sent to student.'),
          backgroundColor: AppColors.changesRequested,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send request. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// -----------------------------------------
  /// Method: _openFile
  /// Purpose: Executes logic for _openFile and handles state or UI updates.
  /// -----------------------------------------
  Future<void> _openFile(String url) async {
    try {
      String finalUrl = url.trim();
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }

      if (finalUrl.contains('cloudinary.com') &&
          finalUrl.toLowerCase().endsWith('.pdf') &&
          finalUrl.contains('/upload/')) {
        final String pdfUrl =
            finalUrl.replaceFirst('/upload/', '/upload/fl_attachment/');
        final Uri pdfUri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(pdfUri)) {
          final success =
              await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
          if (success) return;
        }
      }

      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback if canLaunchUrl fails but it might still be launchable
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open file.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project.title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.student != null)
                Text(
                  widget.student!.name,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
            ],
          ),
          actions: [
            if (widget.project.phaseType == 'customized')
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Manage Custom Phases',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomPhasesManagementScreen(project: widget.project),
                  ),
                ).then((_) {
                  // Ensure UI updates if needed
                  setState(() {});
                }),
              ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: 'Full Project History',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProjectHistoryScreen(projectId: widget.project.id),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Error banner
            if (_error != null)
              Container(
                width: double.infinity,
                color: AppColors.error.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error))),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: AppColors.error),
                      onPressed: () => setState(() => _error = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<List<PhaseModel>>(
                stream: _phaseRepo.getPhasesByProjectId(widget.project.id),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error loading phases: ${snap.error}'),
                    );
                  }
                  final phases = snap.data ?? [];
                  if (phases.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EmptyState(
                          icon: Icons.layers,
                          title: 'No phases found',
                          subtitle: widget.project.phaseType == 'customized'
                              ? 'No phases have been created for this project yet.'
                              : null,
                        ),
                        if (widget.project.phaseType == 'customized') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomPhasesManagementScreen(
                                    project: widget.project),
                              ),
                            ).then((_) {
                              setState(() {});
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Phases'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student info card
                        if (widget.student != null) ...[
                          _StudentInfoCard(
                            student: widget.student!,
                            project: widget.project,
                            phases: phases,
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SectionHeader(title: 'Phase Reviews'),
                        ...phases.map(
                          (phase) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PhaseReviewCard(
                              phase: phase,
                              project: widget.project,
                              onApprove: () =>
                                  _approvePhase(phase, phases.length),
                              onRequestChanges: () => _requestChanges(phase),
                              onOpenFile: _openFile,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  final UserModel student;
  final ProjectModel project;
  final List<PhaseModel> phases;

  const _StudentInfoCard({
    required this.student,
    required this.project,
    required this.phases,
  });

  @override
  Widget build(BuildContext context) {
    final approvedCount = phases.where((p) => p.isApproved).length;
    final submittedCount = phases.where((p) => p.isSubmitted).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text(student.email,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                        label: 'Current Phase',
                        value: '${project.currentPhase}/${phases.length}',
                        color: const Color(0xFF3B82F6))),
                Container(width: 1, height: 40, color: AppColors.divider),
                Expanded(
                    child: _MiniStat(
                        label: 'Approved',
                        value: '$approvedCount',
                        color: const Color(0xFF10B981))),
                Container(width: 1, height: 40, color: AppColors.divider),
                Expanded(
                    child: _MiniStat(
                        label: 'Pending Review',
                        value: '$submittedCount',
                        color: const Color(0xFFF59E0B))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── Phase Review Card ────────────────────────────────────────────────────────
class _PhaseReviewCard extends StatefulWidget {
  final PhaseModel phase;
  final ProjectModel project;
  final VoidCallback onApprove;
  final VoidCallback onRequestChanges;
  final void Function(String url) onOpenFile;

  const _PhaseReviewCard({
    required this.phase,
    required this.project,
    required this.onApprove,
    required this.onRequestChanges,
    required this.onOpenFile,
  });

  @override
  State<_PhaseReviewCard> createState() => _PhaseReviewCardState();
}

class _PhaseReviewCardState extends State<_PhaseReviewCard> {
  bool _expanded = false;
  late Stream<List<AuditTrailModel>> _auditStream;

  @override
  void initState() {
    super.initState();
    // Auto-expand submitted phases
    _expanded = !widget.phase.isLocked &&
        (widget.phase.isSubmitted || widget.phase.isChangesRequested);
    _auditStream = AuditTrailRepository()
        .getAuditTrailByPhase(widget.project.id, widget.phase.phaseNo);
  }

  @override
  void didUpdateWidget(_PhaseReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phase.isLocked) {
      _expanded = false;
    }
  }

  Widget _buildTimelineRow(IconData icon, String label, String value, {Color? iconColor}) {
    final color = iconColor ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final isCustomized = widget.project.phaseType == 'customized';
    final isActionable = phase.isSubmitted;
    final isEffectivelyLocked = phase.isLocked;
    final borderColor = phase.isSubmitted
        ? AppColors.submitted
        : phase.isApproved
            ? AppColors.approved
            : phase.isChangesRequested
                ? AppColors.changesRequested
                : AppColors.divider;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isActionable ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: isEffectivelyLocked
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF), // soft blue
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isEffectivelyLocked
                          ? const Icon(Icons.lock,
                              size: 16,
                              color: Color(0xFF3B82F6))
                          : Text(
                              '${phase.phaseNo}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B82F6),
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
                          phase.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        if (phase.submittedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Submitted: ${DateFormatter.format(phase.submittedAt)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: StatusHelper.getColor(phase.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      StatusHelper.getLabel(phase.status),
                      style: TextStyle(
                        color: StatusHelper.getColor(phase.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isEffectivelyLocked) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expandable content
          if (_expanded && !phase.isLocked) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamps row
                  if (phase.submittedAt != null)
                    _buildTimelineRow(Icons.arrow_upward, 'Submitted', DateFormatter.format(phase.submittedAt!), iconColor: AppColors.primary),
                  if (phase.approvedAt != null)
                    _buildTimelineRow(Icons.check_circle_outline, 'Approved', DateFormatter.format(phase.approvedAt!), iconColor: const Color(0xFF10B981)),
                  if (phase.changesRequestedAt != null)
                    _buildTimelineRow(Icons.warning_amber_rounded, 'Changes Requested', DateFormatter.format(phase.changesRequestedAt!), iconColor: const Color(0xFFF59E0B)),
                  if (phase.resubmittedAt != null)
                    _buildTimelineRow(Icons.replay, 'Resubmitted', DateFormatter.format(phase.resubmittedAt!), iconColor: const Color(0xFF3B82F6)),
                  if (phase.reviewDuration != null)
                    _buildTimelineRow(Icons.timer_outlined, 'Review Time', DateFormatter.formatDuration(phase.reviewDuration!), iconColor: const Color(0xFF3B82F6)),

                  const SizedBox(height: 8),

                  // Submission notes
                  if (phase.submissionText != null &&
                      phase.submissionText!.isNotEmpty) ...[
                    Text(
                      phase.phaseNo == 4
                          ? 'Development Summary'
                          : 'Submission Notes',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        phase.submissionText!,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.primary),
                      ),
                    ),
                  ],

                  // Attached file
                  if (phase.fileUrl != null || phase.fileName != null) ...[
                    const SizedBox(height: 16),
                    if (phase.fileUrl != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                phase.fileName ?? 'Submitted file',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => widget.onOpenFile(phase.fileUrl!),
                              icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                              label: const Text('Open', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 20, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${phase.fileName} (File not uploaded yet)',
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  // GitHub Link
                  if (phase.githubUrl != null &&
                      phase.githubUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('GitHub Repository',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => widget.onOpenFile(phase.githubUrl!),
                      child: Text(phase.githubUrl!,
                          style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              decoration: TextDecoration.underline)),
                    ),
                  ],

                  // Screenshots
                  if (phase.screenshots != null &&
                      phase.screenshots!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Screenshots',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: phase.screenshots!.map((url) {
                        return InkWell(
                          onTap: () => widget.onOpenFile(url),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image,
                                      color: Colors.grey)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Phase 5 Deliverables
                  if (phase.demoVideoUrl != null &&
                      phase.demoVideoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Demo Video Link',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => widget.onOpenFile(phase.demoVideoUrl!),
                      child: Text(phase.demoVideoUrl!,
                          style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                  if (phase.finalProjectLink != null &&
                      phase.finalProjectLink!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Final Project Link',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => widget.onOpenFile(phase.finalProjectLink!),
                      child: Text(phase.finalProjectLink!,
                          style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                  if (phase.presentationUrl != null || phase.presentationName != null) ...[
                    const SizedBox(height: 16),
                    if (phase.presentationUrl != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.slideshow, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                phase.presentationName ?? 'Presentation',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => widget.onOpenFile(phase.presentationUrl!),
                              icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                              label: const Text('Open', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 20, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${phase.presentationName} (File not uploaded yet)',
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (phase.testCasesUrl != null || phase.testCasesName != null) ...[
                    const SizedBox(height: 16),
                    if (phase.testCasesUrl != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_turned_in, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                phase.testCasesName ?? 'Test Cases',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => widget.onOpenFile(phase.testCasesUrl!),
                              icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                              label: const Text('Open', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 20, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${phase.testCasesName} (File not uploaded yet)',
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  // Previous change request reason
                  if (phase.changeRequestReason != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2), // Subtle red
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              phase.changeRequestReason!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFEF4444),
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Action buttons (only if submitted)
                  if (isActionable)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onRequestChanges,
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text('Request Changes'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.changesRequested,
                              side: const BorderSide(
                                  color: AppColors.changesRequested),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirm Approval'),
                                  content: const Text(
                                    'Are you sure you want to approve this phase?\n\nPlease confirm before proceeding.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        widget.onApprove();
                                      },
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.approved,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Comments button — always show for non-locked phases
                  if (!phase.isLocked && _expanded) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentThreadScreen(
                              projectId: widget.project.id,
                              phaseNo: phase.phaseNo,
                              phaseTitle: phase.title,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('View / Add Comments'),
                      ),
                    ),

                    // Audit trail for this phase
                    const SizedBox(height: 12),
                    const Text(
                      'Activity',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<AuditTrailModel>>(
                      stream: _auditStream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final audits = snap.data ?? [];
                        if (audits.isEmpty) {
                          return const Text(
                            'No activity yet.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          );
                        }
                        return Column(
                          children: audits
                              .take(5)
                              .map((a) => AuditTrailTile(audit: a))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
