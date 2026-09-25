import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/calculations.dart';
import '../widgets/common_widgets.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  final Function(Room) onUpdate;
  final List<LaborRate> rates;
  final MaterialPrices materials;

  const RoomDetailScreen({super.key, required this.room, required this.onUpdate,
      required this.rates, required this.materials});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Room _room;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
  }

  void _upd(Room r) {
    setState(() => _room = r);
    widget.onUpdate(r);
  }

  @override
  Widget build(BuildContext context) {
    final bd = calcRoomBreakdown(_room, widget.rates, widget.materials);
    final fSqFt = double.tryParse(_room.floor.sqFt) ?? 0;
    final active = [_room.floor.floorMat, _room.floor.heatMat,
        _room.floor.raised, _room.floor.selfLevel].where((b) => b).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_room.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('\$${bd.total.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.accent, fontSize: 12)),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        // Floor
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Floor'),
          AppInput(label: 'Sq Ft', isNumber: true,
              value: _room.floor.sqFt,
              onChanged: (v) { _room.floor.sqFt = v; _upd(_room); }),
          if (fSqFt > 0) ...[
            const SizedBox(height: 12),
            DifficultyPicker(label: 'Floor Difficulty',
                value: _room.floor.difficulty, rates: widget.rates, rateId: 'floor',
                onChanged: (d) { _room.floor.difficulty = d; _upd(_room); }),
            const SizedBox(height: 12),
            const FieldLabel('Floor Options'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ToggleChip(label: '🧱 Floor Mat', value: _room.floor.floorMat,
                  onChanged: (v) { _room.floor.floorMat = v; _upd(_room); }),
              ToggleChip(label: '🔥 Heat Mat', value: _room.floor.heatMat,
                  onChanged: (v) { _room.floor.heatMat = v; _upd(_room); },
                  activeColor: AppColors.danger),
              ToggleChip(label: '⬆ ¼" Board', value: _room.floor.raised,
                  onChanged: (v) { _room.floor.raised = v; _upd(_room); }),
              ToggleChip(label: '📐 Self Level', value: _room.floor.selfLevel,
                  onChanged: (v) { _room.floor.selfLevel = v; _upd(_room); }),
            ]),
            if (_room.floor.heatMat) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3))),
                  child: Row(children: [
                    const Text('🔥 '),
                    Text('Heat install upcharge: +\$${widget.rates.where((r) => r.id == 'heatedUpcharge').firstOrNull?.rate.toStringAsFixed(0) ?? '300'}/install',
                        style: const TextStyle(color: AppColors.danger,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ])),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border)),
                  child: const Row(children: [
                    Text('🔌 '),
                    Expanded(child: Text('Heat Wire — pricing coming soon',
                        style: TextStyle(color: AppColors.muted, fontSize: 11))),
                  ])),
            ],
            if (active >= 2) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('📐 Multi-prep: +\$${widget.rates.where((r) => r.id == 'multiPrepUpcharge').firstOrNull?.rate.toStringAsFixed(0) ?? '1'}/sqft',
                      style: const TextStyle(color: AppColors.purple,
                          fontSize: 12, fontWeight: FontWeight.w700))),
            ],
            const SizedBox(height: 10),
            GroutSectionWidget(surfaceLabel: 'Floor',
                data: _room.floor.grout, groutPrice: widget.materials.groutPrice,
                onChanged: (g) { _room.floor.grout = g; _upd(_room); }),
          ],
        ])),

        // Walls
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Walls'),
          AppInput(label: 'Sq Ft', isNumber: true,
              value: _room.walls.sqFt,
              onChanged: (v) { _room.walls.sqFt = v; _upd(_room); }),
          if ((double.tryParse(_room.walls.sqFt) ?? 0) > 0) ...[
            const SizedBox(height: 12),
            DifficultyPicker(label: 'Wall Difficulty',
                value: _room.walls.difficulty, rates: widget.rates, rateId: 'wall',
                onChanged: (d) { _room.walls.difficulty = d; _upd(_room); }),
            const SizedBox(height: 10),
            GroutSectionWidget(surfaceLabel: 'Walls',
                data: _room.walls.grout, groutPrice: widget.materials.groutPrice,
                onChanged: (g) { _room.walls.grout = g; _upd(_room); }),
          ],
        ])),

        // Base
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Base'),
          AppInput(label: 'Lin Ft', isNumber: true,
              value: _room.base.linFt,
              onChanged: (v) { _room.base.linFt = v; _upd(_room); }),
          if ((double.tryParse(_room.base.linFt) ?? 0) > 0) ...[
            const SizedBox(height: 10),
            DifficultyPicker(label: 'Base Difficulty',
                value: _room.base.difficulty, rates: widget.rates, rateId: 'base',
                onChanged: (d) { _room.base.difficulty = d; _upd(_room); }),
          ],
        ])),
        const SizedBox(height: 24),
      ]),
    );
  }
}
