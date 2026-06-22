/// ------------------------------------------------------------------
/// File: project_history_screen.dart
/// Role: User Interface (View)
/// 
/// Description:
/// Renders the visual elements of the application. Listens to Providers for state changes to display data dynamically. Contains purely presentation logic without direct database manipulation.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../repositories/repositories.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';

class ProjectHistoryScreen extends StatelessWidget {
  final String projectId;

  const ProjectHistoryScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final phaseRepo = PhaseRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Project History')),
      body: StreamBuilder<List<PhaseModel>>(
        stream: phaseRepo.getPhasesByProjectId(projectId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final phases = snap.data ?? [];
          
          List<AuditTrailModel> audits = [];
          
          for (final p in phases) {
            if (p.submittedAt != null) {
              audits.add(AuditTrailModel(
                id: 'sub_${p.id}', projectId: p.projectId, phaseNo: p.phaseNo,
                action: 'phase_submitted', performedBy: p.submittedBy ?? '', role: 'student',
                message: 'Phase ${p.phaseNo} submitted', timestamp: p.submittedAt!,
              ));
            }
            if (p.resubmittedAt != null) {
              audits.add(AuditTrailModel(
                id: 'resub_${p.id}', projectId: p.projectId, phaseNo: p.phaseNo,
                action: 'phase_resubmitted', performedBy: p.submittedBy ?? '', role: 'student',
                message: 'Phase ${p.phaseNo} resubmitted', timestamp: p.resubmittedAt!,
              ));
            }
            if (p.approvedAt != null) {
              audits.add(AuditTrailModel(
                id: 'app_${p.id}', projectId: p.projectId, phaseNo: p.phaseNo,
                action: 'phase_approved', performedBy: p.reviewedBy ?? '', role: 'supervisor',
                message: 'Phase ${p.phaseNo} approved', timestamp: p.approvedAt!,
              ));
            }
            if (p.changesRequestedAt != null) {
              audits.add(AuditTrailModel(
                id: 'req_${p.id}', projectId: p.projectId, phaseNo: p.phaseNo,
                action: 'changes_requested', performedBy: p.reviewedBy ?? '', role: 'supervisor',
                message: 'Changes requested for Phase ${p.phaseNo}', timestamp: p.changesRequestedAt!,
              ));
            }
          }
          
          if (audits.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No history yet',
              subtitle: 'Activity will appear here once the project starts',
            );
          }
          
          audits.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Group by phase
          final Map<int, List<AuditTrailModel>> grouped = {};
          for (final a in audits) {
            grouped.putIfAbsent(a.phaseNo, () => []).add(a);
          }
          final sortedPhases = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedPhases.length,
            itemBuilder: (context, index) {
              final phaseNo = sortedPhases[index];
              final entries = grouped[phaseNo]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              phaseNo == 0
                                  ? 'Project'
                                  : 'Phase $phaseNo',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${entries.length} activities',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...entries.map((a) => AuditTrailTile(audit: a)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
