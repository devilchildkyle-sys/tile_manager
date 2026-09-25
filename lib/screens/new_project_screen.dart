import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'project_overview_screen.dart';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});
  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _nameCtrl    = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  int _baths = 1, _muds = 0, _laundry = 0, _others = 0;

  @override
  void dispose() {
    _nameCtrl.dispose(); _contactCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  void _create() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final state = context.read<AppState>();
    final proj = Project(
      id: state.newProjectId(),
      name: _nameCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      bathrooms: List.generate(_baths, (i) => Bathroom(
          id: state.newRoomId(), name: 'Bath ${i + 1}')),
      mudRooms: List.generate(_muds, (i) => Room(
          id: state.newRoomId(), name: 'Mud Room ${i + 1}')),
      laundryRooms: List.generate(_laundry, (i) => Room(
          id: state.newRoomId(), name: 'Laundry ${i + 1}')),
      others: List.generate(_others, (i) => Room(
          id: state.newRoomId(), name: 'Room ${i + 1}')),
    );
    state.addProject(proj);
    Navigator.pop(context);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProjectOverviewScreen(project: proj)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('New Project')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Project Info'),
        AppInput(label: 'Project / Client Name', controller: _nameCtrl,
            hint: 'e.g. Johnson Master Bath'),
        const SizedBox(height: 12),
        AppInput(label: 'Contact #', controller: _contactCtrl,
            hint: '555-123-4567'),
        const SizedBox(height: 12),
        AppInput(label: 'Address', controller: _addressCtrl,
            hint: '123 Main St, City'),
      ])),
      const SizedBox(height: 8),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Rooms'),
        const SizedBox(height: 8),
        StepCounter(label: 'Bathrooms',  value: _baths,   onChanged: (v) => setState(() => _baths = v)),
        const SizedBox(height: 10),
        StepCounter(label: 'Mud Rooms',  value: _muds,    onChanged: (v) => setState(() => _muds = v)),
        const SizedBox(height: 10),
        StepCounter(label: 'Laundry',    value: _laundry, onChanged: (v) => setState(() => _laundry = v)),
        const SizedBox(height: 10),
        StepCounter(label: 'Other',      value: _others,  onChanged: (v) => setState(() => _others = v)),
      ])),
      const SizedBox(height: 16),
      PrimaryButton(label: 'Create Project', onTap: _nameCtrl.text.trim().isEmpty ? null : _create),
    ]),
    // rebuild button when name changes
    bottomNavigationBar: ValueListenableBuilder(
      valueListenable: _nameCtrl,
      builder: (_, __, ___) => Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
        child: PrimaryButton(
          label: 'Create Project',
          onTap: _nameCtrl.text.trim().isEmpty ? null : _create,
        ),
      ),
    ),
  );
}
