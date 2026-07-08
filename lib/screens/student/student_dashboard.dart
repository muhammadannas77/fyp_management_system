/// ------------------------------------------------------------------
/// File: student_dashboard.dart
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
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';
import '../../repositories/repositories.dart';
import '../../models/models.dart';
import '../shared/notifications_screen.dart';
import '../shared/login_screen.dart';
import 'phase_detail_screen.dart';
import 'project_history_screen.dart';
import '../../utils/utils.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final UserRepository _userRepo = UserRepository();
  String _supervisorName = '';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final projectProv = context.read<ProjectProvider>();
      final notifProv = context.read<NotificationProvider>();
      if (auth.currentUser != null) {
        projectProv.listenToStudentProject(auth.currentUser!.id);
        notifProv.startListening(auth.currentUser!.id);
        _loadSupervisor(auth.currentUser!.supervisorId);
      }
    });
  }

  /// -----------------------------------------
  /// Method: _loadSupervisor
  /// Purpose: Executes logic for _loadSupervisor and handles state or UI updates.
  /// -----------------------------------------
  Future<void> _loadSupervisor(String? supervisorId) async {
    if (supervisorId == null) return;
    final sup = await _userRepo.getUserById(supervisorId);
    if (mounted && sup != null) {
      setState(() => _supervisorName = sup.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final projectProv = context.watch<ProjectProvider>();
    final notifProv = context.watch<NotificationProvider>();
    final user = auth.currentUser;

    if (_isLoggingOut || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final project = projectProv.project;
    final phases = projectProv.phases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              if (notifProv.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${notifProv.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) async {
              if (v == 'logout') {
                setState(() => _isLoggingOut = true);
                context.read<ProjectProvider>().stopListening();
                context.read<NotificationProvider>().stopListening();
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AuthProvider>().refreshUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              _buildProfileCard(user),
              
              if (project == null) ...[
                const SizedBox(height: 32),
                const EmptyState(
                  icon: Icons.folder_off,
                  title: 'No Project Assigned',
                  subtitle: 'Your supervisor or admin will assign a project to you',
                ),
              ] else ...[
                const SizedBox(height: 24),
                
                // FYP Overview
                const Text('FYP Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                _buildOverviewSection(project, phases),
                const SizedBox(height: 24),
                
                // My Project
                const Text('My Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                _buildProjectCard(project, phases),
                const SizedBox(height: 24),
                
                // Quick Actions
                const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                _buildQuickActions(context, project, phases),
                const SizedBox(height: 32),
                
                // Phase Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Phase Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProjectHistoryScreen(projectId: project.id)),
                      ),
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('History'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Phase cards
                if (!projectProv.phasesLoaded)
                  const Center(child: CircularProgressIndicator())
                else if (phases.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: EmptyState(
                      icon: Icons.pending_actions,
                      title: 'No Phases Available',
                      subtitle: project.phaseType == 'customized'
                          ? 'Your supervisor has not created the project phases yet.'
                          : 'No phases have been assigned to this project.',
                    ),
                  )
                else
                  ...phases.map(
                    (phase) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PhaseProgressCard(
                        phase: phase,
                        isCurrent: phase.phaseNo == project.currentPhase,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhaseDetailScreen(
                              phase: phase,
                              project: project,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.length >= 2 ? user.name.substring(0, 2).toUpperCase() : 'S',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, size: 12, color: AppColors.accent),
                      const SizedBox(width: 4),
                      const Text('Student', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ProjectModel project, List<PhaseModel> phases) {
    final approvedCount = phases.where((p) => p.isApproved).length;
    final pendingCount = phases.where((p) => p.isSubmitted && !p.isApproved && !p.isChangesRequested).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
            icon: Icons.layers,
            iconColor: const Color(0xFF3B82F6),
            label: 'Current Phase',
            value: '${project.currentPhase}/${phases.length}',
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          _StatItem(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF10B981),
            label: 'Approved',
            value: '$approvedCount',
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          _StatItem(
            icon: Icons.access_time,
            iconColor: const Color(0xFFF59E0B),
            label: 'Pending Review',
            value: '$pendingCount',
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project, List<PhaseModel> phases) {
    final approved = phases.where((p) => p.isApproved).length;
    final total = phases.length;
    final progress = total > 0 ? (approved / total * 100).toInt() : 0;
    
    // Find last submission date
    DateTime? lastSub;
    for (var p in phases) {
      if (p.submittedAt != null) {
        if (lastSub == null || p.submittedAt!.isAfter(lastSub)) lastSub = p.submittedAt;
      }
      if (p.resubmittedAt != null) {
        if (lastSub == null || p.resubmittedAt!.isAfter(lastSub)) lastSub = p.resubmittedAt;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_open, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRowDetail(icon: Icons.person_outline, label: 'Supervisor', value: _supervisorName.isEmpty ? 'Loading...' : _supervisorName),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Status', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Active', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRowDetail(
            icon: Icons.access_time, 
            label: 'Last Submission', 
            value: lastSub != null ? DateFormatter.format(lastSub) : 'None'
          ),
          const SizedBox(height: 12),
          _InfoRowDetail(icon: Icons.check_circle_outline, label: 'Overall Progress', value: '$progress%', valueColor: AppColors.accent),
          const SizedBox(height: 20),
          // Phase circles
          Row(
            children: List.generate(phases.length, (index) {
              final p = phases[index];
              final isPast = p.phaseNo < project.currentPhase;
              final isCurrent = p.phaseNo == project.currentPhase;
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? AppColors.accent : (isPast ? Colors.white : Colors.white),
                  border: Border.all(color: isCurrent ? AppColors.accent : AppColors.accent, width: 1.5),
                ),
                child: Center(
                  child: isPast 
                    ? const Icon(Icons.check, size: 16, color: AppColors.accent)
                    : Text('${p.phaseNo}', style: TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : AppColors.accent,
                      )),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ProjectModel project, List<PhaseModel> phases) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.upload,
            label: 'Submit Phase Work',
            color: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            onTap: () {
              if (phases.isEmpty) return;
              final currentPhase = phases.firstWhere((p) => p.phaseNo == project.currentPhase, orElse: () => phases.last);
              Navigator.push(context, MaterialPageRoute(builder: (_) => PhaseDetailScreen(phase: currentPhase, project: project)));
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            icon: Icons.description_outlined,
            label: 'View My Submissions',
            color: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectHistoryScreen(projectId: project.id)));
            },
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _InfoRowDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRowDetail({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.primary)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: iconColor)),
          ],
        ),
      ),
    );
  }
}


