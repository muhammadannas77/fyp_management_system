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

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Project Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: admin.projects.isEmpty
          ? const EmptyState(
              icon: Icons.folder_off,
              title: 'No Projects Yet',
              subtitle: 'Tap the + button to create a project',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: admin.projects.length,
              itemBuilder: (context, index) {
                final project = admin.projects[index];
                final student = admin.students.cast<UserModel?>().firstWhere(
                    (s) => s?.id == project.studentId,
                    orElse: () => null);
                final supervisor = admin.supervisors
                    .cast<UserModel?>()
                    .firstWhere((s) => s?.id == project.supervisorId,
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
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
                                project.status == 'completed'
                                    ? 'Completed'
                                    : 'Active',
                                style: TextStyle(
                                  color: project.status == 'completed'
                                      ? AppColors.approved
                                      : AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
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
                        const SizedBox(height: 10),
                        // Progress bar
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
                                builder: (_) => ProjectHistoryScreen(
                                    projectId: project.id),
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
            ),
    );
  }
}
