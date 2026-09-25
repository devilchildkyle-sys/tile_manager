import 'dart:convert';

// ─── Enums ────────────────────────────────────────────────────────────────────
enum Difficulty { easy, medium, hard }

extension DifficultyExt on Difficulty {
  String get label => name[0].toUpperCase() + name.substring(1);
  static Difficulty? fromString(String? s) =>
      s == null ? null : Difficulty.values.where((d) => d.name == s).firstOrNull;
}

// ─── Grout ────────────────────────────────────────────────────────────────────
class GroutData {
  String bags;
  String color;

  GroutData({this.bags = '', this.color = ''});

  factory GroutData.fromJson(Map<String, dynamic> j) => GroutData(
    bags: (j['bags'] ?? j['customBags'] ?? '').toString(),
    color: (j['color'] ?? '').toString());

  Map<String, dynamic> toJson() => {'bags': bags, 'color': color};
}

// ─── Simple Surface ───────────────────────────────────────────────────────────
class SimpleSurface {
  String sqFt;
  Difficulty? difficulty;
  GroutData grout;

  SimpleSurface({this.sqFt = '', this.difficulty, GroutData? grout})
      : grout = grout ?? GroutData();

  factory SimpleSurface.fromJson(Map<String, dynamic> j) => SimpleSurface(
    sqFt: j['sqFt'] ?? '', difficulty: DifficultyExt.fromString(j['difficulty']),
    grout: j['grout'] != null ? GroutData.fromJson(j['grout']) : GroutData());

  Map<String, dynamic> toJson() => {'sqFt': sqFt, 'difficulty': difficulty?.name,
    'grout': grout.toJson()};
}

// ─── Floor Data ───────────────────────────────────────────────────────────────
class FloorData {
  String sqFt;
  Difficulty? difficulty;
  bool floorMat, heatMat, raised, selfLevel;
  GroutData grout;

  FloorData({this.sqFt = '', this.difficulty, this.floorMat = false,
      this.heatMat = false, this.raised = false, this.selfLevel = false,
      GroutData? grout}) : grout = grout ?? GroutData();

  factory FloorData.fromJson(Map<String, dynamic> j) => FloorData(
    sqFt: j['sqFt'] ?? '', difficulty: DifficultyExt.fromString(j['difficulty']),
    floorMat: j['floorMat'] ?? false, heatMat: j['heatMat'] ?? false,
    raised: j['raised'] ?? false, selfLevel: j['selfLevel'] ?? false,
    grout: j['grout'] != null ? GroutData.fromJson(j['grout']) : GroutData());

  Map<String, dynamic> toJson() => {'sqFt': sqFt, 'difficulty': difficulty?.name,
    'floorMat': floorMat, 'heatMat': heatMat, 'raised': raised,
    'selfLevel': selfLevel, 'grout': grout.toJson()};
}

// ─── Base / Edge ──────────────────────────────────────────────────────────────
class BaseData {
  String linFt;
  Difficulty? difficulty;

  BaseData({this.linFt = '', this.difficulty});

  factory BaseData.fromJson(Map<String, dynamic> j) => BaseData(
    linFt: j['linFt'] ?? '', difficulty: DifficultyExt.fromString(j['difficulty']));

  Map<String, dynamic> toJson() => {'linFt': linFt, 'difficulty': difficulty?.name};
}

class EdgeData {
  bool enabled;
  String linFt;
  String type; // 'metal','miter','pencil'

  EdgeData({this.enabled = false, this.linFt = '', this.type = 'metal'});

  factory EdgeData.fromJson(Map<String, dynamic> j) => EdgeData(
    enabled: j['enabled'] ?? false, linFt: j['linFt'] ?? '', type: j['type'] ?? 'metal');

  Map<String, dynamic> toJson() => {'enabled': enabled, 'linFt': linFt, 'type': type};
}

// ─── Bench Data ───────────────────────────────────────────────────────────────
class BenchData {
  bool enabled;
  String size; // 'small','large'
  String notes;
  String boardQty;

  BenchData({this.enabled = false, this.size = 'small', this.notes = '', this.boardQty = ''});

  factory BenchData.fromJson(Map<String, dynamic> j) => BenchData(
    enabled: j['enabled'] ?? false, size: j['size'] ?? 'small',
    notes: j['notes'] ?? '', boardQty: j['boardQty'] ?? '');

  Map<String, dynamic> toJson() => {'enabled': enabled, 'size': size,
    'notes': notes, 'boardQty': boardQty};
}

// ─── Tub Data ─────────────────────────────────────────────────────────────────
class TubData {
  bool enabled;
  String wallSqFt;
  Difficulty? difficulty;
  String waterproofType; // 'membrane','foam','none'
  String membraneLinFt;
  String membraneHeight; // '5' or '6'
  String niches;
  String customNiches;
  String shelves;
  GroutData grout;

  TubData({this.enabled = false, this.wallSqFt = '', this.difficulty,
      this.waterproofType = 'none', this.membraneLinFt = '',
      this.membraneHeight = '5', this.niches = '', this.customNiches = '',
      this.shelves = '', GroutData? grout})
      : grout = grout ?? GroutData();

  factory TubData.fromJson(Map<String, dynamic> j) => TubData(
    enabled: j['enabled'] ?? false, wallSqFt: j['wallSqFt'] ?? '',
    difficulty: DifficultyExt.fromString(j['difficulty']),
    waterproofType: j['waterproofType'] ?? 'none',
    membraneLinFt: j['membraneLinFt'] ?? '', membraneHeight: j['membraneHeight'] ?? '5',
    niches: j['niches'] ?? '', customNiches: j['customNiches'] ?? '',
    shelves: j['shelves'] ?? '',
    grout: j['grout'] != null ? GroutData.fromJson(j['grout']) : GroutData());

  Map<String, dynamic> toJson() => {'enabled': enabled, 'wallSqFt': wallSqFt,
    'difficulty': difficulty?.name, 'waterproofType': waterproofType,
    'membraneLinFt': membraneLinFt, 'membraneHeight': membraneHeight,
    'niches': niches, 'customNiches': customNiches, 'shelves': shelves,
    'grout': grout.toJson()};
}

// ─── Pan / Shower Data ────────────────────────────────────────────────────────
class PanData {
  bool enabled;
  String widthIn, lengthIn, showerWallsSqFt;
  Difficulty? floorDifficulty, wallDifficulty;
  bool steamShower;
  String shelves;
  BenchData bench;
  String waterproofType; // 'membrane','foam','none'
  String showerLinFt;
  String foamPanSize; // '3x3','3x5','5x5','6x6'
  String drainType; // 'standard','tile'
  String curbType; // 'curb','curbless'
  String curbNote;
  String curbMaterial; // 'scrap','boards'
  String curbScrapLinFt;
  String curbBoardQty;
  String niches;
  String customNiches;
  GroutData floorGrout;
  GroutData wallGrout;

  PanData({
    this.enabled = false, this.widthIn = '', this.lengthIn = '',
    this.showerWallsSqFt = '', this.floorDifficulty, this.wallDifficulty,
    this.steamShower = false, this.shelves = '',
    BenchData? bench, this.waterproofType = 'membrane', this.showerLinFt = '',
    this.foamPanSize = '3x3', this.drainType = 'standard',
    this.curbType = 'curb', this.curbNote = '', this.curbMaterial = 'scrap',
    this.curbScrapLinFt = '', this.curbBoardQty = '',
    this.niches = '', this.customNiches = '',
    GroutData? floorGrout, GroutData? wallGrout,
  }) : bench = bench ?? BenchData(),
       floorGrout = floorGrout ?? GroutData(),
       wallGrout = wallGrout ?? GroutData();

  factory PanData.fromJson(Map<String, dynamic> j) => PanData(
    enabled: j['enabled'] ?? false, widthIn: j['widthIn'] ?? '',
    lengthIn: j['lengthIn'] ?? '', showerWallsSqFt: j['showerWallsSqFt'] ?? '',
    floorDifficulty: DifficultyExt.fromString(j['floorDifficulty']),
    wallDifficulty: DifficultyExt.fromString(j['wallDifficulty']),
    steamShower: j['steamShower'] ?? false, shelves: j['shelves'] ?? '',
    bench: j['bench'] != null ? BenchData.fromJson(j['bench']) : BenchData(),
    waterproofType: j['waterproofType'] ?? 'membrane',
    showerLinFt: j['showerLinFt'] ?? '', foamPanSize: j['foamPanSize'] ?? '3x3',
    drainType: j['drainType'] ?? 'standard', curbType: j['curbType'] ?? 'curb',
    curbNote: j['curbNote'] ?? '', curbMaterial: j['curbMaterial'] ?? 'scrap',
    curbScrapLinFt: j['curbScrapLinFt'] ?? '', curbBoardQty: j['curbBoardQty'] ?? '',
    niches: j['niches'] ?? '', customNiches: j['customNiches'] ?? '',
    floorGrout: j['floorGrout'] != null ? GroutData.fromJson(j['floorGrout']) : GroutData(),
    wallGrout: j['wallGrout'] != null ? GroutData.fromJson(j['wallGrout']) : GroutData(),
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled, 'widthIn': widthIn, 'lengthIn': lengthIn,
    'showerWallsSqFt': showerWallsSqFt, 'floorDifficulty': floorDifficulty?.name,
    'wallDifficulty': wallDifficulty?.name, 'steamShower': steamShower,
    'shelves': shelves, 'bench': bench.toJson(), 'waterproofType': waterproofType,
    'showerLinFt': showerLinFt, 'foamPanSize': foamPanSize, 'drainType': drainType,
    'curbType': curbType, 'curbNote': curbNote, 'curbMaterial': curbMaterial,
    'curbScrapLinFt': curbScrapLinFt, 'curbBoardQty': curbBoardQty,
    'niches': niches, 'customNiches': customNiches,
    'floorGrout': floorGrout.toJson(), 'wallGrout': wallGrout.toJson(),
  };
}

// ─── Bathroom ─────────────────────────────────────────────────────────────────
class Bathroom {
  String id, name;
  FloorData floor;
  SimpleSurface walls, ceiling, wainscot;
  BaseData base;
  EdgeData edging;
  PanData pan;
  TubData tub;

  Bathroom({required this.id, required this.name, FloorData? floor,
      SimpleSurface? walls, SimpleSurface? ceiling, SimpleSurface? wainscot,
      BaseData? base, EdgeData? edging, PanData? pan, TubData? tub})
      : floor = floor ?? FloorData(), walls = walls ?? SimpleSurface(),
        ceiling = ceiling ?? SimpleSurface(), wainscot = wainscot ?? SimpleSurface(),
        base = base ?? BaseData(), edging = edging ?? EdgeData(),
        pan = pan ?? PanData(), tub = tub ?? TubData();

  factory Bathroom.fromJson(Map<String, dynamic> j) => Bathroom(
    id: j['id'], name: j['name'],
    floor: FloorData.fromJson(j['floor'] ?? {}),
    walls: SimpleSurface.fromJson(j['walls'] ?? {}),
    ceiling: SimpleSurface.fromJson(j['ceiling'] ?? {}),
    wainscot: SimpleSurface.fromJson(j['wainscot'] ?? {}),
    base: BaseData.fromJson(j['base'] ?? {}),
    edging: EdgeData.fromJson(j['edging'] ?? {}),
    pan: PanData.fromJson(j['pan'] ?? {}),
    tub: TubData.fromJson(j['tub'] ?? {}),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'floor': floor.toJson(),
    'walls': walls.toJson(), 'ceiling': ceiling.toJson(), 'wainscot': wainscot.toJson(),
    'base': base.toJson(), 'edging': edging.toJson(), 'pan': pan.toJson(),
    'tub': tub.toJson()};
}

// ─── Generic Room (mud/laundry/other) ─────────────────────────────────────────
class Room {
  String id, name;
  FloorData floor;
  SimpleSurface walls;
  BaseData base;

  Room({required this.id, required this.name, FloorData? floor,
      SimpleSurface? walls, BaseData? base})
      : floor = floor ?? FloorData(), walls = walls ?? SimpleSurface(),
        base = base ?? BaseData();

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'], name: j['name'],
    floor: FloorData.fromJson(j['floor'] ?? {}),
    walls: SimpleSurface.fromJson(j['walls'] ?? {}),
    base: BaseData.fromJson(j['base'] ?? {}));

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'floor': floor.toJson(),
    'walls': walls.toJson(), 'base': base.toJson()};
}

// ─── Financial Records ────────────────────────────────────────────────────────
class PhotoRecord {
  String path;
  String name;
  PhotoRecord({required this.path, required this.name});
  factory PhotoRecord.fromJson(Map<String, dynamic> j) =>
      PhotoRecord(path: j['path'] ?? '', name: j['name'] ?? '');
  Map<String, dynamic> toJson() => {'path': path, 'name': name};
}

class Payment {
  String id, project, amount, note, date;
  PhotoRecord? photo;
  Payment({required this.id, this.project = '', this.amount = '',
      this.note = '', this.date = '', this.photo});
  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'] ?? '', project: j['project'] ?? '', amount: j['amount'] ?? '',
    note: j['note'] ?? '', date: j['date'] ?? '',
    photo: j['photo'] != null ? PhotoRecord.fromJson(j['photo']) : null);
  Map<String, dynamic> toJson() => {'id': id, 'project': project, 'amount': amount,
    'note': note, 'date': date, 'photo': photo?.toJson()};
}

class Expense {
  String id, label, amount, category, date;
  PhotoRecord? photo;
  Expense({required this.id, this.label = '', this.amount = '',
      this.category = 'Materials', this.date = '', this.photo});
  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] ?? '', label: j['label'] ?? '', amount: j['amount'] ?? '',
    category: j['category'] ?? 'Materials', date: j['date'] ?? '',
    photo: j['photo'] != null ? PhotoRecord.fromJson(j['photo']) : null);
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'amount': amount,
    'category': category, 'date': date, 'photo': photo?.toJson()};
}

// ─── Project ──────────────────────────────────────────────────────────────────
class Project {
  String id, name, contact, address;
  List<Bathroom> bathrooms;
  List<Room> mudRooms, laundryRooms, others;
  DateTime createdAt;

  Project({required this.id, required this.name, this.contact = '',
      this.address = '', List<Bathroom>? bathrooms, List<Room>? mudRooms,
      List<Room>? laundryRooms, List<Room>? others, DateTime? createdAt})
      : bathrooms = bathrooms ?? [], mudRooms = mudRooms ?? [],
        laundryRooms = laundryRooms ?? [], others = others ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'], name: j['name'], contact: j['contact'] ?? '',
    address: j['address'] ?? '',
    bathrooms: (j['bathrooms'] as List? ?? []).map((e) => Bathroom.fromJson(e)).toList(),
    mudRooms: (j['mudRooms'] as List? ?? []).map((e) => Room.fromJson(e)).toList(),
    laundryRooms: (j['laundryRooms'] as List? ?? []).map((e) => Room.fromJson(e)).toList(),
    others: (j['others'] as List? ?? []).map((e) => Room.fromJson(e)).toList(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'contact': contact,
    'address': address, 'bathrooms': bathrooms.map((e) => e.toJson()).toList(),
    'mudRooms': mudRooms.map((e) => e.toJson()).toList(),
    'laundryRooms': laundryRooms.map((e) => e.toJson()).toList(),
    'others': others.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String()};
}

// ─── Labor Rate ───────────────────────────────────────────────────────────────
class LaborRate {
  String id, name, unit;
  bool tiered; // true=tiered, false=flat
  double easy, medium, hard, rate;

  LaborRate({required this.id, required this.name, required this.unit,
      this.tiered = true, this.easy = 0, this.medium = 0, this.hard = 0,
      this.rate = 0});

  factory LaborRate.fromJson(Map<String, dynamic> j) => LaborRate(
    id: j['id'], name: j['name'], unit: j['unit'] ?? 'sq ft',
    tiered: j['tiered'] ?? true, easy: (j['easy'] ?? 0).toDouble(),
    medium: (j['medium'] ?? 0).toDouble(), hard: (j['hard'] ?? 0).toDouble(),
    rate: (j['rate'] ?? 0).toDouble());

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'unit': unit,
    'tiered': tiered, 'easy': easy, 'medium': medium, 'hard': hard, 'rate': rate};

  double rateFor(Difficulty? d) {
    if (!tiered) return rate;
    switch (d) {
      case Difficulty.easy: return easy;
      case Difficulty.medium: return medium;
      case Difficulty.hard: return hard;
      default: return 0;
    }
  }

  double get flatRate => tiered ? 0 : rate;
}

// ─── Material Prices ──────────────────────────────────────────────────────────
class MaterialPrices {
  double thinsetPrice, thinsetFloorCov, thinsetWallCov;
  double groutPrice;
  double wallMembranePrice, halfInchFoamPrice;
  double floorMatPrice, heatMatPrice, selfLevelPrice;
  double twoInchBoardPrice;
  double quarterInchBoardPrice;
  Map<String, double> foamPanPrices;
  double drainStandardPrice, drainTileGratePrice;
  double nicheStdPrice, nicheCustomPrice;
  double metalEdgePrice;

  MaterialPrices({
    this.thinsetPrice = 15, this.thinsetFloorCov = 30, this.thinsetWallCov = 40,
    this.groutPrice = 20, this.wallMembranePrice = 1.20, this.halfInchFoamPrice = 2.50,
    this.floorMatPrice = 1.20, this.heatMatPrice = 2.00, this.selfLevelPrice = 1.75,
    this.twoInchBoardPrice = 300,
    this.quarterInchBoardPrice = 12,
    Map<String, double>? foamPanPrices,
    this.drainStandardPrice = 85, this.drainTileGratePrice = 100,
    this.nicheStdPrice = 150, this.nicheCustomPrice = 400,
    this.metalEdgePrice = 5.00,
  }) : foamPanPrices = foamPanPrices ?? {'3x3': 110, '3x5': 150, '5x5': 300, '6x6': 310};

  factory MaterialPrices.fromJson(Map<String, dynamic> j) => MaterialPrices(
    thinsetPrice: (j['thinsetPrice'] ?? 15).toDouble(),
    thinsetFloorCov: (j['thinsetFloorCov'] ?? 30).toDouble(),
    thinsetWallCov: (j['thinsetWallCov'] ?? 40).toDouble(),
    groutPrice: (j['groutPrice'] ?? 20).toDouble(),
    wallMembranePrice: (j['wallMembranePrice'] ?? 1.20).toDouble(),
    halfInchFoamPrice: (j['halfInchFoamPrice'] ?? 2.50).toDouble(),
    floorMatPrice: (j['floorMatPrice'] ?? 1.20).toDouble(),
    heatMatPrice: (j['heatMatPrice'] ?? 2.00).toDouble(),
    selfLevelPrice: (j['selfLevelPrice'] ?? 1.75).toDouble(),
    twoInchBoardPrice: (j['twoInchBoardPrice'] ?? 300).toDouble(),
    quarterInchBoardPrice: (j['quarterInchBoardPrice'] ?? 12).toDouble(),
    foamPanPrices: (j['foamPanPrices'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble()))
        .cast<String, double>()
        .let((m) => m.isEmpty ? {'3x3': 110.0, '3x5': 150.0, '5x5': 300.0, '6x6': 310.0} : m),
    drainStandardPrice: (j['drainStandardPrice'] ?? 85).toDouble(),
    drainTileGratePrice: (j['drainTileGratePrice'] ?? 100).toDouble(),
    nicheStdPrice: (j['nicheStdPrice'] ?? 150).toDouble(),
    nicheCustomPrice: (j['nicheCustomPrice'] ?? 400).toDouble(),
    metalEdgePrice: (j['metalEdgePrice'] ?? 5.00).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'thinsetPrice': thinsetPrice, 'thinsetFloorCov': thinsetFloorCov,
    'thinsetWallCov': thinsetWallCov, 'groutPrice': groutPrice,
    'wallMembranePrice': wallMembranePrice, 'halfInchFoamPrice': halfInchFoamPrice,
    'floorMatPrice': floorMatPrice, 'heatMatPrice': heatMatPrice,
    'selfLevelPrice': selfLevelPrice, 'twoInchBoardPrice': twoInchBoardPrice,
    'quarterInchBoardPrice': quarterInchBoardPrice,
    'foamPanPrices': foamPanPrices, 'drainStandardPrice': drainStandardPrice,
    'drainTileGratePrice': drainTileGratePrice,
    'nicheStdPrice': nicheStdPrice, 'nicheCustomPrice': nicheCustomPrice,
    'metalEdgePrice': metalEdgePrice,
  };
}

// ignore: avoid_classes_with_only_static_members
extension ObjectExt<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
