part of '../category_list_screen.dart';

// ── Price range bottom sheet ──────────────────────────────────────────────────

class _PriceRangeSheet extends StatefulWidget {
  final double? initialMin;
  final double? initialMax;
  final void Function(double? min, double? max) onApply;

  const _PriceRangeSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
  });

  @override
  State<_PriceRangeSheet> createState() => _PriceRangeSheetState();
}

class _PriceRangeSheetState extends State<_PriceRangeSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
        text: widget.initialMin?.toStringAsFixed(0) ?? '');
    _maxCtrl = TextEditingController(
        text: widget.initialMax?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.catPriceRange,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.catPriceMin,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('–', style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.catPriceMax,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null);
                    Navigator.pop(context);
                  },
                  child: Text(s.catReset),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final min = double.tryParse(_minCtrl.text.trim());
                    final max = double.tryParse(_maxCtrl.text.trim());
                    widget.onApply(min, max);
                    Navigator.pop(context);
                  },
                  child: Text(s.catApply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Year range bottom sheet ───────────────────────────────────────────────────

class _YearRangeSheet extends StatefulWidget {
  final int? initialMin;
  final int? initialMax;
  final void Function(int? min, int? max) onApply;

  const _YearRangeSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
  });

  @override
  State<_YearRangeSheet> createState() => _YearRangeSheetState();
}

class _YearRangeSheetState extends State<_YearRangeSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
        text: widget.initialMin?.toString() ?? '');
    _maxCtrl = TextEditingController(
        text: widget.initialMax?.toString() ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.catCarYearRange,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.catYearFrom,
                    hintText: '2015',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('–', style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.catYearTo,
                    hintText: '2024',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null);
                    Navigator.pop(context);
                  },
                  child: Text(s.catReset),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final min = int.tryParse(_minCtrl.text.trim());
                    final max = int.tryParse(_maxCtrl.text.trim());
                    widget.onApply(min, max);
                    Navigator.pop(context);
                  },
                  child: Text(s.catApply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
