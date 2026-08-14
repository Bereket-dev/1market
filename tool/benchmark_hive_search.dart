// Koolan — Hive search benchmark
//
// Compares two local search strategies at 1k/5k/10k simulated listing rows:
//   A. Full-scan: iterate all entries, decode JSON, check title.contains(query)
//   B. Token-index: inverted index lookup (token → [entityId]) like SearchIndexService
//
// Run:
//   dart run tool/benchmark_hive_search.dart
//
// No Flutter or Hive dependency — uses in-memory Maps to simulate box access.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math';

// ---------------------------------------------------------------------------
// Mock data generation
// ---------------------------------------------------------------------------

const _locations = [
  'Jigjiga',
  'Dire Dawa',
  'Harar',
  'Dega Habur',
  'Kebri Dahar',
  'Gode',
  'Degehabur',
  'Shinile',
];

const _categories = [
  'CARS',
  'ELECTRONICS',
  'REAL_ESTATE',
  'FASHION',
  'FURNITURE',
  'JOBS',
  'SERVICES',
  'FOOD',
];

// Title templates — Toyota appears in ~10 % of entries (every ~10th entry).
const _titleTemplates = [
  'Toyota Corolla {year} — ሽያጭ ሞቶር',
  'Toyota Land Cruiser {year} for sale',
  'iPhone {year} Pro Max — ኤሌክትሮኒክስ',
  'Samsung Galaxy S{year} new in box',
  'Sofa set — ምቹ ወንበር ለቤት',
  'Apartment for rent in {loc}',
  'Honda Civic {year} — ጥሩ ሁኔታ',
  'Laptop Dell Inspiron {year}',
  'Mitsubishi Pajero {year} 4x4',
  'Huawei MatePad Pro — tablet',
];

const _descriptions = [
  'በጥሩ ሁኔታ ላይ ይገኛል። ቀለም ነጭ፣ ሙሉ ሰነዶች አሉ።',
  'Very clean, single owner, full service history.',
  'ለዝርዝር ይደውሉ። ዋጋ ይደራደራል።',
  'Brand new, sealed box, original accessories included.',
  'Used but well-maintained. Negotiable price.',
  'First come first served. Serious buyers only.',
  'ለቤት ወይም ለቢሮ ይሆናል። ዋጋ ተገቢ ነው።',
  'Contact via WhatsApp for photos and location.',
];

/// Generates a UUID-ish string from a seeded random.
String _makeId(Random rng) {
  final hex = List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '4${hex.substring(13, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

/// Build the mock listing JSON string for a given index.
String _makeListing(int index, Random rng) {
  final templateIndex = index % _titleTemplates.length;
  var title = _titleTemplates[templateIndex]
      .replaceAll('{year}', (2018 + rng.nextInt(7)).toString())
      .replaceAll('{loc}', _locations[rng.nextInt(_locations.length)]);

  final map = {
    'id': _makeId(rng),
    'title': title,
    'location': _locations[rng.nextInt(_locations.length)],
    'category': _categories[rng.nextInt(_categories.length)],
    'price': (rng.nextInt(500) + 10) * 1000,
    'description': _descriptions[rng.nextInt(_descriptions.length)],
    'created_at': '2025-0${1 + rng.nextInt(9)}-${10 + rng.nextInt(20)}T10:00:00Z',
  };
  return jsonEncode(map);
}

// ---------------------------------------------------------------------------
// Data-structure builders
// ---------------------------------------------------------------------------

/// Strategy A box: key → JSON string (simulates a Hive LazyBox).
Map<String, String> buildFullScanBox(int rows) {
  final rng = Random(42); // fixed seed for reproducibility
  final box = <String, String>{};
  for (var i = 0; i < rows; i++) {
    final json = _makeListing(i, rng);
    // Use the index as key (Hive auto-increments int keys by default).
    box[i.toString()] = json;
  }
  return box;
}

/// Strategy B: inverted token index (token → list of keys) + the same box.
({Map<String, String> box, Map<String, List<String>> index})
    buildTokenIndexBox(int rows) {
  final rng = Random(42); // same seed — same data as strategy A
  final box = <String, String>{};
  final index = <String, List<String>>{};

  for (var i = 0; i < rows; i++) {
    final json = _makeListing(i, rng);
    final key = i.toString();
    box[key] = json;

    // Tokenise title (lower-case words) — mirrors SearchIndexService logic.
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final title = (decoded['title'] as String).toLowerCase();
    final tokens = title
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u1200-\u137F\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toSet();

    for (final token in tokens) {
      index.putIfAbsent(token, () => <String>[]).add(key);
    }
  }
  return (box: box, index: index);
}

// ---------------------------------------------------------------------------
// Search strategies
// ---------------------------------------------------------------------------

/// Strategy A: full-scan — decode every entry, check title.contains(query).
List<Map<String, dynamic>> fullScan(
    Map<String, String> box, String query) {
  final q = query.toLowerCase();
  final results = <Map<String, dynamic>>[];
  for (final json in box.values) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    if ((decoded['title'] as String).toLowerCase().contains(q)) {
      results.add(decoded);
    }
  }
  return results;
}

/// Strategy B: token-index lookup.
List<Map<String, dynamic>> tokenIndexSearch(
    Map<String, String> box,
    Map<String, List<String>> index,
    String query) {
  final token = query.toLowerCase();
  final keys = index[token] ?? const <String>[];
  final results = <Map<String, dynamic>>[];
  for (final key in keys) {
    final json = box[key];
    if (json != null) {
      results.add(jsonDecode(json) as Map<String, dynamic>);
    }
  }
  return results;
}

// ---------------------------------------------------------------------------
// Benchmark helpers
// ---------------------------------------------------------------------------

/// Run [fn] [runs] times and return elapsed microseconds for each run.
List<int> _measure(int runs, void Function() fn) {
  final times = <int>[];
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    fn();
    sw.stop();
    times.add(sw.elapsedMicroseconds);
  }
  return times;
}

/// Median of a list of ints (sorts a copy).
int _median(List<int> values) {
  final sorted = List<int>.from(values)..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) ~/ 2;
}

// ---------------------------------------------------------------------------
// Table printing
// ---------------------------------------------------------------------------

String _fmt(int n) {
  // Comma-format integers.
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtRatio(double r) => '${r.toStringAsFixed(1)}x';

void _printTable(List<({int rows, int fullUs, int idxUs})> data) {
  const w1 = 11; // Rows column
  const w2 = 16; // Full-scan column
  const w3 = 16; // Token-idx column
  const w4 = 7;  // Ratio column

  String pad(String s, int width, {bool right = false}) {
    if (right) return s.padLeft(width);
    return s.padRight(width);
  }

  // Total inner width = columns + 3 inner column separators (╦ chars).
  const innerWidth = w1 + w2 + w3 + w4 + 3;
  const title = 'Koolan Hive search benchmark (in-memory)';
  // Centre the title within innerWidth.
  final leftPad = (innerWidth - title.length) ~/ 2;
  final rightPad = innerWidth - title.length - leftPad;
  final header = ' ' * leftPad + title + ' ' * rightPad;

  // Top border
  print('╔${'═' * innerWidth}╗');
  print('║$header║');

  // Column header separator
  print('╠${'═' * w1}╦${'═' * w2}╦${'═' * w3}╦${'═' * w4}╣');

  // Column headers
  print('║${pad(' Rows', w1)}║'
      '${pad(' Full-scan (µs)', w2)}║'
      '${pad(' Token-idx (µs)', w3)}║'
      '${pad(' Ratio', w4)}║');

  // Sub-header separator
  print('╠${'═' * w1}╬${'═' * w2}╬${'═' * w3}╬${'═' * w4}╣');

  // Data rows
  for (final row in data) {
    final rowsFmt = _fmt(row.rows).padLeft(w1 - 1);
    final fullFmt = _fmt(row.fullUs).padLeft(w2 - 1);
    final idxFmt = _fmt(row.idxUs).padLeft(w3 - 1);
    final ratio = row.idxUs > 0 ? row.fullUs / row.idxUs : double.infinity;
    final ratioFmt = _fmtRatio(ratio).padLeft(w4 - 1);

    print('║ $rowsFmt ║ $fullFmt ║ $idxFmt ║ $ratioFmt ║');
  }

  // Bottom border
  print('╚${'═' * w1}╩${'═' * w2}╩${'═' * w3}╩${'═' * w4}╝');
  print('Ratio = full-scan / token-index. Higher = more token-index wins.');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  const rowCounts = [1000, 5000, 10000];
  const query = 'toyota'; // ~10 % of titles contain "Toyota"
  const runs = 3;

  final results = <({int rows, int fullUs, int idxUs})>[];

  for (final rows in rowCounts) {
    print('Building data for $rows rows...');

    // Build strategy-A box.
    final boxA = buildFullScanBox(rows);

    // Build strategy-B structures (same data, same seed).
    final (:box, :index) = buildTokenIndexBox(rows);

    final fullTimes = _measure(runs, () => fullScan(boxA, query));
    final fullMedian = _median(fullTimes);
    print('  Full-scan   ($runs runs): median ${_fmt(fullMedian)} µs  '
        '[${fullTimes.map(_fmt).join(', ')} µs]');

    final idxTimes = _measure(runs, () => tokenIndexSearch(box, index, query));
    final idxMedian = _median(idxTimes);
    print('  Token-index ($runs runs): median ${_fmt(idxMedian)} µs  '
        '[${idxTimes.map(_fmt).join(', ')} µs]');

    results.add((rows: rows, fullUs: fullMedian, idxUs: idxMedian));
  }

  print('');
  _printTable(results);
}
