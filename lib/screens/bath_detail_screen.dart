import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/calculations.dart';
import '../widgets/common_widgets.dart';

class BathDetailScreen extends StatefulWidget {
  final Bathroom bath;
  final Function(Bathroom) onUpdate;
  final List<LaborRate> rates;
  final MaterialPrices materials;

  const BathDetailScreen({super.key, required this.bath, required this.onUpdate,
      required this.rates, required this.materials});

  @override
  State<BathDetailScreen> createState() => _BathDetailScreenState();
}

class _BathDetailScreenState extends State<BathDetailScreen> {
  late Bathroom _bath;
  late List<LaborRate> _rates;
  late MaterialPrices _mats;
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _bath = widget.bath;
    _rates = widget.rates;
    _mats = widget.materials;
    _scrollCtrl = ScrollController(initialScrollOffset: 0);
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  void _upd(Bathroom b) {
    setState(() => _bath = b);
    widget.onUpdate(b);
  }

  double get _labor => calcBathroomBreakdown(_bath, _rates, _mats).labor;
  double get _matCost => calcBathroomBreakdown(_bath, _rates, _mats).materials;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_bath.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Row(children: [
          Text('Labor \$${_labor.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.accent, fontSize: 12)),
          const Text(' Â· ', style: TextStyle(color: AppColors.muted)),
          Text('Mat \$${_matCost.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.teal, fontSize: 12)),
        ]),
      ]),
    ),
    body: ListView(controller: _scrollCtrl, padding: const EdgeInsets.all(14), children: [
      // Room name
      AppCard(child: AppInput(
          label: 'Room Name',
          value: _bath.name,
          onChanged: (v) => _upd(_bath..name = v))),

      // Shower / Pan
      _CollapsibleSection(
        title: 'Shower / Pan',
        headerTrailing: Switch(value: _bath.pan.enabled, activeColor: AppColors.teal,
            onChanged: (v) { _bath.pan.enabled = v; _upd(_bath); }),
        content: _bath.pan.enabled
            ? _PanContent(bath: _bath, rates: _rates, mats: _mats, onUpdate: _upd)
            : const _DisabledHint('Toggle on to configure shower / pan'),
      ),

      // Tub
      _CollapsibleSection(
        title: 'Tub',
        headerTrailing: Switch(value: _bath.tub.enabled, activeColor: AppColors.teal,
            onChanged: (v) { _bath.tub.enabled = v; _upd(_bath); }),
        content: _bath.tub.enabled
            ? _TubContent(bath: _bath, rates: _rates, mats: _mats, onUpdate: _upd)
            : const _DisabledHint('Toggle on to configure tub'),
      ),

      // Floor
      _CollapsibleSection(
        title: 'Floor',
        content: _FloorContent(bath: _bath, rates: _rates, mats: _mats, onUpdate: _upd),
      ),

      // Walls
      _CollapsibleSection(
        title: 'Walls',
        content: _SurfaceContent(
            title: 'Walls', sqFt: _bath.walls.sqFt,
            difficulty: _bath.walls.difficulty, rateId: 'wall',
            grout: _bath.walls.grout, groutPrice: _mats.groutPrice, rates: _rates,
            onSqFtChanged: (v) => _upd(_bath..walls.sqFt = v),
            onDiffChanged: (d) => _upd(_bath..walls.difficulty = d),
            onGroutChanged: (g) => _upd(_bath..walls.grout = g)),
      ),

      // Ceiling
      _CollapsibleSection(
        title: 'Ceiling',
        content: _SurfaceContent(
            title: 'Ceiling', sqFt: _bath.ceiling.sqFt,
            difficulty: _bath.ceiling.difficulty, rateId: 'ceiling',
            grout: _bath.ceiling.grout, groutPrice: _mats.groutPrice, rates: _rates,
            onSqFtChanged: (v) => _upd(_bath..ceiling.sqFt = v),
            onDiffChanged: (d) => _upd(_bath..ceiling.difficulty = d),
            onGroutChanged: (g) => _upd(_bath..ceiling.grout = g)),
      ),

      // Wainscot
      _CollapsibleSection(
        title: 'Wainscot',
        content: _SurfaceContent(
            title: 'Wainscot', sqFt: _bath.wainscot.sqFt,
            difficulty: _bath.wainscot.difficulty, rateId: 'wainscot',
            grout: _bath.wainscot.grout, groutPrice: _mats.groutPrice, rates: _rates,
            onSqFtChanged: (v) => _upd(_bath..wainscot.sqFt = v),
            onDiffChanged: (d) => _upd(_bath..wainscot.difficulty = d),
            onGroutChanged: (g) => _upd(_bath..wainscot.grout = g)),
      ),

      // Base
      _CollapsibleSection(
        title: 'Base',
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppInput(label: 'Lin Ft', isNumber: true,
              value: _bath.base.linFt,
              onChanged: (v) => _upd(_bath..base.linFt = v)),
          if (_bath.base.linFt.isNotEmpty && (double.tryParse(_bath.base.linFt) ?? 0) > 0) ...[
            const SizedBox(height: 10),
            DifficultyPicker(label: 'Base Difficulty', value: _bath.base.difficulty,
                rates: _rates, rateId: 'base',
                onChanged: (d) => _upd(_bath..base.difficulty = d)),
          ],
        ]),
      ),

      // Edging
      _CollapsibleSection(
        title: 'Edging',
        headerTrailing: Switch(value: _bath.edging.enabled, activeColor: AppColors.accent,
            onChanged: (v) { _bath.edging.enabled = v; _upd(_bath); }),
        content: _bath.edging.enabled
            ? _EdgeContent(bath: _bath, rates: _rates, onUpdate: _upd)
            : const _DisabledHint('Toggle on to configure edging'),
      ),

      const SizedBox(height: 24),
    ]),
  );
}

// â”€â”€â”€ Collapsible Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget content;
  final Widget? headerTrailing;

  const _CollapsibleSection({required this.title, required this.content,
      this.headerTrailing});

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _open = !_open),
        child: Row(children: [
          Expanded(child: Text(widget.title.toUpperCase(),
              style: const TextStyle(color: AppColors.muted, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 0.8))),
          if (widget.headerTrailing != null) widget.headerTrailing!,
          const SizedBox(width: 4),
          Icon(_open ? Icons.expand_less : Icons.expand_more,
              color: AppColors.muted, size: 20),
        ]),
      ),
      if (_open) ...[
        const SizedBox(height: 12),
        widget.content,
      ],
    ]),
  );
}

// â”€â”€â”€ Disabled Hint â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DisabledHint extends StatelessWidget {
  final String text;
  const _DisabledHint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 2),
    child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
  );
}

// â”€â”€â”€ Floor Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FloorContent extends StatelessWidget {
  final Bathroom bath;
  final List<LaborRate> rates;
  final MaterialPrices mats;
  final Function(Bathroom) onUpdate;
  const _FloorContent({required this.bath, required this.rates,
      required this.mats, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final f = bath.floor;
    final active = [f.floorMat, f.heatMat, f.raised, f.selfLevel].where((b) => b).length;
    final sqft = double.tryParse(f.sqFt) ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppInput(label: 'Sq Ft', isNumber: true,
          value: f.sqFt,
          onChanged: (v) { bath.floor.sqFt = v; onUpdate(bath); }),
      if (sqft > 0) ...[
        const SizedBox(height: 12),
        DifficultyPicker(label: 'Floor Difficulty', value: f.difficulty,
            rates: rates, rateId: 'floor',
            onChanged: (d) { bath.floor.difficulty = d; onUpdate(bath); }),
        const SizedBox(height: 12),
        const FieldLabel('Floor Options'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ToggleChip(label: 'ðŸ§± Floor Mat', value: f.floorMat,
              onChanged: (v) { bath.floor.floorMat = v; onUpdate(bath); }),
          ToggleChip(label: 'ðŸ”¥ Heat Mat', value: f.heatMat,
              onChanged: (v) { bath.floor.heatMat = v; onUpdate(bath); },
              activeColor: AppColors.danger),
          ToggleChip(label: 'â¬† Â¼" Board', value: f.raised,
              onChanged: (v) { bath.floor.raised = v; onUpdate(bath); }),
          ToggleChip(label: 'ðŸ“ Self Level', value: f.selfLevel,
              onChanged: (v) { bath.floor.selfLevel = v; onUpdate(bath); }),
        ]),
        if (f.heatMat) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3))),
              child: Row(children: [
                const Text('ðŸ”¥ ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text(
                    'Heated upcharge: +\$${rates.where((r) => r.id == 'heatedUpcharge').firstOrNull?.rate.toStringAsFixed(0) ?? '300'}/install',
                    style: const TextStyle(color: AppColors.danger,
                        fontSize: 12, fontWeight: FontWeight.w700))),
              ])),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border)),
              child: const Row(children: [
                Text('ðŸ”Œ ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text(
                    'Heat Wire â€” pricing coming soon Â· more info needed Â· note qty manually for now',
                    style: TextStyle(color: AppColors.muted, fontSize: 11))),
              ])),
        ],
        if (active >= 2) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.purple.withOpacity(0.3))),
              child: Text(
                  'ðŸ“ Multi-prep upcharge: +\$${rates.where((r) => r.id == 'multiPrepUpcharge').firstOrNull?.rate.toStringAsFixed(0) ?? '1'}/sqft ($active layers)',
                  style: const TextStyle(color: AppColors.purple,
                      fontSize: 12, fontWeight: FontWeight.w700))),
        ],
        const SizedBox(height: 10),
        GroutSectionWidget(surfaceLabel: 'Floor',
            data: f.grout, groutPrice: mats.groutPrice,
            onChanged: (g) { bath.floor.grout = g; onUpdate(bath); }),
      ],
    ]);
  }
}

// â”€â”€â”€ Pan / Shower Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PanContent extends StatelessWidget {
  final Bathroom bath;
  final List<LaborRate> rates;
  final MaterialPrices mats;
  final Function(Bathroom) onUpdate;
  const _PanContent({required this.bath, required this.rates,
      required this.mats, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final p = bath.pan;
    final panSqFt = (double.tryParse(p.widthIn) ?? 0) *
        (double.tryParse(p.lengthIn) ?? 0) / 144;
    final swSqFt = double.tryParse(p.showerWallsSqFt) ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: AppInput(label: 'Width (in)', isNumber: true,
            value: p.widthIn,
            onChanged: (v) { bath.pan.widthIn = v; onUpdate(bath); })),
        const SizedBox(width: 8),
        Expanded(child: AppInput(label: 'Length (in)', isNumber: true,
            value: p.lengthIn,
            onChanged: (v) { bath.pan.lengthIn = v; onUpdate(bath); })),
      ]),
      if (panSqFt > 0)
        Padding(padding: const EdgeInsets.only(top: 4),
            child: Text('Pan: ${panSqFt.toStringAsFixed(2)} sq ft',
                style: const TextStyle(color: AppColors.accent, fontSize: 12))),
      const SizedBox(height: 12),
      const FieldLabel('Foam Pan Liner Size'),
      Wrap(spacing: 8, runSpacing: 6, children: ['3x3','3x5','5x5','6x6'].map((size) {
        final sel = p.foamPanSize == size;
        return GestureDetector(
          onTap: () { bath.pan.foamPanSize = size; onUpdate(bath); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AppColors.accent : AppColors.border),
            ),
            child: Text('$size â€” \$${mats.foamPanPrices[size]?.toStringAsFixed(0) ?? '-'}',
                style: TextStyle(color: sel ? Colors.black : AppColors.muted,
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        );
      }).toList()),
      const SizedBox(height: 12),
      DifficultyPicker(label: 'Shower Floor Difficulty', value: p.floorDifficulty,
          rates: rates, rateId: 'showerFloor',
          onChanged: (d) { bath.pan.floorDifficulty = d; onUpdate(bath); }),
      const SizedBox(height: 12),
      AppInput(label: 'Shower Walls Sq Ft', isNumber: true,
          value: p.showerWallsSqFt,
          onChanged: (v) { bath.pan.showerWallsSqFt = v; onUpdate(bath); }),
      if (swSqFt > 0) ...[
        const SizedBox(height: 12),
        DifficultyPicker(label: 'Shower Wall Difficulty', value: p.wallDifficulty,
            rates: rates, rateId: 'showerWall',
            onChanged: (d) { bath.pan.wallDifficulty = d; onUpdate(bath); }),
      ],
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Steam Shower', style: TextStyle(fontWeight: FontWeight.w600)),
        Switch(value: p.steamShower, activeColor: AppColors.teal,
            onChanged: (v) { bath.pan.steamShower = v; onUpdate(bath); }),
      ]),
      const SizedBox(height: 10),
      const FieldLabel('Wall Waterproofing'),
      Row(children: [
        ...[('membrane','Membrane'),('foam','Â½" Foam'),('none','None')].map((opt) {
          final sel = p.waterproofType == opt.$1;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () { bath.pan.waterproofType = opt.$1; onUpdate(bath); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.teal : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppColors.teal : AppColors.border),
                ),
                child: Text(opt.$2, textAlign: TextAlign.center,
                    style: TextStyle(color: sel ? Colors.black : AppColors.muted,
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ));
        }),
      ]),
      if (p.waterproofType == 'membrane') ...[
        const SizedBox(height: 10),
        AppInput(label: 'Shower Perimeter Lin Ft', isNumber: true,
            value: p.showerLinFt,
            onChanged: (v) { bath.pan.showerLinFt = v; onUpdate(bath); }),
        if ((double.tryParse(p.showerLinFt) ?? 0) > 0)
          Padding(padding: const EdgeInsets.only(top: 4),
              child: Text('${p.showerLinFt} lf Ã— 6ft = ${((double.tryParse(p.showerLinFt) ?? 0) * 6).toStringAsFixed(1)} sqft membrane',
                  style: const TextStyle(color: AppColors.teal, fontSize: 11))),
      ],
      if (p.waterproofType == 'foam') ...[
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface,
                borderRadius: BorderRadius.circular(10)),
            child: Text('Â½" foam walls: ${swSqFt.toStringAsFixed(1)} sqft'
                '${p.steamShower && (double.tryParse(bath.ceiling.sqFt) ?? 0) > 0 ? ' + ${bath.ceiling.sqFt} ceiling (steam)' : ''}'
                ' = \$${((swSqFt + (p.steamShower ? (double.tryParse(bath.ceiling.sqFt) ?? 0) : 0)) * mats.halfInchFoamPrice).toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.teal, fontSize: 12))),
      ],
      const SizedBox(height: 12),
      const FieldLabel('Drain Type'),
      Row(children: [('standard','Standard  \$${mats.drainStandardPrice.toStringAsFixed(0)}'),
          ('tile','Tile Grate  \$${mats.drainTileGratePrice.toStringAsFixed(0)}')].map((opt) {
        final sel = p.drainType == opt.$1;
        return Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () { bath.pan.drainType = opt.$1; onUpdate(bath); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? AppColors.accent : AppColors.border),
              ),
              child: Text(opt.$2, textAlign: TextAlign.center,
                  style: TextStyle(color: sel ? Colors.black : AppColors.muted,
                      fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ));
      }).toList()),
      const SizedBox(height: 12),
      StepCounter(label: 'Shelves',
          value: int.tryParse(p.shelves) ?? 0,
          onChanged: (v) { bath.pan.shelves = v.toString(); onUpdate(bath); }),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Standard Niches'),
          AppInput(isNumber: true, value: p.niches,
              onChanged: (v) { bath.pan.niches = v; onUpdate(bath); }),
        ])),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Custom Niches'),
          AppInput(isNumber: true, value: p.customNiches,
              onChanged: (v) { bath.pan.customNiches = v; onUpdate(bath); }),
        ])),
      ]),
      const SizedBox(height: 12),
      const FieldLabel('Curb Type'),
      Row(children: [('curb','Curb'),('curbless','Curbless')].map((opt) {
        final sel = p.curbType == opt.$1;
        return Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () { bath.pan.curbType = opt.$1; onUpdate(bath); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? AppColors.accent : AppColors.border),
              ),
              child: Text(opt.$2, textAlign: TextAlign.center,
                  style: TextStyle(color: sel ? Colors.black : AppColors.muted,
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ));
      }).toList()),
      const SizedBox(height: 8),
      AppInput(label: 'Curb Notes', hint: 'Special details...',
          value: p.curbNote,
          onChanged: (v) { bath.pan.curbNote = v; onUpdate(bath); }),
      if (p.curbType == 'curb' && !p.bench.enabled) ...[
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('2" Board Source'),
              Row(children: [('scrap','Use Scrap'),('boards','Full Boards')].map((opt) {
                final sel = p.curbMaterial == opt.$1;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () { bath.pan.curbMaterial = opt.$1; onUpdate(bath); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.accent : AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? AppColors.accent : AppColors.border),
                      ),
                      child: Text(opt.$2, textAlign: TextAlign.center,
                          style: TextStyle(color: sel ? Colors.black : AppColors.muted,
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 8),
              if (p.curbMaterial == 'scrap') ...[
                AppInput(label: 'Curb Lin Ft', isNumber: true,
                    value: p.curbScrapLinFt,
                    onChanged: (v) { bath.pan.curbScrapLinFt = v; onUpdate(bath); }),
                if ((double.tryParse(p.curbScrapLinFt) ?? 0) > 0)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text(
                      '${(double.tryParse(p.curbScrapLinFt) ?? 0) > 5 ? 'Â¼' : 'â…›'} sheet '
                      '(${(double.tryParse(p.curbScrapLinFt) ?? 0) > 5 ? 'over' : 'under'} 5 ft) = '
                      '\$${(mats.twoInchBoardPrice * ((double.tryParse(p.curbScrapLinFt) ?? 0) > 5 ? 0.25 : 0.125)).toStringAsFixed(2)}'
                      ' Â· 1 sheet = 2Ã—8ft @ \$${mats.twoInchBoardPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.accent, fontSize: 11))),
              ] else ...[
                AppInput(label: 'Board Qty', isNumber: true,
                    value: p.curbBoardQty,
                    onChanged: (v) { bath.pan.curbBoardQty = v; onUpdate(bath); }),
              ],
            ])),
      ],
      if (p.curbType == 'curb' && p.bench.enabled)
        const Padding(padding: EdgeInsets.only(top: 6), child: Text(
            'Bench offcuts cover curb â€” set board qty in bench section below',
            style: TextStyle(color: AppColors.muted, fontSize: 11))),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Bench', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Switch(value: p.bench.enabled, activeColor: AppColors.accent,
            onChanged: (v) { bath.pan.bench.enabled = v; onUpdate(bath); }),
      ]),
      if (p.bench.enabled) ...[
        Row(children: [
          ('small','Small/Corner',rates.where((r) => r.id == 'benchSmall').firstOrNull?.rate ?? 250),
          ('large','Large',rates.where((r) => r.id == 'benchLarge').firstOrNull?.rate ?? 600),
        ].map((opt) {
          final sel = p.bench.size == opt.$1;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () { bath.pan.bench.size = opt.$1; onUpdate(bath); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppColors.accent : AppColors.border),
                ),
                child: Column(children: [
                  Text(opt.$2, style: TextStyle(color: sel ? Colors.black : AppColors.text,
                      fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('\$${(opt.$3).toStringAsFixed(0)}',
                      style: TextStyle(color: sel ? Colors.black87 : AppColors.accent,
                          fontSize: 12)),
                ]),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 8),
        AppInput(label: 'Bench Notes', hint: 'Corner bench, L-shape...',
            value: p.bench.notes,
            onChanged: (v) { bath.pan.bench.notes = v; onUpdate(bath); }),
        const SizedBox(height: 8),
        AppInput(label: '2" Board Qty', isNumber: true,
            value: p.bench.boardQty,
            onChanged: (v) { bath.pan.bench.boardQty = v; onUpdate(bath); }),
        if ((int.tryParse(p.bench.boardQty) ?? 0) > 0)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(
              '${p.bench.boardQty} boards Ã— \$${mats.twoInchBoardPrice.toStringAsFixed(0)} = \$${((int.tryParse(p.bench.boardQty) ?? 0) * mats.twoInchBoardPrice).toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.accent, fontSize: 11))),
      ],
      const SizedBox(height: 12),
      if (panSqFt > 0) GroutSectionWidget(surfaceLabel: 'Shower Floor',
          data: p.floorGrout, groutPrice: mats.groutPrice,
          onChanged: (g) { bath.pan.floorGrout = g; onUpdate(bath); }),
      if (swSqFt > 0) ...[
        const SizedBox(height: 4),
        GroutSectionWidget(surfaceLabel: 'Shower Walls',
            data: p.wallGrout, groutPrice: mats.groutPrice,
            onChanged: (g) { bath.pan.wallGrout = g; onUpdate(bath); }),
      ],
    ]);
  }
}

// â”€â”€â”€ Tub Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TubContent extends StatelessWidget {
  final Bathroom bath;
  final List<LaborRate> rates;
  final MaterialPrices mats;
  final Function(Bathroom) onUpdate;
  const _TubContent({required this.bath, required this.rates,
      required this.mats, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final t = bath.tub;
    final wallSqFt = double.tryParse(t.wallSqFt) ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppInput(label: 'Tub Wall Sq Ft', isNumber: true,
          value: t.wallSqFt,
          onChanged: (v) { bath.tub.wallSqFt = v; onUpdate(bath); }),
      if (wallSqFt > 0) ...[
        const SizedBox(height: 12),
        DifficultyPicker(label: 'Tub Wall Difficulty', value: t.difficulty,
            rates: rates, rateId: 'tubWall',
            onChanged: (d) { bath.tub.difficulty = d; onUpdate(bath); }),
        const SizedBox(height: 12),
        const FieldLabel('Wall Waterproofing'),
        Row(children: [
          ...[('membrane','Membrane'),('foam','Â½" Foam'),('none','None')].map((opt) {
            final sel = t.waterproofType == opt.$1;
            return Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () { bath.tub.waterproofType = opt.$1; onUpdate(bath); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.teal : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppColors.teal : AppColors.border),
                  ),
                  child: Text(opt.$2, textAlign: TextAlign.center,
                      style: TextStyle(color: sel ? Colors.black : AppColors.muted,
                          fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ));
          }),
        ]),
        if (t.waterproofType == 'membrane') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AppInput(label: 'Perimeter Lin Ft', isNumber: true,
                value: t.membraneLinFt,
                onChanged: (v) { bath.tub.membraneLinFt = v; onUpdate(bath); })),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('Membrane Height'),
              Row(children: [('5','5 ft'),('6','6 ft')].map((opt) {
                final sel = t.membraneHeight == opt.$1;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () { bath.tub.membraneHeight = opt.$1; onUpdate(bath); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.teal : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? AppColors.teal : AppColors.border),
                      ),
                      child: Text(opt.$2, textAlign: TextAlign.center,
                          style: TextStyle(color: sel ? Colors.black : AppColors.muted,
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ));
              }).toList()),
            ])),
          ]),
          if ((double.tryParse(t.membraneLinFt) ?? 0) > 0)
            Padding(padding: const EdgeInsets.only(top: 4),
                child: Text('${t.membraneLinFt} lf Ã— ${t.membraneHeight} ft = '
                    '${((double.tryParse(t.membraneLinFt) ?? 0) * (double.tryParse(t.membraneHeight) ?? 5)).toStringAsFixed(1)} sqft membrane',
                    style: const TextStyle(color: AppColors.teal, fontSize: 11))),
        ],
        if (t.waterproofType == 'foam') ...[
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('Â½" foam walls: ${wallSqFt.toStringAsFixed(1)} sqft'
                  ' = \$${(wallSqFt * mats.halfInchFoamPrice).toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.teal, fontSize: 12))),
        ],
        const SizedBox(height: 12),
        StepCounter(label: 'Tub Shelves',
            value: int.tryParse(t.shelves) ?? 0,
            onChanged: (v) { bath.tub.shelves = v.toString(); onUpdate(bath); }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FieldLabel('Standard Niches'),
            AppInput(isNumber: true, value: t.niches,
                onChanged: (v) { bath.tub.niches = v; onUpdate(bath); }),
          ])),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FieldLabel('Custom Niches'),
            AppInput(isNumber: true, value: t.customNiches,
                onChanged: (v) { bath.tub.customNiches = v; onUpdate(bath); }),
          ])),
        ]),
        const SizedBox(height: 10),
        GroutSectionWidget(surfaceLabel: 'Tub Walls',
            data: t.grout, groutPrice: mats.groutPrice,
            onChanged: (g) { bath.tub.grout = g; onUpdate(bath); }),
      ],
    ]);
  }
}

// â”€â”€â”€ Generic Surface Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SurfaceContent extends StatelessWidget {
  final String title, rateId;
  final String sqFt;
  final Difficulty? difficulty;
  final GroutData grout;
  final double groutPrice;
  final List<LaborRate> rates;
  final ValueChanged<String> onSqFtChanged;
  final ValueChanged<Difficulty?> onDiffChanged;
  final ValueChanged<GroutData> onGroutChanged;

  const _SurfaceContent({required this.title, required this.sqFt,
      required this.difficulty, required this.rateId, required this.grout,
      required this.groutPrice, required this.rates, required this.onSqFtChanged,
      required this.onDiffChanged, required this.onGroutChanged});

  @override
  Widget build(BuildContext context) {
    final sqftVal = double.tryParse(sqFt) ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppInput(label: 'Sq Ft', isNumber: true,
          value: sqFt, onChanged: onSqFtChanged),
      if (sqftVal > 0) ...[
        const SizedBox(height: 12),
        DifficultyPicker(label: '$title Difficulty', value: difficulty,
            rates: rates, rateId: rateId, onChanged: onDiffChanged),
        const SizedBox(height: 10),
        GroutSectionWidget(surfaceLabel: title,
            data: grout, groutPrice: groutPrice, onChanged: onGroutChanged),
      ],
    ]);
  }
}

// â”€â”€â”€ Edge Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EdgeContent extends StatelessWidget {
  final Bathroom bath;
  final List<LaborRate> rates;
  final Function(Bathroom) onUpdate;
  const _EdgeContent({required this.bath, required this.rates, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final e = bath.edging;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const FieldLabel('Edge Type'),
      Row(children: [
        ('metal','Metal  \$${rates.where((r) => r.id == 'metalEdge').firstOrNull?.rate.toStringAsFixed(2) ?? '1.00'}'),
        ('miter','Miter  \$${rates.where((r) => r.id == 'miterEdge').firstOrNull?.rate.toStringAsFixed(2) ?? '20.00'}'),
        ('pencil','Pencil \$${rates.where((r) => r.id == 'pencilEdge').firstOrNull?.rate.toStringAsFixed(2) ?? '6.00'}'),
      ].map((opt) {
        final sel = e.type == opt.$1;
        return Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () { bath.edging.type = opt.$1; onUpdate(bath); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sel ? AppColors.accent : AppColors.border),
              ),
              child: Text(opt.$2, textAlign: TextAlign.center,
                  style: TextStyle(color: sel ? Colors.black : AppColors.muted,
                      fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ),
        ));
      }).toList()),
      const SizedBox(height: 8),
      AppInput(label: 'Lin Ft', isNumber: true,
          value: e.linFt,
          onChanged: (v) { bath.edging.linFt = v; onUpdate(bath); }),
    ]);
  }
}
