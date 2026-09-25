import '../models/models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────
double n(String? s) => double.tryParse(s?.trim() ?? '') ?? 0;
int ni(String? s) => int.tryParse(s?.trim() ?? '') ?? 0;

double _rateFor(List<LaborRate> rates, String id, Difficulty? diff) {
  final match = rates.where((rate) => rate.id == id).firstOrNull;
  if (match == null) return 0;
  return match.rateFor(diff);
}

int _groutBags(GroutData g) => ni(g.bags);

// ─── Cost Lines ───────────────────────────────────────────────────────────────
class CostLine {
  final String label;
  final String qty;
  final String unit;
  final double rate;
  final double cost;
  final String? difficulty;

  const CostLine({required this.label, required this.qty, required this.unit,
      required this.rate, required this.cost, this.difficulty});
}

// ─── Room Breakdown ───────────────────────────────────────────────────────────
class RoomBreakdown {
  final String name;
  final List<CostLine> laborLines;
  final List<CostLine> matLines;

  RoomBreakdown({required this.name, required this.laborLines, required this.matLines});

  double get labor => laborLines.fold(0, (s, l) => s + l.cost);
  double get materials => matLines.fold(0, (s, l) => s + l.cost);
  double get total => labor + materials;
}

// ─── Project Breakdown ────────────────────────────────────────────────────────
class ProjectBreakdown {
  final List<RoomBreakdown> rooms;
  ProjectBreakdown(this.rooms);
  double get labor => rooms.fold(0, (s, r) => s + r.labor);
  double get materials => rooms.fold(0, (s, r) => s + r.materials);
  double get total => labor + materials;
}

// ─── Footage Totals ───────────────────────────────────────────────────────────
class FootageTotals {
  double floor, walls, waterproofSqFt, base, ceiling;
  FootageTotals({this.floor = 0, this.walls = 0, this.waterproofSqFt = 0,
      this.base = 0, this.ceiling = 0});
}

// ─── Material Summary ─────────────────────────────────────────────────────────
class MaterialSummary {
  double thinsetFloor = 0, thinsetWall = 0, grout = 0;
  double membrane = 0, foamBoard = 0;
  double floorMat = 0, heatMat = 0, selfLevel = 0, raisedFloorSqFt = 0;
  int heatInstalls = 0;
  double boardSheets = 0;
  Map<String, int> foamPans = {'3x3': 0, '3x5': 0, '5x5': 0, '6x6': 0};
  int drainStandard = 0, drainTile = 0;
  int nichesStd = 0, nichesCustom = 0;
  int metalEdgeSticks = 0;
}

// ─── Bathroom Calculations ────────────────────────────────────────────────────
RoomBreakdown calcBathroomBreakdown(
    Bathroom bath, List<LaborRate> rates, MaterialPrices M) {
  final labor = <CostLine>[];
  final mats = <CostLine>[];

  void addL(String label, double qty, String unit, double rate,
      {String? diff, bool isNote = false}) {
    if (qty > 0 && rate > 0)
      labor.add(CostLine(label: label, qty: qty.toStringAsFixed(1), unit: unit,
          rate: rate, cost: qty * rate, difficulty: diff));
  }
  void addM(String label, double qty, String unit, double rate) {
    if (qty > 0 && rate > 0)
      mats.add(CostLine(label: label, qty: qty.toStringAsFixed(2), unit: unit,
          rate: rate, cost: qty * rate));
  }
  void addMFlat(String label, double cost) {
    if (cost > 0) mats.add(CostLine(label: label, qty: '1', unit: 'each',
        rate: cost, cost: cost));
  }

  // Floor
  final fSqFt = n(bath.floor.sqFt);
  final panSqFt = bath.pan.enabled
      ? (n(bath.pan.widthIn) * n(bath.pan.lengthIn)) / 144 : 0.0;
  final totalFloor = fSqFt + panSqFt;
  if (totalFloor > 0 && bath.floor.difficulty != null) {
    addL('Floor', fSqFt, 'sq ft', _rateFor(rates, 'floor', bath.floor.difficulty),
        diff: bath.floor.difficulty?.label);
  }
  if (panSqFt > 0 && bath.pan.floorDifficulty != null) {
    addL('Shower Floor (Pan)', panSqFt, 'sq ft',
        _rateFor(rates, 'showerFloor', bath.pan.floorDifficulty),
        diff: bath.pan.floorDifficulty?.label);
  }

  // Floor options
  final activeOpts = [bath.floor.floorMat, bath.floor.heatMat,
      bath.floor.raised, bath.floor.selfLevel].where((b) => b).length;
  if (bath.floor.heatMat) {
    final u = _rateFor(rates, 'heatedUpcharge', null);
    if (u > 0) addL('Heated Floor Upcharge', 1, 'install', u);
  }
  if (activeOpts >= 2) {
    final u = _rateFor(rates, 'multiPrepUpcharge', null);
    if (u > 0 && fSqFt > 0) addL('Multi-Prep Upcharge', fSqFt, 'sq ft', u);
  }

  // Walls
  final wSqFt = n(bath.walls.sqFt);
  if (wSqFt > 0 && bath.walls.difficulty != null)
    addL('Walls', wSqFt, 'sq ft', _rateFor(rates, 'wall', bath.walls.difficulty),
        diff: bath.walls.difficulty?.label);

  // Ceiling
  final cSqFt = n(bath.ceiling.sqFt);
  if (cSqFt > 0 && bath.ceiling.difficulty != null)
    addL('Ceiling', cSqFt, 'sq ft', _rateFor(rates, 'ceiling', bath.ceiling.difficulty),
        diff: bath.ceiling.difficulty?.label);

  // Shower walls
  final swSqFt = bath.pan.enabled ? n(bath.pan.showerWallsSqFt) : 0.0;
  if (swSqFt > 0 && bath.pan.wallDifficulty != null)
    addL('Shower Walls', swSqFt, 'sq ft',
        _rateFor(rates, 'showerWall', bath.pan.wallDifficulty),
        diff: bath.pan.wallDifficulty?.label);

  // Tub walls
  if (bath.tub.enabled) {
    final twSqFt = n(bath.tub.wallSqFt);
    if (twSqFt > 0 && bath.tub.difficulty != null)
      addL('Tub Walls', twSqFt, 'sq ft',
          _rateFor(rates, 'tubWall', bath.tub.difficulty),
          diff: bath.tub.difficulty?.label);
    final tShQty = ni(bath.tub.shelves);
    if (tShQty > 0) addL('Tub Shelves ×$tShQty', tShQty.toDouble(), 'each',
        _rateFor(rates, 'shelf', null));
  }

  // Wainscot
  final wcSqFt = n(bath.wainscot.sqFt);
  if (wcSqFt > 0 && bath.wainscot.difficulty != null)
    addL('Wainscot', wcSqFt, 'sq ft',
        _rateFor(rates, 'wainscot', bath.wainscot.difficulty),
        diff: bath.wainscot.difficulty?.label);

  // Base
  final bLinFt = n(bath.base.linFt);
  if (bLinFt > 0 && bath.base.difficulty != null)
    addL('Base', bLinFt, 'lin ft', _rateFor(rates, 'base', bath.base.difficulty),
        diff: bath.base.difficulty?.label);

  // Edging
  if (bath.edging.enabled) {
    final eLinFt = n(bath.edging.linFt);
    final eRateId = {'metal': 'metalEdge', 'miter': 'miterEdge',
        'pencil': 'pencilEdge'}[bath.edging.type] ?? 'metalEdge';
    if (eLinFt > 0) {
      addL('${bath.edging.type[0].toUpperCase()}${bath.edging.type.substring(1)} Edge',
          eLinFt, 'lin ft', _rateFor(rates, eRateId, null));
      if (bath.edging.type == 'metal') {
        final sticks = (eLinFt / 8).ceil().toDouble();
        addM('Metal Edge (${sticks.toInt()} sticks @ 8ft)', sticks, 'stick', M.metalEdgePrice);
      }
    }
  }

  // Shelves
  if (bath.pan.enabled) {
    final shQty = ni(bath.pan.shelves);
    if (shQty > 0) addL('Shelves ×$shQty', shQty.toDouble(), 'each',
        _rateFor(rates, 'shelf', null));

    // Bench
    if (bath.pan.bench.enabled) {
      final bRateId = bath.pan.bench.size == 'large' ? 'benchLarge' : 'benchSmall';
      final bRate = _rateFor(rates, bRateId, null);
      if (bRate > 0) addL('Bench (${bath.pan.bench.size})', 1, 'install', bRate);
    }
  }

  // ─── Materials ───────────────────────────────────────────────────────────────
  // Thinset — floor (heat mat +50%, raised floor +25%, pan stays at base rate)
  if (M.thinsetFloorCov > 0) {
    double mult = 1.0;
    if (bath.floor.heatMat) mult += 0.5;
    if (bath.floor.raised)  mult += 0.25;
    final adjustedFloor = fSqFt * mult + panSqFt;
    if (adjustedFloor > 0)
      addM('Thinset — Floor', (adjustedFloor / M.thinsetFloorCov).ceil().toDouble(),
          'bags', M.thinsetPrice);
  }

  // Thinset — walls/ceiling
  final totalWall = wSqFt + swSqFt + (bath.tub.enabled ? n(bath.tub.wallSqFt) : 0)
      + cSqFt + wcSqFt;
  if (totalWall > 0 && M.thinsetWallCov > 0)
    addM('Thinset — Walls/Ceiling', (totalWall / M.thinsetWallCov).ceil().toDouble(),
        'bags', M.thinsetPrice);

  // Grout
  void addGrout(String surfLabel, GroutData g) {
    final bags = _groutBags(g);
    if (bags > 0) addM('Grout — $surfLabel', bags.toDouble(), 'bags', M.groutPrice);
  }
  addGrout('Floor', bath.floor.grout);
  addGrout('Shower Floor', bath.pan.floorGrout);
  addGrout('Shower Walls', bath.pan.wallGrout);
  addGrout('Walls', bath.walls.grout);
  addGrout('Ceiling', bath.ceiling.grout);
  if (bath.tub.enabled) {
    final twSqFt = n(bath.tub.wallSqFt);
    if (twSqFt > 0) addGrout('Tub Walls', bath.tub.grout);

    // Tub waterproofing
    final tubWType = bath.tub.waterproofType;
    if (tubWType == 'membrane') {
      final height = n(bath.tub.membraneHeight.isEmpty ? '5' : bath.tub.membraneHeight);
      final membSqFt = n(bath.tub.membraneLinFt) * height;
      if (membSqFt > 0) addM('Wall Membrane (Tub)', membSqFt, 'sq ft', M.wallMembranePrice);
    } else if (tubWType == 'foam' && twSqFt > 0) {
      addM('½" Foam Board (tub walls)', twSqFt, 'sq ft', M.halfInchFoamPrice);
    }

    // Tub niches
    final tNSt = ni(bath.tub.niches), tNCu = ni(bath.tub.customNiches);
    if (tNSt > 0) addM('Tub Niche ×$tNSt', tNSt.toDouble(), 'each', M.nicheStdPrice);
    if (tNCu > 0) addM('Tub Custom Niche ×$tNCu', tNCu.toDouble(), 'each', M.nicheCustomPrice);
  }
  addGrout('Wainscot', bath.wainscot.grout);

  // Waterproofing
  if (bath.pan.enabled) {
    // Foam pan liner — always
    final fpPrice = M.foamPanPrices[bath.pan.foamPanSize] ?? 0;
    if (fpPrice > 0) addMFlat('Foam Pan Liner (${bath.pan.foamPanSize})', fpPrice);

    // Shower wall waterproofing
    final wType = bath.pan.waterproofType;
    if (wType == 'membrane') {
      final membSqFt = bath.pan.steamShower
          ? swSqFt + cSqFt
          : n(bath.pan.showerLinFt) * 6;
      addM('Wall Membrane', membSqFt, 'sq ft', M.wallMembranePrice);
    } else if (wType == 'foam') {
      final foamSqFt = swSqFt + (bath.pan.steamShower ? cSqFt : 0);
      addM('½" Foam Board (walls)', foamSqFt, 'sq ft', M.halfInchFoamPrice);
    }

    // Drain
    final dPrice = bath.pan.drainType == 'tile'
        ? M.drainTileGratePrice : M.drainStandardPrice;
    addMFlat('Drain (${bath.pan.drainType == 'tile' ? 'Tile Grate' : 'Standard'})', dPrice);

    // Niches
    final nSt = ni(bath.pan.niches), nCu = ni(bath.pan.customNiches);
    if (nSt > 0) addM('Niche ×$nSt', nSt.toDouble(), 'each', M.nicheStdPrice);
    if (nCu > 0) addM('Custom Niche ×$nCu', nCu.toDouble(), 'each', M.nicheCustomPrice);

    // 2" Board — bench
    if (bath.pan.bench.enabled && ni(bath.pan.bench.boardQty) > 0) {
      addM('2" Board (bench) ×${bath.pan.bench.boardQty}',
          ni(bath.pan.bench.boardQty).toDouble(), 'sheet', M.twoInchBoardPrice);
    }
    // 2" Board — curb (only when no bench)
    if (bath.pan.curbType == 'curb' && !bath.pan.bench.enabled) {
      if (bath.pan.curbMaterial == 'scrap' && n(bath.pan.curbScrapLinFt) > 0) {
        final lf = n(bath.pan.curbScrapLinFt);
        final frac = lf > 5 ? 0.25 : 0.125;
        mats.add(CostLine(label: '2" Board scrap (curb ${lf.toStringAsFixed(1)} lf)',
            qty: frac.toString(), unit: 'sheet', rate: M.twoInchBoardPrice,
            cost: M.twoInchBoardPrice * frac));
      } else if (bath.pan.curbMaterial == 'boards' && ni(bath.pan.curbBoardQty) > 0) {
        addM('2" Board (curb) ×${bath.pan.curbBoardQty}',
            ni(bath.pan.curbBoardQty).toDouble(), 'sheet', M.twoInchBoardPrice);
      }
    }
  }

  // Floor materials
  if (fSqFt > 0) {
    if (bath.floor.floorMat) addM('Floor Mat', fSqFt, 'sq ft', M.floorMatPrice);
    if (bath.floor.heatMat)  addM('Heat Mat',  fSqFt, 'sq ft', M.heatMatPrice);
    if (bath.floor.selfLevel) addM('Self Leveler', fSqFt, 'sq ft', M.selfLevelPrice);
    if (bath.floor.raised) {
      final sheets = (fSqFt / 15).ceil().toDouble();
      addM('¼" Cement Board (~${sheets.toInt()} sheets)',
          sheets, 'sheet', M.quarterInchBoardPrice);
    }
  }

  return RoomBreakdown(name: bath.name, laborLines: labor, matLines: mats);
}

// ─── Generic Room Breakdown ───────────────────────────────────────────────────
RoomBreakdown calcRoomBreakdown(Room room, List<LaborRate> rates, MaterialPrices M) {
  final labor = <CostLine>[];
  final mats  = <CostLine>[];

  void addL(String label, double qty, String unit, double rate, {String? diff}) {
    if (qty > 0 && rate > 0)
      labor.add(CostLine(label: label, qty: qty.toStringAsFixed(1), unit: unit,
          rate: rate, cost: qty * rate, difficulty: diff));
  }
  void addM(String label, double qty, String unit, double rate) {
    if (qty > 0 && rate > 0)
      mats.add(CostLine(label: label, qty: qty.toStringAsFixed(2), unit: unit,
          rate: rate, cost: qty * rate));
  }

  final fSqFt = n(room.floor.sqFt);
  if (fSqFt > 0 && room.floor.difficulty != null)
    addL('Floor', fSqFt, 'sq ft', _rateFor(rates, 'floor', room.floor.difficulty),
        diff: room.floor.difficulty?.label);

  final activeOpts = [room.floor.floorMat, room.floor.heatMat,
      room.floor.raised, room.floor.selfLevel].where((b) => b).length;
  if (room.floor.heatMat) {
    final u = _rateFor(rates, 'heatedUpcharge', null);
    if (u > 0) addL('Heated Floor Upcharge', 1, 'install', u);
  }
  if (activeOpts >= 2) {
    final u = _rateFor(rates, 'multiPrepUpcharge', null);
    if (u > 0 && fSqFt > 0) addL('Multi-Prep Upcharge', fSqFt, 'sq ft', u);
  }

  final wSqFt = n(room.walls.sqFt);
  if (wSqFt > 0 && room.walls.difficulty != null)
    addL('Walls', wSqFt, 'sq ft', _rateFor(rates, 'wall', room.walls.difficulty),
        diff: room.walls.difficulty?.label);

  final bLinFt = n(room.base.linFt);
  if (bLinFt > 0 && room.base.difficulty != null)
    addL('Base', bLinFt, 'lin ft', _rateFor(rates, 'base', room.base.difficulty),
        diff: room.base.difficulty?.label);

  // Thinset — floor (heat mat +50%, raised +25%)
  if (fSqFt > 0 && M.thinsetFloorCov > 0) {
    double mult = 1.0;
    if (room.floor.heatMat) mult += 0.5;
    if (room.floor.raised)  mult += 0.25;
    addM('Thinset — Floor', (fSqFt * mult / M.thinsetFloorCov).ceil().toDouble(), 'bags', M.thinsetPrice);
  }
  if (wSqFt > 0 && M.thinsetWallCov > 0)
    addM('Thinset — Walls', (wSqFt / M.thinsetWallCov).ceil().toDouble(), 'bags', M.thinsetPrice);

  // Grout
  {
    final bags = _groutBags(room.floor.grout);
    if (bags > 0) addM('Grout — Floor', bags.toDouble(), 'bags', M.groutPrice);
    final wallBags = _groutBags(room.walls.grout);
    if (wallBags > 0) addM('Grout — Walls', wallBags.toDouble(), 'bags', M.groutPrice);
  }

  // Floor mats
  if (fSqFt > 0) {
    if (room.floor.floorMat) addM('Floor Mat', fSqFt, 'sq ft', M.floorMatPrice);
    if (room.floor.heatMat)  addM('Heat Mat',  fSqFt, 'sq ft', M.heatMatPrice);
    if (room.floor.selfLevel) addM('Self Leveler', fSqFt, 'sq ft', M.selfLevelPrice);
    if (room.floor.raised) {
      final sheets = (fSqFt / 16).ceil().toDouble();
      addM('¼" Cement Board (~${(fSqFt / 15).ceil()} sheets)',
          (fSqFt / 15).ceil().toDouble(), 'sheet', M.quarterInchBoardPrice);
    }
  }

  return RoomBreakdown(name: room.name, laborLines: labor, matLines: mats);
}

// ─── Project Breakdown ────────────────────────────────────────────────────────
ProjectBreakdown calcProjectBreakdown(
    Project proj, List<LaborRate> rates, MaterialPrices mats) {
  final rooms = <RoomBreakdown>[];
  for (final b in proj.bathrooms) rooms.add(calcBathroomBreakdown(b, rates, mats));
  for (final r in [...proj.mudRooms, ...proj.laundryRooms, ...proj.others])
    rooms.add(calcRoomBreakdown(r, rates, mats));
  return ProjectBreakdown(rooms);
}

// ─── Footage Totals ───────────────────────────────────────────────────────────
FootageTotals calcProjectFootage(Project proj) {
  double floor = 0, tileWalls = 0, waterproof = 0, base = 0, ceiling = 0;
  for (final b in proj.bathrooms) {
    final panSqFt = b.pan.enabled ? (n(b.pan.widthIn) * n(b.pan.lengthIn)) / 144 : 0.0;
    floor += n(b.floor.sqFt) + panSqFt;
    tileWalls += n(b.walls.sqFt) + (b.pan.enabled ? n(b.pan.showerWallsSqFt) : 0)
        + (b.tub.enabled ? n(b.tub.wallSqFt) : 0);
    ceiling += n(b.ceiling.sqFt);
    base += n(b.base.linFt);
    if (b.pan.enabled) {
      final wt = b.pan.waterproofType;
      if (wt == 'membrane') {
        waterproof += b.pan.steamShower
            ? n(b.pan.showerWallsSqFt) + n(b.ceiling.sqFt)
            : n(b.pan.showerLinFt) * 6;
      } else if (wt == 'foam') {
        waterproof += n(b.pan.showerWallsSqFt) + (b.pan.steamShower ? n(b.ceiling.sqFt) : 0);
      }
    }
    if (b.tub.enabled) {
      final tt = b.tub.waterproofType;
      if (tt == 'membrane') {
        waterproof += n(b.tub.membraneLinFt) * n(b.tub.membraneHeight.isEmpty ? '5' : b.tub.membraneHeight);
      } else if (tt == 'foam') {
        waterproof += n(b.tub.wallSqFt);
      }
    }
  }
  for (final r in [...proj.mudRooms, ...proj.laundryRooms, ...proj.others]) {
    floor += n(r.floor.sqFt);
    tileWalls += n(r.walls.sqFt);
    base += n(r.base.linFt);
  }
  return FootageTotals(floor: floor, walls: tileWalls, waterproofSqFt: waterproof,
      base: base, ceiling: ceiling);
}

// ─── Material Summary ─────────────────────────────────────────────────────────
MaterialSummary calcMaterialSummary(
    Project proj, List<LaborRate> rates, MaterialPrices M) {
  final s = MaterialSummary();
  for (final b in proj.bathrooms) {
    final ml = calcBathroomBreakdown(b, rates, M).matLines;
    for (final l in ml) {
      final q = double.tryParse(l.qty) ?? 0;
      final lb = l.label;
      if (lb.startsWith('Thinset — Floor'))         s.thinsetFloor += q;
      else if (lb.startsWith('Thinset — Wall'))      s.thinsetWall += q;
      else if (lb.startsWith('Grout'))               s.grout += q;
      else if (lb.startsWith('Wall Membrane'))       s.membrane += q;
      else if (lb.contains('Foam Board'))             s.foamBoard += q;
      else if (lb.startsWith('Floor Mat'))           s.floorMat += q;
      else if (lb.startsWith('Heat Mat'))            { s.heatMat += q; s.heatInstalls++; }
      else if (lb.startsWith('Self Leveler'))        s.selfLevel += q;
      else if (lb.contains('¼" Cement Board'))        s.raisedFloorSqFt += n(b.floor.sqFt);
      else if (lb.contains('2" Board'))               s.boardSheets += q;
      else if (lb.startsWith('Foam Pan Liner')) {
        final m = RegExp(r'\(([^)]+)\)').firstMatch(lb);
        if (m != null) {
          final size = m.group(1)!;
          s.foamPans[size] = (s.foamPans[size] ?? 0) + 1;
        }
      }
      else if (lb.startsWith('Drain')) {
        if (lb.contains('Tile')) s.drainTile++;
        else s.drainStandard++;
      }
      else if (lb.startsWith('Niche ×'))        s.nichesStd += q.toInt();
      else if (lb.startsWith('Custom Niche'))    s.nichesCustom += q.toInt();
      else if (lb.startsWith('Metal Edge'))      s.metalEdgeSticks += q.toInt();
    }
  }
  for (final r in [...proj.mudRooms, ...proj.laundryRooms, ...proj.others]) {
    final fSqFt = n(r.floor.sqFt);
    if (r.floor.floorMat && fSqFt > 0) s.floorMat += fSqFt;
    if (r.floor.heatMat  && fSqFt > 0) { s.heatMat += fSqFt; s.heatInstalls++; }
    if (r.floor.selfLevel && fSqFt > 0) s.selfLevel += fSqFt;
    if (r.floor.raised   && fSqFt > 0) s.raisedFloorSqFt += fSqFt;
  }
  return s;
}
