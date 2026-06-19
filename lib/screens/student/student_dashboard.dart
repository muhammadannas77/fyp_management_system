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

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final UserRepository _userRepo = UserRepository();
  String _supervisorName = '';

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

    if (user == null) {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 24,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text(user.email,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Student',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (_supervisorName.isNotEmpty)
                        InfoRow(
                          icon: Icons.supervisor_account,
                          label: 'Supervisor',
                          value: _supervisorName,
                        ),
                      if (project != null) ...[
                        InfoRow(
                          icon: Icons.folder_open,
                          label: 'Project',
                          value: project.title,
                        ),
                        InfoRow(
                          icon: Icons.layers,
                          label: 'Current Phase',
                          value: 'Phase ${project.currentPhase}',
                          valueColor: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // No project state
              if (project == null) ...[
                const SizedBox(height: 32),
                const EmptyState(
                  icon: Icons.folder_off,
                  title: 'No Project Assigned',
                  subtitle:
                      'Your supervisor or admin will assign a project to you',
                ),
              ] else ...[
                // Progress overview
                SectionHeader(
                  title: 'Project Phases',
                  trailing: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProjectHistoryScreen(projectId: project.id)),
                    ),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('History'),
                  ),
                ),
                // Progress bar
                if (phases.isNotEmpty) ...[
                  _buildProgressBar(phases),
                  const SizedBox(height: 12),
                ],
                // Phase cards
                if (phases.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  ...phases.map(
                    (phase) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildProgressBar(List<PhaseModel> phases) {
    final approved = phases.where((p) => p.isApproved).length;
    final total = phases.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Progress',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$approved/$total phases',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? approved / total : 0,
                minHeight: 10,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.approved),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
