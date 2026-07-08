/// ------------------------------------------------------------------
/// File: supervisor_dashboard.dart
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
import '../../repositories/repositories.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';
import '../../utils/utils.dart';
import '../shared/notifications_screen.dart';
import '../shared/login_screen.dart';
import 'supervisor_review_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final ProjectRepository _projectRepo = ProjectRepository();
  final UserRepository _userRepo = UserRepository();
  final PhaseRepository _phaseRepo = PhaseRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser!;
      context.read<NotificationProvider>().startListening(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifProv = context.watch<NotificationProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
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
                        color: Colors.red, shape: BoxShape.circle),
                    child: Center(
                        child: Text('${notifProv.unreadCount}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10))),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) async {
              if (v == 'logout') {
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
      body: StreamBuilder<List<ProjectModel>>(
        stream: _projectRepo.getProjectsBySupervisorId(user.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final projects = snap.data ?? [];
          if (projects.isEmpty) {
            return Column(
              children: [
                _buildSupervisorHeader(user),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.folder_open,
                    title: 'No Students Assigned',
                    subtitle: 'Projects will appear here once admin assigns them',
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async {},
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSupervisorHeader(user)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Assigned Projects (${projects.length})',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ProjectCard(
                        project: projects[index],
                        userRepo: _userRepo,
                        phaseRepo: _phaseRepo,
                      ),
                      childCount: projects.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// -----------------------------------------
  /// Method: _buildSupervisorHeader
  /// Purpose: Executes logic for _buildSupervisorHeader and handles state or UI updates.
  /// -----------------------------------------
  Widget _buildSupervisorHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), AppColors.accent], // Blue to Teal
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name.substring(0, 2).toUpperCase() : 'S',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 12, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text('Supervisor',
                              style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final UserRepository userRepo;
  final PhaseRepository phaseRepo;

  const _ProjectCard({
    required this.project,
    required this.userRepo,
    required this.phaseRepo,
  });

  Widget _buildProjectDetailRow(IconData icon, String label, String value, Color valueColor, {bool isStatus = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        if (isStatus)
          Row(
            children: [
              Text(
                value,
                style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(Icons.circle, size: 8, color: valueColor),
            ],
          )
        else
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: userRepo.getUserById(project.studentId),
      builder: (context, studentSnap) {
        return StreamBuilder<List<PhaseModel>>(
          stream: phaseRepo.getPhasesByProjectId(project.id),
          builder: (context, phaseSnap) {
            final isStudentLoading = studentSnap.connectionState == ConnectionState.waiting;
            final isPhaseLoading = phaseSnap.connectionState == ConnectionState.waiting;
            final phases = phaseSnap.data ?? [];

            if (isStudentLoading || isPhaseLoading) {
              return const Card(
                margin: EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final student = studentSnap.data;
            final currentPhase = phases.isNotEmpty
                ? phases.firstWhere(
                    (p) => p.phaseNo == project.currentPhase,
                    orElse: () => phases.first,
                  )
                : null;

            final studentName = student?.name ?? 'Unknown Student';
            final phaseStatusLabel = currentPhase != null ? StatusHelper.getLabel(currentPhase.status) : 'No Phases';
            final phaseStatusColor = currentPhase != null ? StatusHelper.getColor(currentPhase.status) : Colors.grey;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupervisorReviewScreen(
                                project: project,
                                student: student,
                              ),
                            ),
                          ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.folder_open, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                project.title,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildProjectDetailRow(Icons.person, 'Student', studentName, AppColors.primary),
                        const SizedBox(height: 12),
                        _buildProjectDetailRow(Icons.layers, 'Current Phase', 'Phase ${project.currentPhase}', AppColors.primary),
                        const SizedBox(height: 12),
                        _buildProjectDetailRow(Icons.info_outline, 'Phase Status', phaseStatusLabel, phaseStatusColor, isStatus: true),
                        if (currentPhase != null && currentPhase.submittedAt != null) ...[
                          const SizedBox(height: 12),
                          _buildProjectDetailRow(Icons.access_time, 'Last Submission', DateFormatter.format(currentPhase.submittedAt!), AppColors.primary),
                        ],
                        const SizedBox(height: 20),
                        // Phase progress chips
                        if (phases.isEmpty)
                          const Text(
                            'No phases created yet.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 13),
                          )
                        else
                          Row(
                            children: phases.map((p) {
                              final isActive = p.phaseNo == project.currentPhase;
                              final isCompleted = p.phaseNo < project.currentPhase;

                              Color bgColor = isActive ? const Color(0xFF3B82F6) : Colors.transparent;
                              Color borderColor = isActive ? const Color(0xFF3B82F6) : (isCompleted ? const Color(0xFF93C5FD) : AppColors.divider);
                              Color textColor = isActive ? Colors.white : (isCompleted ? const Color(0xFF3B82F6) : AppColors.textSecondary);

                              return Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor, width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    '${p.phaseNo}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
