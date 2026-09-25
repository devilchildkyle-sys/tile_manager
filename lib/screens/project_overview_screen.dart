import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/calculations.dart';
import '../utils/share_utils.dart';
import '../widgets/common_widgets.dart';
import 'bath_detail_screen.dart';
import 'room_detail_screen.dart';

class ProjectOverviewScreen extends StatefulWidget {
  final Project project;
  const ProjectOverviewScreen({super.key, required this.project});
  @override
  State<ProjectOverviewScreen> createState() => _ProjectOverviewScreenState();
}

class _ProjectOverviewScreenState extends State<ProjectOverviewScreen> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  void _refresh() {
    final state = context.read<AppState>();
    setState(() {
      _project = state.projects.firstWhere((p) => p.id == _project.id,
          orElse: () => _project);
    });
  }

  Future<void> _share(ProjectBreakdown bd) async {
    final text = generateShareText(_project, bd);
    try {
      await Share.share(text, subject: 'Estimate — ${_project.name}');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estimate copied to clipboard!')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(context,
        title: 'Delete Project?',
        message: '"${_project.name}" and all its data will be permanently removed.',
        confirmLabel: 'Delete');
    if (confirmed && mounted) {
      context.read<AppState>().deleteProject(_project.id);
      Navigator.pop(context);
    }
  }

  void _addRoom(String type) {
    final state = context.read<AppState>();
    final id = state.newRoomId();
    if (type == 'bath') {
      _project.bathrooms.add(Bathroom(
          id: id, name: 'Bath ${_project.bathrooms.length + 1}'));
    } else if (type == 'mud') {
      _project.mudRooms.add(Room(
          id: id, name: 'Mud Room ${_project.mudRooms.length + 1}'));
    } else if (type == 'laundry') {
      _project.laundryRooms.add(Room(
          id: id, name: 'Laundry ${_project.laundryRooms.length + 1}'));
    } else {
      _project.others.add(Room(
          id: id, name: 'Room ${_project.others.length + 1}'));
    }
    state.updateProject(_project);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bd    = calcProjectBreakdown(_project, state.rates, state.materials);
    final tots  = calcProjectFootage(_project);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_project.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('${_project.createdAt.month}/${_project.createdAt.day}/${_project.createdAt.year}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ]),
        actions: [
          // Materials
          IconButton(icon: const Text('📦', style: TextStyle(fontSize: 18)),
              onPressed: () => _showMaterialList(context, state, bd)),
          // Share
          IconButton(icon: const Icon(Icons.ios_share_outlined, color: AppColors.teal),
              onPressed: () => _share(bd)),
          // Delete
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _delete),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        // Total card
        GestureDetector(
          onTap: () => _showBreakdown(context, bd),
          child: AppCard(child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ESTIMATED TOTAL', style: TextStyle(color: AppColors.muted,
                  fontSize: 10, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text('\$${bd.total.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.accent,
                      fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                Text('Labor  \$${bd.labor.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(width: 16),
                Text('Mat  \$${bd.materials.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.teal, fontSize: 12)),
              ]),
            ])),
            const Column(children: [
              Icon(Icons.chevron_right, color: AppColors.muted),
              Text('breakdown', style: TextStyle(color: AppColors.muted, fontSize: 9)),
            ]),
          ])),
        ),

        // Footage
        const SectionTitle('Footage Summary'),
        GridView.count(crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.8,
            children: [
              StatTile(label: 'Floor', value: tots.floor.toStringAsFixed(1),
                  unit: 'sq ft', color: AppColors.accent),
              StatTile(label: 'Walls', value: tots.walls.toStringAsFixed(1),
                  unit: 'sq ft', color: AppColors.blue),
              StatTile(label: 'Ceiling', value: tots.ceiling.toStringAsFixed(1),
                  unit: 'sq ft', color: AppColors.purple),
              StatTile(label: 'Base', value: tots.base.toStringAsFixed(1),
                  unit: 'lin ft', color: AppColors.success),
            ]),
        const SizedBox(height: 16),

        // Bathrooms
        if (_project.bathrooms.isNotEmpty) ...[
          const SectionTitle('🛁 Bathrooms'),
          ..._project.bathrooms.map((b) => _RoomCard(
            name: b.name,
            tags: _bathTags(b),
            total: _bathTotal(b, state),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BathDetailScreen(bath: b,
                      onUpdate: (updated) {
                        final idx = _project.bathrooms.indexWhere((x) => x.id == b.id);
                        if (idx >= 0) _project.bathrooms[idx] = updated;
                        state.updateProject(_project);
                        setState(() {});
                      },
                      rates: state.rates, materials: state.materials)));
            },
            onDelete: () async {
              final ok = await showConfirmDialog(context,
                  title: 'Delete ${b.name}?',
                  message: 'This room will be permanently removed.',
                  confirmLabel: 'Delete');
              if (ok && mounted) {
                _project.bathrooms.removeWhere((x) => x.id == b.id);
                state.updateProject(_project);
                setState(() {});
              }
            },
          )),
        ],

        // Other rooms
        ..._roomSection('👟 Mud Rooms', _project.mudRooms, state),
        ..._roomSection('🧺 Laundry', _project.laundryRooms, state),
        ..._roomSection('📦 Other Rooms', _project.others, state),

        const SizedBox(height: 12),
        // Add room button
        OutlinedButton.icon(
          onPressed: () => _showAddRoom(context),
          icon: const Icon(Icons.add, color: AppColors.accent),
          label: const Text('Add Room', style: TextStyle(color: AppColors.accent)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  List<Widget> _roomSection(String title, List<Room> rooms, AppState state) {
    if (rooms.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      SectionTitle(title),
      ...rooms.map((r) => _RoomCard(
        name: r.name,
        tags: [Tag('${r.floor.sqFt} floor sqft')],
        total: calcRoomBreakdown(r, state.rates, state.materials).total,
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => RoomDetailScreen(room: r,
                  onUpdate: (updated) {
                    final list = rooms;
                    final idx = list.indexWhere((x) => x.id == r.id);
                    if (idx >= 0) list[idx] = updated;
                    state.updateProject(_project);
                    setState(() {});
                  },
                  rates: state.rates, materials: state.materials)));
        },
        onDelete: () async {
          final ok = await showConfirmDialog(context,
              title: 'Delete ${r.name}?',
              message: 'This room will be permanently removed.',
              confirmLabel: 'Delete');
          if (ok && mounted) {
            rooms.removeWhere((x) => x.id == r.id);
            state.updateProject(_project);
            setState(() {});
          }
        },
      )),
    ];
  }

  double _bathTotal(Bathroom b, AppState state) {
    final bd = calcBathroomBreakdown(b, state.rates, state.materials);
    return bd.total;
  }

  List<Widget> _bathTags(Bathroom b) {
    final tags = <Widget>[];
    final panSqFt = b.pan.enabled ? (double.tryParse(b.pan.widthIn) ?? 0) *
        (double.tryParse(b.pan.lengthIn) ?? 0) / 144 : 0.0;
    final floor = (double.tryParse(b.floor.sqFt) ?? 0) + panSqFt;
    if (floor > 0) tags.add(Tag('${floor.toStringAsFixed(1)} floor'));
    if ((double.tryParse(b.walls.sqFt) ?? 0) > 0)
      tags.add(Tag('${b.walls.sqFt} walls', color: AppColors.blue));
    if (b.pan.steamShower) tags.add(const Tag('Steam', color: AppColors.teal));
    if (b.floor.heatMat)   tags.add(const Tag('Heated', color: AppColors.danger));
    return tags;
  }

  void _showAddRoom(BuildContext context) {
    showModalBottomSheet(context: context,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Add Room', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            ...{
              'bath': ('🛁', 'Bathroom'), 'mud': ('👟', 'Mud Room'),
              'laundry': ('🧺', 'Laundry'), 'other': ('📦', 'Other'),
            }.entries.map((e) => ListTile(
              leading: Text(e.value.$1, style: const TextStyle(fontSize: 22)),
              title: Text(e.value.$2),
              onTap: () { Navigator.pop(context); _addRoom(e.key); },
            )),
          ]),
        ));
  }

  void _showBreakdown(BuildContext context, ProjectBreakdown bd) {
    showModalBottomSheet(context: context,
        backgroundColor: AppColors.card,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(
          expand: false, initialChildSize: 0.75, maxChildSize: 0.95,
          builder: (_, ctrl) => ListView(controller: ctrl,
              padding: const EdgeInsets.all(20), children: [
            const Text('Cost Breakdown', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            ...bd.rooms.map((room) => Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.name, style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.w700)),
              const Divider(color: AppColors.border),
              if (room.laborLines.isNotEmpty) ...[
                const Text('Labor', style: TextStyle(color: AppColors.muted,
                    fontSize: 11, fontWeight: FontWeight.w600)),
                ...room.laborLines.map((l) => CostRow(
                    label: '${l.label}${l.difficulty != null ? ' (${l.difficulty})' : ''}',
                    amount: l.cost)),
              ],
              if (room.matLines.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Text('Materials', style: TextStyle(color: AppColors.muted,
                    fontSize: 11, fontWeight: FontWeight.w600)),
                ...room.matLines.map((l) => CostRow(label: l.label, amount: l.cost,
                    color: AppColors.teal)),
              ],
              CostRow(label: '${room.name} Total', amount: room.total,
                  bold: true, color: AppColors.accent),
              const SizedBox(height: 12),
            ])),
            const Divider(color: AppColors.border, thickness: 2),
            CostRow(label: 'Labor', amount: bd.labor, bold: true),
            CostRow(label: 'Materials', amount: bd.materials,
                bold: true, color: AppColors.teal),
            const Divider(color: AppColors.border),
            CostRow(label: 'TOTAL', amount: bd.total,
                bold: true, color: AppColors.accent),
          ]),
        ));
  }

  void _showMaterialList(BuildContext context, AppState state, ProjectBreakdown bd) {
    final M  = state.materials;
    final ms = calcMaterialSummary(_project, state.rates, M);

    showModalBottomSheet(context: context,
        backgroundColor: AppColors.card,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(
          expand: false, initialChildSize: 0.75, maxChildSize: 0.95,
          builder: (_, ctrl) => ListView(controller: ctrl,
              padding: const EdgeInsets.all(20), children: [
            const Text('📦 Material List', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            _matSection('🪣 Thin Set', [
              if (ms.thinsetFloor > 0) _MatRow('Floor',
                  '${ms.thinsetFloor.toInt()} bags', ms.thinsetFloor * M.thinsetPrice),
              if (ms.thinsetWall > 0) _MatRow('Walls / Ceiling',
                  '${ms.thinsetWall.toInt()} bags', ms.thinsetWall * M.thinsetPrice),
            ]),
            _matSection('🟡 Grout', [
              if (ms.grout > 0) _MatRow('All surfaces',
                  '${ms.grout.toInt()} bags', ms.grout * M.groutPrice),
            ]),
            _matSection('💧 Waterproofing', [
              if (ms.membrane > 0) _MatRow('Wall Membrane',
                  '${ms.membrane.toStringAsFixed(1)} sqft', ms.membrane * M.wallMembranePrice),
              if (ms.foamBoard > 0) _MatRow('½" Foam Board',
                  '${ms.foamBoard.toStringAsFixed(1)} sqft', ms.foamBoard * M.halfInchFoamPrice),
            ]),
            _matSection('🛁 Foam Pan Liners',
              ms.foamPans.entries.where((e) => e.value > 0).map((e) =>
                  _MatRow(e.key, '${e.value} pc', e.value * (M.foamPanPrices[e.key] ?? 0))).toList()),
            _matSection('🔥 Floor Materials', [
              if (ms.floorMat > 0) _MatRow('Floor Mat',
                  '${ms.floorMat.toStringAsFixed(1)} sqft', ms.floorMat * M.floorMatPrice),
              if (ms.heatMat > 0) _MatRow('Heat Mat (${ms.heatInstalls} install)',
                  '${ms.heatMat.toStringAsFixed(1)} sqft', ms.heatMat * M.heatMatPrice),
              if (ms.selfLevel > 0) _MatRow('Self Leveler',
                  '${ms.selfLevel.toStringAsFixed(1)} sqft', ms.selfLevel * M.selfLevelPrice),
              if (ms.raisedFloorSqFt > 0) _MatRow(
                  '¼" Cement Board (~${(ms.raisedFloorSqFt / 15).ceil()} sheets)',
                  '${ms.raisedFloorSqFt.toStringAsFixed(1)} sqft',
                  (ms.raisedFloorSqFt / 15).ceil() * M.quarterInchBoardPrice),
            ]),
            _matSection('📐 2" Board (Bench/Curb)', [
              if (ms.boardSheets > 0) _MatRow('Sheets needed',
                  ms.boardSheets % 1 == 0 ? '${ms.boardSheets.toInt()} sheets'
                      : '${ms.boardSheets.toStringAsFixed(2)} sheets',
                  ms.boardSheets * M.twoInchBoardPrice),
            ]),
            _matSection('🕳 Drains', [
              if (ms.drainStandard > 0) _MatRow('Standard Grate',
                  '${ms.drainStandard} pc', ms.drainStandard * M.drainStandardPrice),
              if (ms.drainTile > 0) _MatRow('Tile Grate',
                  '${ms.drainTile} pc', ms.drainTile * M.drainTileGratePrice),
            ]),
            _matSection('◻ Niches', [
              if (ms.nichesStd > 0) _MatRow('Standard',
                  '${ms.nichesStd} pc', ms.nichesStd * M.nicheStdPrice),
              if (ms.nichesCustom > 0) _MatRow('Custom',
                  '${ms.nichesCustom} pc', ms.nichesCustom * M.nicheCustomPrice),
            ]),
            _matSection('📐 Metal Edge', [
              if (ms.metalEdgeSticks > 0) _MatRow('8ft sticks',
                  '${ms.metalEdgeSticks} sticks', ms.metalEdgeSticks * M.metalEdgePrice),
            ]),
            const Divider(color: AppColors.border, thickness: 2),
            CostRow(label: 'Total Materials', amount: bd.materials,
                bold: true, color: AppColors.teal),
            const SizedBox(height: 24),
          ]),
        ));
  }

  Widget _matSection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.muted,
          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      ...rows,
      const SizedBox(height: 12),
    ]);
  }

  Widget _MatRow(String label, String qty, double cost) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 14, color: AppColors.text))),
      Text(qty, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(width: 12),
      Text('\$${cost.toStringAsFixed(2)}',
          style: const TextStyle(color: AppColors.accent,
              fontWeight: FontWeight.w700, fontSize: 14)),
    ]),
  );
}

// ─── Room Card ────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final String name;
  final List<Widget> tags;
  final double total;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _RoomCard({required this.name, required this.tags,
      required this.total, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(name, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15)),
          Text('\$${total.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
        ]),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: tags),
        ],
      ])),
      const SizedBox(width: 4),
      if (onDelete != null)
        GestureDetector(
          onTap: onDelete,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
          ),
        ),
      const Icon(Icons.chevron_right, color: AppColors.muted),
    ]),
  );
}
