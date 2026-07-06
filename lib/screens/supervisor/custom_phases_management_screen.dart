import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../constants/app_constants.dart';
import '../../utils/utils.dart';

class CustomPhasesManagementScreen extends StatefulWidget {
  final ProjectModel project;

  const CustomPhasesManagementScreen({super.key, required this.project});

  @override
  State<CustomPhasesManagementScreen> createState() => _CustomPhasesManagementScreenState();
}

class _CustomPhasesManagementScreenState extends State<CustomPhasesManagementScreen> {
  final PhaseRepository _phaseRepo = PhaseRepository();
  bool _loading = true;
  bool _saving = false;
  List<PhaseModel> _phases = [];
  final List<String> _deletedPhaseIds = [];

  @override
  void initState() {
    super.initState();
    _loadPhases();
  }

  Future<void> _loadPhases() async {
    try {
      final stream = _phaseRepo.getPhasesByProjectId(widget.project.id);
      final phases = await stream.first;
      if (mounted) {
        setState(() {
          _phases = List.from(phases);
          _loading = false;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _saving = false;
        });
      }
    }
  }

  Future<void> _addPhase() async {
    setState(() => _saving = true);
    
    final newPhase = PhaseModel(
      id: '',
      projectId: widget.project.id,
      phaseNo: _phases.length + 1,
      title: 'New Phase',
      duration: '',
      requirements: [],
      status: _phases.isEmpty ? 'pending_submission' : 'locked',
      unlocked: _phases.isEmpty,
    );
    
    final updatedPhases = List<PhaseModel>.from(_phases)..add(newPhase);
    
    try {
      await _phaseRepo.saveCustomPhases(
        projectId: widget.project.id,
        phases: updatedPhases,
        deletedPhaseIds: [],
        currentPhase: widget.project.currentPhase,
      );
      await _loadPhases();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add phase.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _editPhase(int index) async {
    final phase = _phases[index];
    final result = await showDialog<PhaseModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PhaseEditDialog(phase: phase),
    );

    if (result != null) {
      setState(() => _saving = true);
      final updatedPhases = List<PhaseModel>.from(_phases);
      updatedPhases[index] = result;
      
      try {
        await _phaseRepo.saveCustomPhases(
          projectId: widget.project.id,
          phases: updatedPhases,
          deletedPhaseIds: [],
          currentPhase: widget.project.currentPhase,
        );
        await _loadPhases();
      } catch (e) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update phase.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _deletePhase(int index) {
    final phase = _phases[index];
    if (phase.status != 'locked' && phase.status != 'pending_submission') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete a phase that has submissions.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Phase'),
        content: const Text('Are you sure you want to delete this phase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _saving = true);
              
              final deletedId = phase.id;
              final updatedPhases = List<PhaseModel>.from(_phases)..removeAt(index);
              
              try {
                await _phaseRepo.saveCustomPhases(
                  projectId: widget.project.id,
                  phases: updatedPhases,
                  deletedPhaseIds: deletedId.isNotEmpty ? [deletedId] : [],
                  currentPhase: widget.project.currentPhase,
                );
                if (deletedId.isNotEmpty) {
                  _deletedPhaseIds.add(deletedId);
                }
                await _loadPhases();
              } catch (e) {
                if (mounted) {
                  setState(() => _saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete phase.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePhases() async {
    if (_phases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one phase.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _phaseRepo.saveCustomPhases(
        projectId: widget.project.id,
        phases: _phases,
        deletedPhaseIds: _deletedPhaseIds,
        currentPhase: widget.project.currentPhase,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom phases saved successfully.'),
          backgroundColor: AppColors.approved,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save custom phases.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Custom Phases'),
        actions: [
          if (!_loading)
            IconButton(
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save, color: Colors.white),
              onPressed: _saving ? null : _savePhases,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading || _saving ? null : _addPhase,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _phases.isEmpty
              ? const Center(
                  child: Text(
                    'No custom phases created yet.\nTap the + button to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _phases.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = _phases.removeAt(oldIndex);
                      _phases.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final phase = _phases[index];
                    return Card(
                      key: ValueKey(phase.id.isEmpty ? 'new_${DateTime.now().microsecondsSinceEpoch}_$index' : phase.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(phase.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (phase.deadline != null)
                              Text('Deadline: ${DateFormatter.formatDate(phase.deadline!)}'),
                            if (phase.description != null && phase.description!.isNotEmpty)
                              Text(
                                phase.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () => _editPhase(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _deletePhase(index),
                            ),
                            const Icon(Icons.drag_handle, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _PhaseEditDialog extends StatefulWidget {
  final PhaseModel phase;

  const _PhaseEditDialog({required this.phase});

  @override
  State<_PhaseEditDialog> createState() => _PhaseEditDialogState();
}

class _PhaseEditDialogState extends State<_PhaseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime? _deadline;

  late bool _requireText;
  late bool _requireFile;
  late bool _requireImage;
  late bool _requireLink;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.phase.title == 'New Phase' ? '' : widget.phase.title);
    _descCtrl = TextEditingController(text: widget.phase.description ?? '');
    _deadline = widget.phase.deadline;
    _requireText = widget.phase.requireText;
    _requireFile = widget.phase.requireFile;
    _requireImage = widget.phase.requireImage;
    _requireLink = widget.phase.requireLink;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Phase'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Phase Title *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('What should student submit?', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Text / Notes'),
                value: _requireText,
                onChanged: (v) => setState(() => _requireText = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('PDF / Document'),
                value: _requireFile,
                onChanged: (v) => setState(() => _requireFile = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Image Upload'),
                value: _requireImage,
                onChanged: (v) => setState(() => _requireImage = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Link / URL'),
                value: _requireLink,
                onChanged: (v) => setState(() => _requireLink = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_deadline == null
                    ? 'Select Deadline *'
                    : 'Deadline: ${DateFormatter.formatDate(_deadline!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                subtitle: _deadline == null
                    ? const Text('Required', style: TextStyle(color: AppColors.error, fontSize: 12))
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _deadline != null) {
              final updatedPhase = widget.phase.copyWith(
                title: _titleCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                deadline: _deadline,
                requireText: _requireText,
                requireFile: _requireFile,
                requireImage: _requireImage,
                requireLink: _requireLink,
              );
              Navigator.pop(context, updatedPhase);
            } else if (_deadline == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a deadline.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
