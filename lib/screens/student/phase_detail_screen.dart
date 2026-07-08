/// ------------------------------------------------------------------
/// File: phase_detail_screen.dart
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
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';
import '../../utils/utils.dart';
import '../../repositories/repositories.dart';

import '../shared/comment_thread_screen.dart';

/// ------------------------------------------------------------------
/// PhaseDetailScreen (Student Submission Workspace)
/// ------------------------------------------------------------------
/// This is the primary interface where a student manages a single phase.
/// 
/// Functionality features:
/// 1. Dynamic Rendering: The form fields change depending on the phase number 
///    (e.g., Phase 4 shows GitHub/Screenshot options, Phase 5 shows demo links).
/// 2. Cloudinary File Uploads: Invokes the `ProjectProvider` to select and 
///    upload files to Cloudinary directly from the device.
/// 3. Read-Only State: If a phase is approved or pending review, the form 
///    disappears and the screen becomes a read-only receipt of their submission.
/// 4. Historical Transparency: Displays the activity log/audit trail of when 
///    the phase was submitted, rejected, and approved.
/// ------------------------------------------------------------------
class PhaseDetailScreen extends StatefulWidget {
  final PhaseModel phase;
  final ProjectModel project;

  const PhaseDetailScreen(
      {super.key, required this.phase, required this.project});

  @override
  State<PhaseDetailScreen> createState() => _PhaseDetailScreenState();
}

class _PhaseDetailScreenState extends State<PhaseDetailScreen> {
  final _submissionCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _demoVideoCtrl = TextEditingController();
  final _finalLinkCtrl = TextEditingController();

  final _userRepo = UserRepository();
  String? _reviewerName;
  String? _cachedReviewerId;

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

  Future<void> _fetchReviewerName(String uid) async {
    try {
      final user = await _userRepo.getUserById(uid);
      if (mounted) {
        setState(() {
          _reviewerName = user?.name ?? 'Unknown Supervisor';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reviewerName = 'Unknown Supervisor';
        });
      }
    }
  }



  @override
  void initState() {
    super.initState();
    // Pre-fill if there's existing submission text
    _submissionCtrl.text = widget.phase.submissionText ?? '';
    _githubCtrl.text = widget.phase.githubUrl ?? '';
    _demoVideoCtrl.text = widget.phase.demoVideoUrl ?? '';
    _finalLinkCtrl.text = widget.phase.finalProjectLink ?? '';
  }

  @override
  void dispose() {
    _submissionCtrl.dispose();
    _githubCtrl.dispose();
    _demoVideoCtrl.dispose();
    _finalLinkCtrl.dispose();
    super.dispose();
  }

  /// -----------------------------------------
  /// Method: _submit
  /// Purpose: Executes logic for _submit and handles state or UI updates.
  /// -----------------------------------------
  Future<void> _submit(PhaseModel phase) async {
    final isGeneric = widget.project.phaseType == 'generic';
    final isPhase4 = isGeneric && phase.phaseNo == 4;
    final isPhase5 = isGeneric && phase.phaseNo == 5;

    if (phase.requireText && _submissionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add submission notes before submitting.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (isPhase4) {
      final ghUrl = _githubCtrl.text.trim();
      if (ghUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GitHub Repository Link is required.'), backgroundColor: AppColors.error));
        return;
      }
      final ghUri = Uri.tryParse(ghUrl);
      if (ghUri == null || !ghUri.isAbsolute || (ghUri.scheme != 'http' && ghUri.scheme != 'https')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid GitHub URL (http/https).'), backgroundColor: AppColors.error));
        return;
      }
      final prov = context.read<ProjectProvider>();
      if (prov.selectedFile == null && phase.fileUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documentation File is required.'), backgroundColor: AppColors.error));
        return;
      }
      if (prov.selectedScreenshots.isEmpty && (phase.screenshots == null || phase.screenshots!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Development Screenshots are required.'), backgroundColor: AppColors.error));
        return;
      }
    }

    if (isPhase5) {
      final finalLink = _finalLinkCtrl.text.trim();
      if (finalLink.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Final Application Link is required.'), backgroundColor: AppColors.error));
        return;
      }
      final flUri = Uri.tryParse(finalLink);
      if (flUri == null || !flUri.isAbsolute || (flUri.scheme != 'http' && flUri.scheme != 'https')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid Application URL (http/https).'), backgroundColor: AppColors.error));
        return;
      }
      final demoLink = _demoVideoCtrl.text.trim();
      if (demoLink.isNotEmpty) {
        final dmUri = Uri.tryParse(demoLink);
        if (dmUri == null || !dmUri.isAbsolute || (dmUri.scheme != 'http' && dmUri.scheme != 'https')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid Demonstration Video URL (http/https).'), backgroundColor: AppColors.error));
          return;
        }
      }
      final prov = context.read<ProjectProvider>();
      if (prov.selectedFile == null && phase.fileUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Final Documentation is required.'), backgroundColor: AppColors.error));
        return;
      }
      if (prov.presentationFile == null && phase.presentationUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Final Presentation is required.'), backgroundColor: AppColors.error));
        return;
      }
      if (prov.testCasesFile == null && phase.testCasesUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Cases Document is required.'), backgroundColor: AppColors.error));
        return;
      }
    }

    final user = context.read<AuthProvider>().currentUser!;
    final projectProv = context.read<ProjectProvider>();
    final isResubmission = phase.isChangesRequested;

    final ok = await projectProv.submitPhase(
      phaseId: phase.id,
      projectId: widget.project.id,
      phaseNo: phase.phaseNo,
      submissionText: phase.requireText ? _submissionCtrl.text.trim() : '',
      studentId: user.id,
      supervisorId: widget.project.supervisorId,
      studentName: user.name,
      isResubmission: isResubmission,
      githubUrl: isPhase4 ? _githubCtrl.text.trim() : (phase.requireLink ? _githubCtrl.text.trim() : null),
      existingScreenshots: phase.screenshots,
      demoVideoUrl: isPhase5 ? _demoVideoCtrl.text.trim() : null,
      finalProjectLink: isPhase5 ? _finalLinkCtrl.text.trim() : null,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isResubmission
              ? 'Phase resubmitted successfully!'
              : 'Phase submitted successfully!'),
          backgroundColor: AppColors.approved,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(projectProv.error ?? 'Submission failed. Try again.'),
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
        final String pdfUrl = finalUrl.replaceFirst('/upload/', '/upload/fl_attachment/');
        final Uri pdfUri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(pdfUri)) {
          final success = await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
          if (success) return;
        }
      }

      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file.')),
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
    // Watch provider so UI updates when phase status changes
    final projectProv = context.watch<ProjectProvider>();
    final phase = projectProv.phases.isNotEmpty
        ? projectProv.phases.firstWhere(
            (p) => p.id == widget.phase.id,
            orElse: () => widget.phase,
          )
        : widget.phase;

    final isGeneric = widget.project.phaseType == 'generic';
    final isPhase4 = isGeneric && phase.phaseNo == 4;
    final isPhase5 = isGeneric && phase.phaseNo == 5;

    if (phase.reviewedBy != null && phase.reviewedBy != _cachedReviewerId) {
      _cachedReviewerId = phase.reviewedBy;
      _reviewerName = 'Loading...';
      _fetchReviewerName(phase.reviewedBy!);
    }

    final canSubmit = phase.isPendingSubmission || phase.isChangesRequested;

    return LoadingOverlay(
      isLoading: projectProv.loading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Phase ${phase.phaseNo}: ${phase.title}',
              style: const TextStyle(fontSize: 14)),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              tooltip: 'Comments',
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
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status + Info Card ──────────────────────────────────────
              Container(
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: StatusHelper.getColor(phase.status).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${phase.phaseNo}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: StatusHelper.getColor(phase.status),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              phase.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          StatusBadge(status: phase.status),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 20),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Change Request Banner ───────────────────────────────────
              if (phase.isChangesRequested &&
                  phase.changeRequestReason != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          phase.changeRequestReason!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              if (phase.isChangesRequested) const SizedBox(height: 8),

              // ── Requirements Card ───────────────────────────────────────
              if (phase.requirements.isNotEmpty || (phase.description != null && phase.description!.isNotEmpty))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(phase.requirements.isNotEmpty ? Icons.checklist : Icons.description,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(phase.requirements.isNotEmpty ? 'Requirements' : 'Description',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (phase.description != null && phase.description!.isNotEmpty) ...[
                          Text(phase.description!, style: const TextStyle(fontSize: 14)),
                          if (phase.requirements.isNotEmpty) const SizedBox(height: 12),
                        ],
                        if (phase.requirements.isNotEmpty)
                          ...phase.requirements.asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${entry.key + 1}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(entry.value,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // ── Existing Submitted Text ─────────────────────────────────
              if (phase.submissionText != null && phase.submissionText!.isNotEmpty && !canSubmit) ...[
                const Text(
                  'Submission Notes',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
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
                const SizedBox(height: 16),
              ],

              // ── Existing Submitted File ─────────────────────────────────
              if (phase.fileUrl != null || phase.fileName != null) ...[
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
                          onPressed: () => _openFile(phase.fileUrl!),
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
                        const Expanded(
                          child: Text(
                            'File not uploaded yet',
                            style: TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],

              // ── Submitted Phase 4 Details ────────────────────────────────
              if (phase.phaseNo == 4 && (phase.githubUrl != null || (phase.screenshots != null && phase.screenshots!.isNotEmpty)))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.code, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Development Details',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (phase.githubUrl != null && phase.githubUrl!.isNotEmpty) ...[
                          const Text('Repository:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _openFile(phase.githubUrl!),
                            child: Text(phase.githubUrl!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (phase.screenshots != null && phase.screenshots!.isNotEmpty) ...[
                          const Text('Screenshots:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: phase.screenshots!.map((url) {
                              return InkWell(
                                onTap: () => _openFile(url),
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
                                    child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (phase.phaseNo == 4 && (phase.githubUrl != null || (phase.screenshots != null && phase.screenshots!.isNotEmpty))) 
                const SizedBox(height: 8),

              // ── Submitted Phase 5 Details ────────────────────────────────
              if (phase.phaseNo == 5 && (phase.demoVideoUrl != null || phase.finalProjectLink != null || phase.presentationUrl != null || phase.testCasesUrl != null))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stars, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Final Deliverables',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (phase.demoVideoUrl != null && phase.demoVideoUrl!.isNotEmpty) ...[
                          const Text('Demo Video Link:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _openFile(phase.demoVideoUrl!),
                            child: Text(phase.demoVideoUrl!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (phase.finalProjectLink != null && phase.finalProjectLink!.isNotEmpty) ...[
                          const Text('Final Project Link:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _openFile(phase.finalProjectLink!),
                            child: Text(phase.finalProjectLink!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (phase.presentationUrl != null || phase.presentationName != null) ...[
                          const Text('Presentation:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          FileAttachmentRow(
                            fileName: phase.presentationName ?? 'Presentation',
                            fileUrl: phase.presentationUrl,
                          ),
                          if (phase.presentationUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                onPressed: () => _openFile(phase.presentationUrl!),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text('Open'),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('(File not uploaded yet)', style: TextStyle(color: AppColors.error, fontSize: 12)),
                            ),
                          const SizedBox(height: 12),
                        ],
                        if (phase.testCasesUrl != null || phase.testCasesName != null) ...[
                          const Text('Test Cases:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          FileAttachmentRow(
                            fileName: phase.testCasesName ?? 'Test Cases',
                            fileUrl: phase.testCasesUrl,
                          ),
                          if (phase.testCasesUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                onPressed: () => _openFile(phase.testCasesUrl!),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text('Open'),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('(File not uploaded yet)', style: TextStyle(color: AppColors.error, fontSize: 12)),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              if (phase.phaseNo == 5 && (phase.demoVideoUrl != null || phase.finalProjectLink != null || phase.presentationUrl != null || phase.testCasesUrl != null)) 
                const SizedBox(height: 8),

              // ── Submission Form (only if can submit) ────────────────────
              if (canSubmit)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              phase.isChangesRequested
                                  ? Icons.replay
                                  : Icons.upload_file,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              phase.isChangesRequested
                                  ? 'Resubmit Phase'
                                  : 'Submit Phase',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (phase.requireText) ...[
                          TextField(
                            controller: _submissionCtrl,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Submission Notes *',
                              hintText: 'Describe what you have completed in this phase...',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (isPhase4) ...[
                          TextField(
                            controller: _githubCtrl,
                            decoration: const InputDecoration(
                              labelText: 'GitHub Repository Link *',
                              hintText: 'https://github.com/username/repo',
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Consumer<ProjectProvider>(
                            builder: (_, prov, __) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Development Screenshots *', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (prov.selectedScreenshots.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(prov.selectedScreenshots.length, (index) {
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade400),
                                            ),
                                            child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                          ),
                                          Positioned(
                                            right: -8,
                                            top: -8,
                                            child: InkWell(
                                              onTap: () => prov.removeScreenshot(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: prov.loading ? null : prov.pickScreenshots,
                                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                                  label: const Text('Upload Images (JPG, PNG)'),
                                ),
                                const SizedBox(height: 14),
                                if (prov.selectedFile != null) ...[
                                  FileAttachmentRow(
                                    fileName: prov.selectedFile!.name,
                                    showRemove: true,
                                    onRemove: prov.clearSelectedFile,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: prov.loading ? null : prov.pickFile,
                                    icon: const Icon(Icons.attach_file, size: 18),
                                    label: Text(prov.selectedFile != null
                                        ? 'Change File'
                                        : 'Attach Documentation (PDF, Word) *'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isPhase5) ...[
                          TextField(
                            controller: _demoVideoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Demonstration Video (Optional)',
                              hintText: 'YouTube or Google Drive URL',
                              prefixIcon: Icon(Icons.video_library),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _finalLinkCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Application Link (APK / Web URL) *',
                              hintText: 'https://...',
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Consumer<ProjectProvider>(
                            builder: (_, prov, __) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (prov.selectedFile != null) ...[
                                  FileAttachmentRow(
                                    fileName: prov.selectedFile!.name,
                                    showRemove: true,
                                    onRemove: prov.clearSelectedFile,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: prov.loading ? null : prov.pickFile,
                                    icon: const Icon(Icons.attach_file, size: 18),
                                    label: Text(prov.selectedFile != null
                                        ? 'Change Documentation'
                                        : 'Final Documentation (PDF/DOC) *'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (prov.presentationFile != null) ...[
                                  FileAttachmentRow(
                                    fileName: prov.presentationFile!.name,
                                    showRemove: true,
                                    onRemove: prov.clearPresentationFile,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: prov.loading ? null : prov.pickPresentationFile,
                                    icon: const Icon(Icons.slideshow, size: 18),
                                    label: Text(prov.presentationFile != null
                                        ? 'Change Presentation'
                                        : 'Final Presentation (PPT/PPTX) *'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (prov.testCasesFile != null) ...[
                                  FileAttachmentRow(
                                    fileName: prov.testCasesFile!.name,
                                    showRemove: true,
                                    onRemove: prov.clearTestCasesFile,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: prov.loading ? null : prov.pickTestCasesFile,
                                    icon: const Icon(Icons.fact_check, size: 18),
                                    label: Text(prov.testCasesFile != null
                                        ? 'Change Test Cases'
                                        : 'Test Cases Document (PDF/DOC) *'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!isPhase4 && !isPhase5 && phase.requireLink) ...[
                          TextField(
                            controller: _githubCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Submit Link (GitHub / Drive / YouTube etc)',
                              hintText: 'https://...',
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (!isPhase4 && !isPhase5 && phase.requireImage) ...[
                          Consumer<ProjectProvider>(
                            builder: (_, prov, __) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Project Screenshots (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (prov.selectedScreenshots.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(prov.selectedScreenshots.length, (index) {
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade400),
                                            ),
                                            child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                          ),
                                          Positioned(
                                            right: -8,
                                            top: -8,
                                            child: InkWell(
                                              onTap: () => prov.removeScreenshot(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: prov.loading ? null : prov.pickScreenshots,
                                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                                  label: const Text('Add Screenshots'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (!isPhase4 && !isPhase5 && phase.requireFile) ...[
                          Consumer<ProjectProvider>(
                            builder: (_, prov, __) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (prov.selectedFile != null) ...[
                                  FileAttachmentRow(
                                    fileName: prov.selectedFile!.name,
                                    showRemove: true,
                                    onRemove: prov.clearSelectedFile,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: prov.loading ? null : prov.pickFile,
                                    icon: const Icon(Icons.attach_file, size: 18),
                                    label: Text(prov.selectedFile != null
                                        ? 'Change File'
                                        : 'Attach PDF / DOC'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                projectProv.loading ? null : () => _submit(phase),
                            icon: Icon(
                              phase.isChangesRequested
                                  ? Icons.replay
                                  : Icons.upload,
                              size: 18,
                            ),
                            label: Text(
                              phase.isChangesRequested
                                  ? 'Resubmit Phase'
                                  : 'Submit Phase',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (canSubmit) const SizedBox(height: 8),

              // ── Approved banner ─────────────────────────────────────────
              if (phase.isApproved)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.approved.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.approved.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.approved, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Phase Approved!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.approved)),
                            Text(
                              DateFormatter.format(phase.approvedAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (phase.isApproved) const SizedBox(height: 8),

              // ── Activity Log (Audit Trail) ──────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history,
                              color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Activity Log',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final List<AuditTrailModel> audits = [];
                          
                          if (phase.submittedAt != null) {
                            audits.add(AuditTrailModel(
                              id: 'sub_${phase.id}', projectId: phase.projectId, phaseNo: phase.phaseNo,
                              action: 'phase_submitted', performedBy: phase.submittedBy ?? '', role: 'student',
                              message: 'Student submitted phase', timestamp: phase.submittedAt!,
                            ));
                          }
                          if (phase.resubmittedAt != null) {
                            audits.add(AuditTrailModel(
                              id: 'resub_${phase.id}', projectId: phase.projectId, phaseNo: phase.phaseNo,
                              action: 'phase_resubmitted', performedBy: phase.submittedBy ?? '', role: 'student',
                              message: 'Student resubmitted phase', timestamp: phase.resubmittedAt!,
                            ));
                          }
                          if (phase.approvedAt != null) {
                            audits.add(AuditTrailModel(
                              id: 'app_${phase.id}', projectId: phase.projectId, phaseNo: phase.phaseNo,
                              action: 'phase_approved', performedBy: phase.reviewedBy ?? '', role: 'supervisor',
                              message: 'Supervisor approved phase', timestamp: phase.approvedAt!,
                            ));
                          }
                          if (phase.changesRequestedAt != null) {
                            audits.add(AuditTrailModel(
                              id: 'req_${phase.id}', projectId: phase.projectId, phaseNo: phase.phaseNo,
                              action: 'changes_requested', performedBy: phase.reviewedBy ?? '', role: 'supervisor',
                              message: 'Supervisor requested changes', timestamp: phase.changesRequestedAt!,
                            ));
                          }

                          if (audits.isEmpty) {
                            return const Text(
                              'No activity recorded yet.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13),
                            );
                          }
                          
                          audits.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                          return Column(
                            children: audits
                                .map((a) => AuditTrailTile(audit: a))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Change Request Banner ───────────────────────────────────────────────────
class _ChangeRequestBanner extends StatelessWidget {
  final String reason;

  const _ChangeRequestBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.changesRequested.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.changesRequested.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note,
                  color: AppColors.changesRequested, size: 20),
              SizedBox(width: 8),
              Text(
                'Changes Requested by Supervisor',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.changesRequested,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please address the feedback above and resubmit.',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
