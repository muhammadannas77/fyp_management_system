import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';
import '../shared/notifications_screen.dart';
import '../shared/login_screen.dart';
import 'user_management_screen.dart';
import 'project_management_screen.dart';
import '../student/project_history_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().startListening();
      final user = context.read<AuthProvider>().currentUser!;
      context.read<NotificationProvider>().startListening(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final notifProv = context.watch<NotificationProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = user.name.isNotEmpty ? user.name : 'System Administration';
    final avatarInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
                context.read<AdminProvider>().stopListening();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.changesRequested,
                      radius: 26,
                      child: Text(
                        avatarInitial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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
                        color: AppColors.changesRequested.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Admin',
                          style: TextStyle(
                              color: AppColors.changesRequested,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader(title: 'Overview'),
            // Stats grid
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 600 ? 4 : 2;
                final itemWidth = (width - ((crossAxisCount - 1) * 12)) / crossAxisCount;
                final aspectRatio = itemWidth / 160; // Base height of 160
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: aspectRatio,
                  children: [
                    StatsCard(
                      title: 'Total Users',
                      value: '${admin.allUsers.length}',
                      icon: Icons.people,
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                      ),
                    ),
                    StatsCard(
                      title: 'Students',
                      value: '${admin.totalStudents}',
                      icon: Icons.person,
                      color: AppColors.primaryLight,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserManagementScreen(initialTabIndex: 0)),
                      ),
                    ),
                    StatsCard(
                      title: 'Supervisors',
                      value: '${admin.totalSupervisors}',
                      icon: Icons.supervisor_account,
                      color: AppColors.approved,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserManagementScreen(initialTabIndex: 1)),
                      ),
                    ),
                    StatsCard(
                      title: 'Projects',
                      value: '${admin.totalProjects}',
                      icon: Icons.folder_open,
                      color: AppColors.pendingSubmission,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            const SectionHeader(title: 'Management'),
            // Action cards
            _ActionCard(
              title: 'User Management',
              subtitle: 'Add, view, and manage students & supervisors',
              icon: Icons.manage_accounts,
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              ),
            ),
            _ActionCard(
              title: 'Project Management',
              subtitle: 'Create projects, assign supervisors, track progress',
              icon: Icons.folder_special,
              color: AppColors.approved,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProjectManagementScreen()),
              ),
            ),
            const SizedBox(height: 8),
            // Recent projects
            if (admin.projects.isNotEmpty) ...[
              const SectionHeader(title: 'Recent Projects'),
              ...admin.projects.take(5).map(
                    (p) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.folder, color: Colors.white, size: 20),
                        ),
                        title: Text(p.title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('Phase ${p.currentPhase} • ${p.status}',
                            style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProjectHistoryScreen(projectId: p.id)),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
