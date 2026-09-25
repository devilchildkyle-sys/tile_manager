import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/defaults.dart';

const _kProjects  = 'et_projects';
const _kRates     = 'et_rates';
const _kMaterials = 'et_materials';
const _kPayments  = 'et_payments';
const _kExpenses  = 'et_expenses';

const _uuid = Uuid();

class AppState extends ChangeNotifier {
  List<Project>   projects  = [];
  List<LaborRate> rates     = defaultRates();
  MaterialPrices  materials = defaultMaterials();
  List<Payment>   payments  = [];
  List<Expense>   expenses  = [];
  bool loaded = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final rJson = prefs.getString(_kRates);
    if (rJson != null) {
      try {
        final list = jsonDecode(rJson) as List;
        rates = list.map((e) => LaborRate.fromJson(e)).toList();
      } catch (_) {}
    }

    final mJson = prefs.getString(_kMaterials);
    if (mJson != null) {
      try { materials = MaterialPrices.fromJson(jsonDecode(mJson)); } catch (_) {}
    }

    final pJson = prefs.getString(_kProjects);
    if (pJson != null) {
      try {
        final list = jsonDecode(pJson) as List;
        projects = list.map((e) => Project.fromJson(e)).toList();
      } catch (_) {}
    }

    final payJson = prefs.getString(_kPayments);
    if (payJson != null) {
      try {
        final list = jsonDecode(payJson) as List;
        payments = list.map((e) => Payment.fromJson(e)).toList();
      } catch (_) {}
    }

    final expJson = prefs.getString(_kExpenses);
    if (expJson != null) {
      try {
        final list = jsonDecode(expJson) as List;
        expenses = list.map((e) => Expense.fromJson(e)).toList();
      } catch (_) {}
    }

    loaded = true;
    notifyListeners();
  }

  // ─── Projects ───────────────────────────────────────────────────────────────
  void addProject(Project p) {
    projects.add(p);
    notifyListeners();
    _saveProjects();
  }

  void updateProject(Project p) {
    final idx = projects.indexWhere((x) => x.id == p.id);
    if (idx >= 0) projects[idx] = p;
    notifyListeners();
    _saveProjects();
  }

  void deleteProject(String id) {
    projects.removeWhere((p) => p.id == id);
    notifyListeners();
    _saveProjects();
  }

  String newProjectId() => _uuid.v4();
  String newRoomId()    => _uuid.v4();

  // ─── Rates ──────────────────────────────────────────────────────────────────
  void updateRates(List<LaborRate> r) {
    rates = r;
    notifyListeners();
    _saveRates();
  }

  void resetRates() {
    rates = defaultRates();
    notifyListeners();
    _saveRates();
  }

  // ─── Materials ──────────────────────────────────────────────────────────────
  void updateMaterials(MaterialPrices m) {
    materials = m;
    notifyListeners();
    _saveMaterials();
  }

  void resetMaterials() {
    materials = defaultMaterials();
    notifyListeners();
    _saveMaterials();
  }

  // ─── Payments ───────────────────────────────────────────────────────────────
  void addPayment(Payment p) {
    payments.add(p);
    notifyListeners();
    _savePayments();
  }

  void deletePayment(String id) {
    payments.removeWhere((p) => p.id == id);
    notifyListeners();
    _savePayments();
  }

  // ─── Expenses ───────────────────────────────────────────────────────────────
  void addExpense(Expense e) {
    expenses.add(e);
    notifyListeners();
    _saveExpenses();
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    _saveExpenses();
  }

  // ─── Persistence ────────────────────────────────────────────────────────────
  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProjects, jsonEncode(projects.map((p) => p.toJson()).toList()));
  }

  Future<void> _saveRates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRates, jsonEncode(rates.map((r) => r.toJson()).toList()));
  }

  Future<void> _saveMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMaterials, jsonEncode(materials.toJson()));
  }

  Future<void> _savePayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPayments, jsonEncode(payments.map((p) => p.toJson()).toList()));
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kExpenses, jsonEncode(expenses.map((e) => e.toJson()).toList()));
  }
}
