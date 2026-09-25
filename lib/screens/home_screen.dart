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
                  child: CustomPaint(painter: _BlueprintPainter()),
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
      const _BlueprintIcon(),
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

class _BlueprintIcon extends StatelessWidget {
  const _BlueprintIcon();

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(100, 100),
    painter: _BlueprintPainter(),
  );
}

class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF1A2A4A);
    final border = Paint()
      ..color = const Color(0xFF3A5A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final line = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final dim = Paint()
      ..color = const Color(0xFFFFB547).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final dot = Paint()..color = const Color(0xFF60A5FA).withOpacity(0.6);

    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(14));
    canvas.drawRRect(r, bg);
    canvas.drawRRect(r, border);

    final s = size.width;

    // Floor plan outline — outer walls
    final walls = [
      Offset(0.15 * s, 0.2 * s), Offset(0.85 * s, 0.2 * s),
      Offset(0.85 * s, 0.82 * s), Offset(0.15 * s, 0.82 * s),
      Offset(0.15 * s, 0.2 * s),
    ];
    final path = Path()..moveTo(walls[0].dx, walls[0].dy);
    for (final pt in walls.skip(1)) path.lineTo(pt.dx, pt.dy);
    canvas.drawPath(path, line..strokeWidth = 2.0);

    // Interior wall — vertical divider
    canvas.drawLine(Offset(0.52 * s, 0.2 * s), Offset(0.52 * s, 0.65 * s), line..strokeWidth = 1.5);
    // Interior wall — horizontal divider
    canvas.drawLine(Offset(0.15 * s, 0.55 * s), Offset(0.52 * s, 0.55 * s), line..strokeWidth = 1.5);

    // Door arc (bottom-left room)
    final doorRect = Rect.fromCenter(
        center: Offset(0.15 * s, 0.55 * s), width: 0.18 * s, height: 0.18 * s);
    canvas.drawArc(doorRect, -1.57, 1.57, false, line..strokeWidth = 1.0);
    canvas.drawLine(Offset(0.15 * s, 0.55 * s), Offset(0.15 * s, 0.64 * s), line..strokeWidth = 1.0);

    // Window — top wall
    canvas.drawLine(Offset(0.32 * s, 0.2 * s), Offset(0.44 * s, 0.2 * s),
        Paint()..color = const Color(0xFF2DD4BF)..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);

    // Dimension lines (accent color)
    canvas.drawLine(Offset(0.15 * s, 0.88 * s), Offset(0.85 * s, 0.88 * s), dim);
    canvas.drawLine(Offset(0.15 * s, 0.86 * s), Offset(0.15 * s, 0.90 * s), dim);
    canvas.drawLine(Offset(0.85 * s, 0.86 * s), Offset(0.85 * s, 0.90 * s), dim);

    // Grid dots
    for (double x = 0.25 * s; x < 0.90 * s; x += 0.15 * s) {
      for (double y = 0.30 * s; y < 0.80 * s; y += 0.15 * s) {
        canvas.drawCircle(Offset(x, y), 0.8, dot);
      }
    }
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
