import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/calculations.dart';
import '../widgets/common_widgets.dart';
import 'new_project_screen.dart';
import 'project_overview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? state.projects
        : state.projects.where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.contact.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                  hintText: 'Search by name or contact...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.muted),
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Row(children: [
                SizedBox(
                  width: 28, height: 28,
                  child: CustomPaint(painter: _TLogoPainter()),
                ),
                const SizedBox(width: 8),
                const Text('Tile Manager'),
              ]),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search,
                color: AppColors.muted),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) { _query = ''; _searchCtrl.clear(); }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NewProjectScreen())),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: state.projects.isEmpty
          ? _emptyState()
          : filtered.isEmpty
              ? Center(child: Text('No results for "$_query"',
                  style: const TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _ProjectCard(
                      project: filtered[i], state: state),
                ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const _TLogoIcon(),
      const SizedBox(height: 16),
      const Text('No projects yet', style: TextStyle(color: AppColors.text,
          fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Tap + to create your first project.',
          style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NewProjectScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent, foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]),
  );
}

class _TLogoIcon extends StatelessWidget {
  const _TLogoIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(100, 100),
    painter: _TLogoPainter(),
  );
}

class _TLogoPainter extends CustomPainter {
  const _TLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = s * 0.18;

    // Background
    final bgPaint = Paint()..color = const Color(0xFF0D0D0D);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s), Radius.circular(r)), bgPaint);

    final cx = s * 0.54;
    final midY = s * 0.50;
    final tLeft = cx - s * 0.09;

    // Speed lines
    final lines = [
      (dy: -s * 0.14, len: s * 0.28, alpha: 0.55),
      (dy: -s * 0.07, len: s * 0.36, alpha: 0.75),
      (dy: 0.0,       len: s * 0.40, alpha: 0.90),
      (dy:  s * 0.07, len: s * 0.36, alpha: 0.75),
      (dy:  s * 0.14, len: s * 0.28, alpha: 0.55),
    ];
    for (final l in lines) {
      final y  = midY + l.dy;
      final x1 = tLeft - l.len;
      final x2 = tLeft - s * 0.025;
      final shader = LinearGradient(colors: [
        const Color(0xFFE8172A).withOpacity(0),
        const Color(0xFFE8172A).withOpacity(l.alpha),
      ]).createShader(Rect.fromLTRB(x1, y - 1, x2, y + 1));
      canvas.drawLine(Offset(x1, y), Offset(x2, y),
          Paint()
            ..shader = shader
            ..strokeWidth = s * 0.022
            ..strokeCap = StrokeCap.round);
    }

    // Italic T
    const skew = -0.22;
    final tx = cx - skew * (s * 0.28);
    final crossH = s * 0.14;
    final crossW = s * 0.54;
    final stemW  = s * 0.18;
    final stemH  = s * 0.50;
    final topY   = s * 0.18;
    final botY   = topY + crossH + stemH;

    final tPath = Path()
      ..moveTo(tx - crossW / 2, topY)
      ..lineTo(tx + crossW / 2, topY)
      ..lineTo(tx + crossW / 2, topY + crossH)
      ..lineTo(tx + stemW / 2,  topY + crossH)
      ..lineTo(tx + stemW / 2,  botY)
      ..lineTo(tx - stemW / 2,  botY)
      ..lineTo(tx - stemW / 2,  topY + crossH)
      ..lineTo(tx - crossW / 2, topY + crossH)
      ..close();

    final skewMatrix = Matrix4.identity()..setEntry(0, 1, skew);
    canvas.save();
    canvas.transform(skewMatrix.storage);

    final tShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFFFF2D42), const Color(0xFFB01020)],
    ).createShader(Rect.fromLTWH(tx - crossW / 2, topY, crossW, crossH + stemH));

    canvas.drawPath(tPath, Paint()..shader = tShader);
    canvas.restore();

    // Clip to rounded rect
    canvas.saveLayer(Rect.fromLTWH(0, 0, s, s), Paint()..blendMode = BlendMode.dstIn);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s), Radius.circular(r)),
        Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final AppState state;
  const _ProjectCard({required this.project, required this.state});

  @override
  Widget build(BuildContext context) {
    final totals = calcProjectFootage(project);
    final bd = calcProjectBreakdown(project, state.rates, state.materials);
    final rooms = project.bathrooms.length + project.mudRooms.length +
        project.laundryRooms.length + project.others.length;

    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProjectOverviewScreen(project: project))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(project.name, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 16))),
          Text('\$${bd.total.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.accent,
                  fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        if (project.contact.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text('📞 ${project.contact}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
        if (project.address.isNotEmpty)
          Text('📍 ${project.address}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 4, children: [
          Tag('${totals.floor.toStringAsFixed(0)} floor sqft'),
          Tag('${totals.walls.toStringAsFixed(0)} wall sqft', color: AppColors.blue),
          if (totals.ceiling > 0)
            Tag('${totals.ceiling.toStringAsFixed(0)} ceil', color: AppColors.purple),
          Tag('$rooms room${rooms != 1 ? 's' : ''}', color: AppColors.muted),
        ]),
      ]),
    );
  }
}
