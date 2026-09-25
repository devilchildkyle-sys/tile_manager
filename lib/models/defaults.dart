import 'models.dart';

List<LaborRate> defaultRates() => [
  LaborRate(id: 'floor',             name: 'Floor',                  unit: 'sq ft',  tiered: true,  easy: 8,    medium: 12,  hard: 15),
  LaborRate(id: 'showerFloor',       name: 'Shower Floor',           unit: 'sq ft',  tiered: true,  easy: 15,   medium: 20,  hard: 25),
  LaborRate(id: 'showerWall',        name: 'Shower Wall',            unit: 'sq ft',  tiered: true,  easy: 8,    medium: 12,  hard: 18),
  LaborRate(id: 'wall',              name: 'Wall',                   unit: 'sq ft',  tiered: true,  easy: 12,   medium: 14,  hard: 18),
  LaborRate(id: 'ceiling',           name: 'Ceiling',                unit: 'sq ft',  tiered: true,  easy: 14,   medium: 18,  hard: 22),
  LaborRate(id: 'tubWall',           name: 'Tub Wall',               unit: 'sq ft',  tiered: true,  easy: 12,   medium: 14,  hard: 18),
  LaborRate(id: 'wainscot',          name: 'Wainscot',               unit: 'sq ft',  tiered: true,  easy: 12,   medium: 14,  hard: 18),
  LaborRate(id: 'base',              name: 'Base',                   unit: 'lin ft', tiered: true,  easy: 2,    medium: 4,   hard: 7),
  LaborRate(id: 'metalEdge',         name: 'Metal Edge',             unit: 'lin ft', tiered: false, rate: 1.00),
  LaborRate(id: 'miterEdge',         name: 'Miter Edge',             unit: 'lin ft', tiered: false, rate: 20.00),
  LaborRate(id: 'pencilEdge',        name: 'Pencil Edge',            unit: 'lin ft', tiered: false, rate: 6.00),
  LaborRate(id: 'heatedUpcharge',    name: 'Heated Floor Upcharge',  unit: 'install',tiered: false, rate: 300),
  LaborRate(id: 'multiPrepUpcharge', name: 'Multi-Prep Upcharge',    unit: 'sq ft',  tiered: false, rate: 1),
  LaborRate(id: 'shelf',             name: 'Shelf (each)',           unit: 'each',   tiered: false, rate: 80),
  LaborRate(id: 'benchSmall',        name: 'Bench — Small/Corner',   unit: 'install',tiered: false, rate: 250),
  LaborRate(id: 'benchLarge',        name: 'Bench — Large',          unit: 'install',tiered: false, rate: 600),
];

MaterialPrices defaultMaterials() => MaterialPrices();
