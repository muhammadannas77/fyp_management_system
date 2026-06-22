/// ------------------------------------------------------------------
/// File: project_management_screen.dart
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
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';
import '../../utils/utils.dart';
import '../student/project_history_screen.dart';

class ProjectManagementScreen extends StatelessWidget {
  const ProjectManagementScreen({super.key});

  /// -----------------------------------------
  /// Method: _showCreateProjectDialog
  /// Purpose: Executes logic for _showCreateProjectDialog and handles state or UI updates.
  /// -----------------------------------------
  void _showCreateProjectDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String? selectedStudentId;
    String? selectedSupervisorId;
    final formKey = GlobalKey<FormState>();
    final admin = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Project'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Project Title'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Student dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedStudentId,
                    decoration: const InputDecoration(labelText: 'Student'),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 350,
                    isExpanded: true,
                    items: admin.students
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.email})',
                                  style: const TextStyle(color: Colors.black87),
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedStudentId = v),
                    validator: (v) => v == null ? 'Select a student' : null,
                  ),
                  const SizedBox(height: 12),
                  // Supervisor dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedSupervisorId,
                    decoration:
                        const InputDecoration(labelText: 'Supervisor'),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 350,
                    isExpanded: true,
                    items: admin.supervisors
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.email})',
                                  style: const TextStyle(color: Colors.black87),
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedSupervisorId = v),
                    validator: (v) => v == null ? 'Select a supervisor' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            Consumer<AdminProvider>(
              builder: (_, adminProv, __) => ElevatedButton(
                onPressed: adminProv.loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await adminProv.createProject(
                          studentId: selectedStudentId!,
                          supervisorId: selectedSupervisorId!,
                          title: titleCtrl.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Project created successfully'
                                : (adminProv.error ?? 'Failed')),
                            backgroundColor:
                                ok ? AppColors.approved : AppColors.error,
                          ),
                        );
                      },
                child: adminProv.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -----------------------------------------
  /// Method: _showEditProjectDialog
  /// Purpose: Executes logic for _showEditProjectDialog and handles state or UI updates.
  /// -----------------------------------------
  void _showEditProjectDialog(BuildContext context, ProjectModel project) {
    final titleCtrl = TextEditingController(text: project.title);
    String? selectedStudentId = project.studentId;
    String? selectedSupervisorId = project.supervisorId;
    final formKey = GlobalKey<FormState>();
    final admin = context.read<AdminProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Project'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Project Title'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: admin.students.any((s) => s.id == selectedStudentId) ? selectedStudentId : null,
                    decoration: const InputDecoration(labelText: 'Student'),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 350,
                    isExpanded: true,
                    items: admin.students
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.email})',
                                  style: const TextStyle(color: Colors.black87),
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedStudentId = v),
                    validator: (v) => v == null ? 'Select a student' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: admin.supervisors.any((s) => s.id == selectedSupervisorId) ? selectedSupervisorId : null,
                    decoration:
                        const InputDecoration(labelText: 'Supervisor'),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 350,
                    isExpanded: true,
                    items: admin.supervisors
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.email})',
                                  style: const TextStyle(color: Colors.black87),
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedSupervisorId = v),
                    validator: (v) => v == null ? 'Select a supervisor' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            Consumer<AdminProvider>(
              builder: (_, adminProv, __) => ElevatedButton(
                onPressed: adminProv.loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await adminProv.updateProjectCore(
                          project.id,
                          studentId: selectedStudentId!,
                          supervisorId: selectedSupervisorId!,
                          title: titleCtrl.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Project updated successfully'
                                : (adminProv.error ?? 'Failed')),
                            backgroundColor:
                                ok ? AppColors.approved : AppColors.error,
                          ),
                        );
                      },
                child: adminProv.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Project Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Projects'),
              Tab(text: 'Archived Projects'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateProjectDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('New Project'),
        ),
        body: TabBarView(
          children: [
            _buildProjectList(context, admin.projects, isActive: true),
            _buildProjectList(context, admin.archivedProjects, isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(
      BuildContext context, List<ProjectModel> projectList,
      {required bool isActive}) {
    final admin = context.watch<AdminProvider>();

    if (projectList.isEmpty) {
      return EmptyState(
        icon: Icons.folder_off,
        title: 'No Projects Yet',
        subtitle: isActive
            ? 'Tap the + button to create a project'
            : 'No archived projects found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: projectList.length,
      itemBuilder: (context, index) {
        final project = projectList[index];
        final student = admin.students.cast<UserModel?>().firstWhere(
            (s) => s?.id == project.studentId,
            orElse: () => null);
        final supervisor = admin.supervisors.cast<UserModel?>().firstWhere(
            (s) => s?.id == project.supervisorId,
            orElse: () => null);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: project.status == 'completed'
                            ? AppColors.approved.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        project.status == 'completed' ? 'Completed' : 'Active',
                        style: TextStyle(
                          color: project.status == 'completed'
                              ? AppColors.approved
                              : AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          _showEditProjectDialog(context, project);
                        } else if (val == 'archive') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Archive Project'),
                              content: const Text(
                                  'Are you sure you want to archive this project?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Archive'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            final ok = await context
                                .read<AdminProvider>()
                                .archiveProject(project.id);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Project archived successfully'),
                                    backgroundColor: AppColors.approved),
                              );
                            }
                          }
                        } else if (val == 'restore') {
                          final ok = await context
                              .read<AdminProvider>()
                              .restoreProject(project.id);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Project restored successfully'),
                                  backgroundColor: AppColors.approved),
                            );
                          }
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Project'),
                              content: const Text(
                                  'Are you sure you want to delete this project? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            final ok = await context
                                .read<AdminProvider>()
                                .deleteProject(project.id);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Project deleted successfully'),
                                    backgroundColor: AppColors.approved),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (ctx) {
                        if (isActive) {
                          return [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Project'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'archive',
                              child: Row(children: [
                                Icon(Icons.archive, size: 18),
                                SizedBox(width: 8),
                                Text('Archive Project'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete,
                                    color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Delete Project',
                                    style: TextStyle(color: Colors.red)),
                              ]),
                            ),
                          ];
                        } else {
                          return [
                            const PopupMenuItem(
                              value: 'restore',
                              child: Row(children: [
                                Icon(Icons.restore, size: 18),
                                SizedBox(width: 8),
                                Text('Restore Project'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete,
                                    color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Permanently Delete Project',
                                    style: TextStyle(color: Colors.red)),
                              ]),
                            ),
                          ];
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (student != null)
                  InfoRow(
                      icon: Icons.person,
                      label: 'Student',
                      value: student.name),
                if (supervisor != null)
                  InfoRow(
                      icon: Icons.supervisor_account,
                      label: 'Supervisor',
                      value: supervisor.name),
                InfoRow(
                    icon: Icons.layers,
                    label: 'Phase',
                    value: 'Phase ${project.currentPhase} / 5',
                    valueColor: AppColors.primary),
                InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    value: DateFormatter.formatDate(project.createdAt)),
                if (!isActive && project.archivedAt != null)
                  InfoRow(
                      icon: Icons.archive,
                      label: 'Archived',
                      value: DateFormatter.formatDate(project.archivedAt)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.currentPhase / 5,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      project.status == 'completed'
                          ? AppColors.approved
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProjectHistoryScreen(projectId: project.id),
                      ),
                    ),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('View History'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
