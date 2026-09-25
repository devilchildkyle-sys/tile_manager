import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;
import '../state/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Settings'),
      bottom: TabBar(controller: _tabs,
          labelColor: AppColors.accent, unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.accent,
          tabs: const [Tab(text: 'LABOR'), Tab(text: 'MATERIALS'), Tab(text: 'ABOUT')]),
    ),
    body: TabBarView(controller: _tabs, children: const [
      _LaborTab(), _MaterialsTab(), _AboutTab(),
    ]),
  );
}

// ─── Labor Tab ────────────────────────────────────────────────────────────────
class _LaborTab extends StatelessWidget {
  const _LaborTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rates = state.rates;

    final tiered  = rates.where((r) => r.tiered).toList();
    final flat    = rates.where((r) => !r.tiered).toList();

    return ListView(padding: const EdgeInsets.all(14), children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Tiered Rates (Easy / Medium / Hard)'),
        ...tiered.map((r) => _TieredRateRow(rate: r, onChanged: (updated) {
          final idx = rates.indexWhere((x) => x.id == r.id);
          if (idx >= 0) { rates[idx] = updated; state.updateRates(List.from(rates)); }
        })),
      ])),
      const SizedBox(height: 8),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Flat Rates'),
        ...flat.map((r) => _FlatRateRow(rate: r, onChanged: (updated) {
          final idx = rates.indexWhere((x) => x.id == r.id);
          if (idx >= 0) { rates[idx] = updated; state.updateRates(List.from(rates)); }
        })),
      ])),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showConfirmDialog(context,
              title: 'Reset Labor Rates?',
              message: 'All rates will return to defaults.',
              confirmLabel: 'Reset', confirmColor: AppColors.accent);
          if (confirmed && context.mounted) context.read<AppState>().resetRates();
        },
        icon: const Icon(Icons.refresh, color: AppColors.muted),
        label: const Text('Reset to Defaults', style: TextStyle(color: AppColors.muted)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class _TieredRateRow extends StatefulWidget {
  final LaborRate rate;
  final ValueChanged<LaborRate> onChanged;
  const _TieredRateRow({required this.rate, required this.onChanged});
  @override
  State<_TieredRateRow> createState() => _TieredRateRowState();
}

class _TieredRateRowState extends State<_TieredRateRow> {
  late TextEditingController _easy, _medium, _hard;

  @override
  void initState() {
    super.initState();
    _easy   = TextEditingController(text: widget.rate.easy.toString());
    _medium = TextEditingController(text: widget.rate.medium.toString());
    _hard   = TextEditingController(text: widget.rate.hard.toString());
  }

  void _sync(TextEditingController ctrl, String incoming) {
    if (incoming != ctrl.text) {
      final sel = ctrl.selection;
      ctrl.text = incoming;
      if (sel.isValid && sel.end <= incoming.length) ctrl.selection = sel;
    }
  }

  @override
  void didUpdateWidget(_TieredRateRow old) {
    super.didUpdateWidget(old);
    _sync(_easy,   widget.rate.easy.toString());
    _sync(_medium, widget.rate.medium.toString());
    _sync(_hard,   widget.rate.hard.toString());
  }

  @override
  void dispose() { _easy.dispose(); _medium.dispose(); _hard.dispose(); super.dispose(); }

  Widget _field(TextEditingController ctrl, Color color, ValueChanged<String> onCh) =>
      Expanded(flex: 2, child: Container(
        decoration: BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border)),
        child: TextField(
          controller: ctrl, onChanged: onCh,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            prefixText: '\$', prefixStyle: TextStyle(color: color, fontSize: 11),
            border: InputBorder.none, enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          ),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    final r = widget.rate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(flex: 3, child: Text(r.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        _field(_easy, AppColors.success, (v) => widget.onChanged(LaborRate(
            id: r.id, name: r.name, unit: r.unit, tiered: true,
            easy: double.tryParse(v) ?? r.easy, medium: r.medium, hard: r.hard))),
        const SizedBox(width: 4),
        _field(_medium, AppColors.accent, (v) => widget.onChanged(LaborRate(
            id: r.id, name: r.name, unit: r.unit, tiered: true,
            easy: r.easy, medium: double.tryParse(v) ?? r.medium, hard: r.hard))),
        const SizedBox(width: 4),
        _field(_hard, AppColors.danger, (v) => widget.onChanged(LaborRate(
            id: r.id, name: r.name, unit: r.unit, tiered: true,
            easy: r.easy, medium: r.medium, hard: double.tryParse(v) ?? r.hard))),
        const SizedBox(width: 4),
        Text('/${r.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
      ]),
    );
  }
}

class _FlatRateRow extends StatefulWidget {
  final LaborRate rate;
  final ValueChanged<LaborRate> onChanged;
  const _FlatRateRow({required this.rate, required this.onChanged});
  @override
  State<_FlatRateRow> createState() => _FlatRateRowState();
}

class _FlatRateRowState extends State<_FlatRateRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.rate.rate.toString());
  }

  @override
  void didUpdateWidget(_FlatRateRow old) {
    super.didUpdateWidget(old);
    final incoming = widget.rate.rate.toString();
    if (incoming != _ctrl.text) {
      final sel = _ctrl.selection;
      _ctrl.text = incoming;
      if (sel.isValid && sel.end <= incoming.length) _ctrl.selection = sel;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.rate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(r.name, style: const TextStyle(fontSize: 14))),
        SizedBox(width: 80, child: Container(
          decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border)),
          child: TextField(
            controller: _ctrl,
            onChanged: (v) => widget.onChanged(LaborRate(id: r.id, name: r.name,
                unit: r.unit, tiered: false, rate: double.tryParse(v) ?? r.rate)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.accent, fontSize: 14,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              prefixText: '\$',
              prefixStyle: TextStyle(color: AppColors.accent, fontSize: 12),
              border: InputBorder.none, enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none, isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
          ),
        )),
        const SizedBox(width: 4),
        Text('/${r.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
      ]),
    );
  }
}

// ─── Materials Tab ────────────────────────────────────────────────────────────
class _MaterialsTab extends StatelessWidget {
  const _MaterialsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final M = state.materials;

    void upd(MaterialPrices m) => state.updateMaterials(m);

    return ListView(padding: const EdgeInsets.all(14), children: [
      _matCard('🪣 Thin Set', [
        _MatField('Price per bag', M.thinsetPrice.toString(),
            (v) => upd(MaterialPrices(thinsetPrice: double.tryParse(v) ?? M.thinsetPrice,
                thinsetFloorCov: M.thinsetFloorCov, thinsetWallCov: M.thinsetWallCov,
                groutPrice: M.groutPrice, wallMembranePrice: M.wallMembranePrice,
                halfInchFoamPrice: M.halfInchFoamPrice, floorMatPrice: M.floorMatPrice,
                heatMatPrice: M.heatMatPrice, selfLevelPrice: M.selfLevelPrice,
                twoInchBoardPrice: M.twoInchBoardPrice, foamPanPrices: M.foamPanPrices,
                drainStandardPrice: M.drainStandardPrice, drainTileGratePrice: M.drainTileGratePrice,
                nicheStdPrice: M.nicheStdPrice, nicheCustomPrice: M.nicheCustomPrice))),
        _MatField('Floor sq ft/bag', M.thinsetFloorCov.toString(),
            (v) { M.thinsetFloorCov = double.tryParse(v) ?? M.thinsetFloorCov; upd(M); }),
        _MatField('Wall sq ft/bag', M.thinsetWallCov.toString(),
            (v) { M.thinsetWallCov = double.tryParse(v) ?? M.thinsetWallCov; upd(M); }),
      ]),
      _matCard('🟡 Grout', [
        _MatField('Price per bag', M.groutPrice.toString(),
            (v) { M.groutPrice = double.tryParse(v) ?? M.groutPrice; upd(M); }),
      ], note: 'Coverage calculated per job from tile size & joint width'),
      _matCard('💧 Waterproofing', [
        _MatField('Wall Membrane (\$/sqft)', M.wallMembranePrice.toString(),
            (v) { M.wallMembranePrice = double.tryParse(v) ?? M.wallMembranePrice; upd(M); }),
        _MatField('½" Foam Board (\$/sqft)', M.halfInchFoamPrice.toString(),
            (v) { M.halfInchFoamPrice = double.tryParse(v) ?? M.halfInchFoamPrice; upd(M); }),
        _MatField('2" Board — price per sheet', M.twoInchBoardPrice.toString(),
            (v) { M.twoInchBoardPrice = double.tryParse(v) ?? M.twoInchBoardPrice; upd(M); }),
      ]),
      _matCard('🔥 Floor Materials (\$/sqft)', [
        _MatField('Floor Mat', M.floorMatPrice.toString(),
            (v) { M.floorMatPrice = double.tryParse(v) ?? M.floorMatPrice; upd(M); }),
        _MatField('Heat Mat', M.heatMatPrice.toString(),
            (v) { M.heatMatPrice = double.tryParse(v) ?? M.heatMatPrice; upd(M); }),
        _MatField('Self Leveler', M.selfLevelPrice.toString(),
            (v) { M.selfLevelPrice = double.tryParse(v) ?? M.selfLevelPrice; upd(M); }),
        _MatField('Price Per Sheet (¼" cement board)', M.quarterInchBoardPrice.toString(),
            (v) { M.quarterInchBoardPrice = double.tryParse(v) ?? M.quarterInchBoardPrice; upd(M); }),
      ]),
      _matCard('🛁 Foam Pan Sizes (\$each)', [
        ...['3x3','3x5','5x5','6x6'].map((size) => _MatField(
            '$size Pan', M.foamPanPrices[size]?.toString() ?? '0',
            (v) { M.foamPanPrices[size] = double.tryParse(v) ?? 0; upd(M); })),
      ]),
      _matCard('🕳 Drain (\$each)', [
        _MatField('Standard Grate', M.drainStandardPrice.toString(),
            (v) { M.drainStandardPrice = double.tryParse(v) ?? M.drainStandardPrice; upd(M); }),
        _MatField('Tile Grate', M.drainTileGratePrice.toString(),
            (v) { M.drainTileGratePrice = double.tryParse(v) ?? M.drainTileGratePrice; upd(M); }),
      ]),
      _matCard('◻ Niches (\$each)', [
        _MatField('Standard Niche', M.nicheStdPrice.toString(),
            (v) { M.nicheStdPrice = double.tryParse(v) ?? M.nicheStdPrice; upd(M); }),
        _MatField('Custom Niche', M.nicheCustomPrice.toString(),
            (v) { M.nicheCustomPrice = double.tryParse(v) ?? M.nicheCustomPrice; upd(M); }),
      ]),
      _matCard('📐 Edging Material', [
        _MatField('Metal Edge (price per 8ft stick)', M.metalEdgePrice.toString(),
            (v) { M.metalEdgePrice = double.tryParse(v) ?? M.metalEdgePrice; upd(M); }),
      ], note: '1 stick = 8 ft · sticks rounded up from lin ft entered'),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showConfirmDialog(context,
              title: 'Reset Material Prices?',
              message: 'All prices will return to defaults.',
              confirmLabel: 'Reset', confirmColor: AppColors.accent);
          if (confirmed && context.mounted) context.read<AppState>().resetMaterials();
        },
        icon: const Icon(Icons.refresh, color: AppColors.muted),
        label: const Text('Reset to Defaults', style: TextStyle(color: AppColors.muted)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _matCard(String title, List<Widget> fields, {String? note}) =>
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title),
        ...fields,
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ]));
}

class _MatField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _MatField(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AppInput(label: label, isNumber: true,
        value: value,
        onChanged: onChanged),
  );
}

// ─── About / Updates Tab ──────────────────────────────────────────────────────
class _AboutTab extends StatefulWidget {
  const _AboutTab();
  @override
  State<_AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<_AboutTab> {
  UpdateInfo? _info;
  bool _checking = false;
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() { _checking = true; _error = null; });
    final info = await UpdateService.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _info = info;
      if (info == null) _error = 'Could not reach update server.';
    });
  }

  Future<void> _download() async {
    if (_info == null) return;
    setState(() { _downloading = true; _progress = 0; _error = null; });
    await UpdateService.downloadAndInstall(
      _info!.downloadUrl,
      onProgress: (p) { if (mounted) setState(() => _progress = p); },
      onError: (e) { if (mounted) setState(() { _error = e; _downloading = false; }); },
    );
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('App Info'),
        if (_info != null) ...[
          _row('Current Version', 'v${_info!.currentVersion}'),
          _row('Latest Version',  'v${_info!.latestVersion}'),
          const SizedBox(height: 4),
          if (_info!.hasUpdate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.new_releases_outlined, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Update available — v${_info!.latestVersion}',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
              ]),
            )
          else
            const Row(children: [
              Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
              SizedBox(width: 8),
              Text('You\'re up to date', style: TextStyle(color: AppColors.success)),
            ]),
          if (_info!.hasUpdate && _info!.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text("What's new:", style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_info!.releaseNotes,
                style: const TextStyle(color: AppColors.text, fontSize: 12), maxLines: 8, overflow: TextOverflow.ellipsis),
          ],
        ] else if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      ])),
      const SizedBox(height: 8),
      if (_info != null && _info!.hasUpdate) ...[
        if (_downloading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text('Downloading… ${(_progress * 100).toInt()}%',
              style: const TextStyle(color: AppColors.muted, fontSize: 12))),
        ] else
          ElevatedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download & Install'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
      ],
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: (_checking || _downloading) ? null : _check,
        icon: _checking
            ? const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted))
            : const Icon(Icons.refresh, color: AppColors.muted),
        label: Text(_checking ? 'Checking...' : 'Check for Updates',
            style: const TextStyle(color: AppColors.muted)),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size.fromHeight(44)),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      Text(value, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}
