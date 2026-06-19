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

  Widget _buildSupervisorHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.approved,
                radius: 28,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.approved.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Supervisor',
                          style: TextStyle(
                              color: AppColors.approved,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: userRepo.getUserById(project.studentId),
      builder: (context, studentSnap) {
        return StreamBuilder<List<PhaseModel>>(
          stream: phaseRepo.getPhasesByProjectId(project.id),
          builder: (context, phaseSnap) {
            final student = studentSnap.data;
            final phases = phaseSnap.data ?? [];
            final currentPhase = phases.isNotEmpty
                ? phases.firstWhere(
                    (p) => p.phaseNo == project.currentPhase,
                    orElse: () => phases.first,
                  )
                : null;
            final pendingReview =
                phases.where((p) => p.isSubmitted).length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (pendingReview > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$pendingReview pending',
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (student != null)
                        InfoRow(
                            icon: Icons.person,
                            label: 'Student',
                            value: student.name),
                      InfoRow(
                          icon: Icons.layers,
                          label: 'Current Phase',
                          value: 'Phase ${project.currentPhase}',
                          valueColor: AppColors.primary),
                      if (currentPhase != null) ...[
                        InfoRow(
                            icon: Icons.info_outline,
                            label: 'Phase Status',
                            value: StatusHelper.getLabel(currentPhase.status),
                            valueColor:
                                StatusHelper.getColor(currentPhase.status)),
                        if (currentPhase.submittedAt != null)
                          InfoRow(
                              icon: Icons.access_time,
                              label: 'Last Submission',
                              value: DateFormatter.format(
                                  currentPhase.submittedAt)),
                      ],
                      const SizedBox(height: 8),
                      // Phase progress chips
                      Wrap(
                        spacing: 6,
                        children: phases
                            .map((p) => Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: StatusHelper.getColor(p.status)
                                        .withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: StatusHelper.getColor(p.status),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${p.phaseNo}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            StatusHelper.getColor(p.status),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
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
