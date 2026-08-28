part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Viewing Request Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ViewingRequestSheet extends StatefulWidget {
  final Listing listing;
  final OnemarketAppState state;

  const _ViewingRequestSheet({
    required this.listing,
    required this.state,
  });

  @override
  State<_ViewingRequestSheet> createState() => _ViewingRequestSheetState();
}

class _ViewingRequestSheetState extends State<_ViewingRequestSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    final s = widget.state.s;
    final success = await widget.state.sendViewingRequest(
      listingId: widget.listing.id,
      date: _selectedDate,
      time: _selectedTime,
      messageTemplate: s.viewingMessageTemplate,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              success ? s.viewingRequestSent : s.viewingRequestFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = widget.state.s;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding:
          EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(s.viewingSheetTitle,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(s.viewingSheetSubtitle,
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.5)),
          const SizedBox(height: 24),

          // Date picker
          _PickerLabel(label: s.viewingSelectDate, cs: cs),
          const SizedBox(height: 8),
          _DateTimePickerRow(
            icon: Icons.calendar_today_outlined,
            value: _formatDate(_selectedDate),
            onTap: _pickDate,
            cs: cs,
          ),
          const SizedBox(height: 16),

          // Time picker
          _PickerLabel(label: s.viewingSelectTime, cs: cs),
          const SizedBox(height: 8),
          _DateTimePickerRow(
            icon: Icons.access_time_outlined,
            value: _formatTime(_selectedTime),
            onTap: _pickTime,
            cs: cs,
          ),
          const SizedBox(height: 28),

          // Send button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _sendRequest,
              icon: _sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(s.viewingConfirmButton,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers used only by the viewing sheet ─────────────────────────────

class _PickerLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _PickerLabel({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5),
      );
}

class _DateTimePickerRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _DateTimePickerRow(
      {required this.icon,
      required this.value,
      required this.onTap,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
