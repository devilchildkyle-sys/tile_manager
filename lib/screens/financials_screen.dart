import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

const _uuid = Uuid();

const _expenseCategories = [
  'Materials', 'Tools', 'Fuel', 'Labor', 'Food', 'Insurance', 'Other'
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class FinancialsScreen extends StatefulWidget {
  const FinancialsScreen({super.key});
  @override
  State<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends State<FinancialsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financials'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.muted,
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'PAYMENTS'),
            Tab(text: 'EXPENSES'),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: TabBarView(
        controller: _tabs,
        children: const [
          _OverviewTab(),
          _PaymentsTab(),
          _ExpensesTab(),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final income = state.payments.fold<double>(
        0, (s, p) => s + (double.tryParse(p.amount) ?? 0));
    final expenses = state.expenses.fold<double>(
        0, (s, e) => s + (double.tryParse(e.amount) ?? 0));
    final net = income - expenses;
    final tax = net > 0 ? net * 0.25 : 0.0;

    // Group expenses by category
    final byCategory = <String, double>{};
    for (final e in state.expenses) {
      final amt = double.tryParse(e.amount) ?? 0;
      byCategory[e.category] = (byCategory[e.category] ?? 0) + amt;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary tiles
        Row(children: [
          Expanded(child: _StatCard(
              label: 'Total Income', value: '\$${income.toStringAsFixed(2)}',
              color: AppColors.success)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(
              label: 'Total Expenses', value: '\$${expenses.toStringAsFixed(2)}',
              color: AppColors.danger)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatCard(
              label: 'Net Profit', value: '\$${net.toStringAsFixed(2)}',
              color: net >= 0 ? AppColors.accent : AppColors.danger)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(
              label: 'Tax Est. (25%)', value: '\$${tax.toStringAsFixed(2)}',
              color: AppColors.purple)),
        ]),

        if (byCategory.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionTitle('Expenses by Category'),
          AppCard(
            child: Column(children: byCategory.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text(_categoryIcon(e.key),
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(e.key,
                          style: const TextStyle(color: AppColors.text)),
                    ]),
                    Text('\$${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList()),
          ),
        ],

        if (state.payments.isNotEmpty) ...[
          const SizedBox(height: 10),
          SectionTitle(
              '${state.payments.length} Payment${state.payments.length != 1 ? 's' : ''}'),
          ...state.payments.reversed.map((p) => _PaymentRow(payment: p)),
        ],
      ],
    );
  }
}

// ─── Payments Tab ─────────────────────────────────────────────────────────────
class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab();
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  final _amtCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _project = '';
  String _date    = _today();
  String? _photoPath;
  bool _expanded  = true;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_amtCtrl.text.trim().isEmpty) return;
    final state = context.read<AppState>();
    state.addPayment(Payment(
      id: _uuid.v4(),
      project: _project,
      amount:  _amtCtrl.text.trim(),
      note:    _noteCtrl.text.trim(),
      date:    _date,
      photo:   _photoPath != null
          ? PhotoRecord(path: _photoPath!, name: 'check.jpg')
          : null,
    ));
    setState(() {
      _amtCtrl.clear();
      _noteCtrl.clear();
      _project   = '';
      _date      = _today();
      _photoPath = null;
      _expanded  = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment logged ✓')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Log form
        _FormCard(
          title: 'Log a Payment',
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: AppInput(
                label: 'Amount (\$)', hint: '0.00',
                controller: _amtCtrl, isNumber: true)),
              const SizedBox(width: 10),
              Expanded(child: _DateField(
                  label: 'Date', value: _date,
                  onChanged: (d) => setState(() => _date = d))),
            ]),
            const SizedBox(height: 10),
            FieldLabel('Project'),
            _ProjectDropdown(
              value: _project,
              projects: state.projects,
              onChanged: (v) => setState(() => _project = v),
            ),
            const SizedBox(height: 10),
            AppInput(
                label: 'Note', hint: 'Check #, deposit memo...',
                controller: _noteCtrl),
            const SizedBox(height: 12),
            PhotoPickerWidget(
              photoPath: _photoPath,
              label: 'Attach Check Photo',
              onChanged: (p) => setState(() => _photoPath = p),
            ),
            const SizedBox(height: 14),
            PrimaryButton(label: 'Log Payment', onTap: _submit),
          ]),
        ),

        const SizedBox(height: 6),
        SectionTitle(
            '${state.payments.length} Payment${state.payments.length != 1 ? 's' : ''}'),

        if (state.payments.isEmpty)
          const _EmptyHint(text: 'No payments logged yet.'),

        ...state.payments.reversed.map((p) => _DismissiblePayment(payment: p)),
      ],
    );
  }
}

// ─── Expenses Tab ─────────────────────────────────────────────────────────────
class _ExpensesTab extends StatefulWidget {
  const _ExpensesTab();
  @override
  State<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<_ExpensesTab> {
  final _amtCtrl   = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _category = 'Materials';
  String _date     = _today();
  String? _photoPath;
  bool _expanded   = true;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_amtCtrl.text.trim().isEmpty) return;
    final state = context.read<AppState>();
    state.addExpense(Expense(
      id:       _uuid.v4(),
      label:    _descCtrl.text.trim(),
      amount:   _amtCtrl.text.trim(),
      category: _category,
      date:     _date,
      photo:    _photoPath != null
          ? PhotoRecord(path: _photoPath!, name: 'receipt.jpg')
          : null,
    ));
    setState(() {
      _amtCtrl.clear();
      _descCtrl.clear();
      _category  = 'Materials';
      _date      = _today();
      _photoPath = null;
      _expanded  = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense logged ✓')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Log form
        _FormCard(
          title: 'Log an Expense',
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: AppInput(
                  label: 'Amount (\$)', hint: '0.00',
                  controller: _amtCtrl, isNumber: true)),
              const SizedBox(width: 10),
              Expanded(child: _DateField(
                  label: 'Date', value: _date,
                  onChanged: (d) => setState(() => _date = d))),
            ]),
            const SizedBox(height: 10),
            FieldLabel('Category'),
            _CategoryDropdown(
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 10),
            AppInput(
                label: 'Description', hint: 'What was it for?',
                controller: _descCtrl),
            const SizedBox(height: 12),
            PhotoPickerWidget(
              photoPath: _photoPath,
              label: 'Attach Receipt Photo',
              onChanged: (p) => setState(() => _photoPath = p),
            ),
            const SizedBox(height: 14),
            PrimaryButton(label: 'Log Expense', onTap: _submit),
          ]),
        ),

        const SizedBox(height: 6),
        SectionTitle(
            '${state.expenses.length} Expense${state.expenses.length != 1 ? 's' : ''}'),

        if (state.expenses.isEmpty)
          const _EmptyHint(text: 'No expenses logged yet.'),

        ...state.expenses.reversed.map((e) => _DismissibleExpense(expense: e)),
      ],
    );
  }
}

// ─── Reusable UI ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: const TextStyle(color: AppColors.muted, fontSize: 10,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      Text(value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
    ]),
  );
}

class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;
  const _FormCard({required this.title, required this.child,
      required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
              Icon(expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: child,
        ),
    ]),
  );
}

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(payment.project.isEmpty ? '—' : payment.project,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${payment.note.isEmpty ? '' : '${payment.note} · '}${payment.date}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ])),
        Text('\$${(double.tryParse(payment.amount) ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.success,
                fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
      if (payment.photo != null && payment.photo!.path.isNotEmpty) ...[
        const SizedBox(height: 8),
        _PhotoThumb(path: payment.photo!.path),
      ],
    ]),
  );
}

class _DismissiblePayment extends StatelessWidget {
  final Payment payment;
  const _DismissiblePayment({required this.payment});

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key('pay_${payment.id}'),
    direction: DismissDirection.endToStart,
    background: _deleteBg(),
    confirmDismiss: (_) => showConfirmDialog(context,
        title: 'Delete Payment?',
        message: 'Remove \$${payment.amount} from ${payment.project.isEmpty ? "—" : payment.project}?',
        confirmLabel: 'Delete'),
    onDismissed: (_) => context.read<AppState>().deletePayment(payment.id),
    child: _PaymentRow(payment: payment),
  );
}

class _DismissibleExpense extends StatelessWidget {
  final Expense expense;
  const _DismissibleExpense({required this.expense});

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key('exp_${expense.id}'),
    direction: DismissDirection.endToStart,
    background: _deleteBg(),
    confirmDismiss: (_) => showConfirmDialog(context,
        title: 'Delete Expense?',
        message: 'Remove \$${expense.amount} (${expense.category})?',
        confirmLabel: 'Delete'),
    onDismissed: (_) => context.read<AppState>().deleteExpense(expense.id),
    child: AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_categoryIcon(expense.category),
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(expense.label.isEmpty ? expense.category : expense.label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 2),
            Text('${expense.category} · ${expense.date}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
          Text('-\$${(double.tryParse(expense.amount) ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.danger,
                  fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        if (expense.photo != null && expense.photo!.path.isNotEmpty) ...[
          const SizedBox(height: 8),
          _PhotoThumb(path: expense.photo!.path),
        ],
      ]),
    ),
  );
}

class _PhotoThumb extends StatelessWidget {
  final String path;
  const _PhotoThumb({required this.path});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(path),
      width: 64, height: 64, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 64, height: 64, color: AppColors.surface,
        child: const Icon(Icons.broken_image, color: AppColors.muted)),
    ),
  );
}

class _ProjectDropdown extends StatelessWidget {
  final String value;
  final List<Project> projects;
  final ValueChanged<String> onChanged;
  const _ProjectDropdown({required this.value, required this.projects,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border)),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value.isEmpty ? null : value,
        hint: const Text('— Select Project —',
            style: TextStyle(color: AppColors.muted)),
        isExpanded: true,
        dropdownColor: AppColors.card,
        style: const TextStyle(color: AppColors.text, fontSize: 15),
        items: projects.map((p) => DropdownMenuItem(
            value: p.name, child: Text(p.name))).toList(),
        onChanged: (v) => onChanged(v ?? ''),
      ),
    ),
  );
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border)),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.card,
        style: const TextStyle(color: AppColors.text, fontSize: 15),
        items: _expenseCategories.map((c) => DropdownMenuItem(
            value: c,
            child: Row(children: [
              Text(_categoryIcon(c), style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(c),
            ]))).toList(),
        onChanged: (v) => onChanged(v ?? 'Materials'),
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  const _DateField({required this.label, required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldLabel(label),
      GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(value) ?? now,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 1),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                    primary: AppColors.accent, onPrimary: Colors.black,
                    surface: AppColors.card, onSurface: AppColors.text)),
              child: child!,
            ),
          );
          if (picked != null) {
            onChanged('${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border)),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 15, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(
                color: AppColors.text, fontSize: 15)),
          ]),
        ),
      ),
    ],
  );
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(child: Text(text,
        style: const TextStyle(color: AppColors.muted))),
  );
}

Widget _deleteBg() => Container(
  alignment: Alignment.centerRight,
  padding: const EdgeInsets.only(right: 20),
  margin: const EdgeInsets.only(bottom: 10),
  decoration: BoxDecoration(
      color: AppColors.danger.withOpacity(0.15),
      borderRadius: BorderRadius.circular(14)),
  child: const Icon(Icons.delete_outline, color: AppColors.danger),
);

String _categoryIcon(String cat) {
  switch (cat) {
    case 'Materials':  return '🧱';
    case 'Tools':      return '🔧';
    case 'Fuel':       return '⛽';
    case 'Labor':      return '👷';
    case 'Food':       return '🍔';
    case 'Insurance':  return '📋';
    default:           return '📌';
  }
}

String _today() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
}
