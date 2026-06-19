import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';
import '../../utils/utils.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showAddUserDialog(BuildContext context, String defaultRole) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = defaultRole;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add ${selectedRole == 'student' ? 'Student' : 'Supervisor'}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(
                          value: 'supervisor', child: Text('Supervisor')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedRole = v ?? selectedRole),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
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
              builder: (_, admin, __) => ElevatedButton(
                onPressed: admin.loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await admin.createUser(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                          role: selectedRole,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'User created successfully'
                                : (admin.error ?? 'Failed')),
                            backgroundColor:
                                ok ? AppColors.approved : AppColors.error,
                          ),
                        );
                      },
                child: admin.loading
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
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Students (${admin.totalStudents})'),
            Tab(text: 'Supervisors (${admin.totalSupervisors})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final role = _tabCtrl.index == 0 ? 'student' : 'supervisor';
          _showAddUserDialog(context, role);
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _UserList(users: admin.students, role: 'student'),
          _UserList(users: admin.supervisors, role: 'supervisor'),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<UserModel> users;
  final String role;

  const _UserList({required this.users, required this.role});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return EmptyState(
        icon: role == 'student' ? Icons.person : Icons.supervisor_account,
        title: 'No ${role == 'student' ? 'Students' : 'Supervisors'} yet',
        subtitle: 'Tap the + button to add one',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final color = role == 'student' ? AppColors.primary : AppColors.approved;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email,
                    style: const TextStyle(fontSize: 12)),
                Text(
                  'Joined: ${DateFormatter.formatDate(user.createdAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete User'),
                      content: Text(
                          'Delete ${user.name}? This cannot be undone.'),
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
                    await context.read<AdminProvider>().deleteUser(user.id);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
