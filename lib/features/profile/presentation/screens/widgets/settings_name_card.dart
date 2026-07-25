part of '../settings_screen.dart';

// ── Inline name edit card ─────────────────────────────────────────────────────
//
// Displays the user's avatar, display name, and city. The display name field
// switches between a read-only label and an inline TextField on tap.
// Only the display name is editable here — all other fields are edited on
// EditProfileScreen (reachable via the "Edit Profile" row below).
//
// Uses getInheritedWidgetOfExactType (non-registering) so this widget's
// element is NOT added to KoolanAppStateScope._dependents. We only need
// the profile data once for the initial controller text — we don't need
// automatic rebuild notifications from the scope. Any mutation-driven
// state changes are covered by setState.

class _InlineNameCard extends StatefulWidget {
  final String displayName;
  final String? city;
  final String? avatarUrl;

  const _InlineNameCard({
    required this.displayName,
    this.city,
    this.avatarUrl,
  });

  @override
  State<_InlineNameCard> createState() => _InlineNameCardState();
}

class _InlineNameCardState extends State<_InlineNameCard> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.displayName);
  }

  @override
  void didUpdateWidget(_InlineNameCard old) {
    super.didUpdateWidget(old);
    // Sync the controller text when the parent rebuilds with a new name
    // (e.g. after a successful save propagates back through the tree),
    // but only when we're NOT currently editing — we don't want to clobber
    // what the user is typing.
    if (!_editing && old.displayName != widget.displayName) {
      _controller.text = widget.displayName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;

    // Non-registering read — safe inside a State method (not build()).
    // We only need the appState reference here; no reactive subscription needed.
    final scope = context.getInheritedWidgetOfExactType<KoolanAppStateScope>();
    final appState = scope?.notifier;
    if (appState == null) return;

    setState(() => _saving = true);
    try {
      await appState.submitProfileUpdate(
        displayName: name,
        bio: appState.profile?.bio ?? '',
        phone: appState.profile?.phone ?? '',
        city: appState.profile?.city ?? '',
        preferredCategory: appState.profile?.preferredCategory,
      );
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _startEditing() {
    // Reset controller to the current display name when entering edit mode.
    _controller.text = widget.displayName;
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _controller.text = widget.displayName;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Read strings via non-registering lookup (consistent with _save above).
    final scope = context.getInheritedWidgetOfExactType<KoolanAppStateScope>();
    final s = scope?.notifier?.s;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              backgroundImage: widget.avatarUrl != null &&
                      widget.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(
                      widget.displayName.isNotEmpty
                          ? widget.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Name + city column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_editing) ...[
                    // Inline text field for editing the name
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: cs.onSurface),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onSubmitted: (_) => _save(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Confirm button
                        _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _controller,
                                builder: (_, value, _) => IconButton(
                                  icon: Icon(Icons.check_circle_rounded,
                                      color: value.text.trim().isEmpty
                                          ? cs.onSurfaceVariant
                                              .withValues(alpha: 0.4)
                                          : cs.primary,
                                      size: 22),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  onPressed: value.text.trim().isEmpty
                                      ? null
                                      : _save,
                                  tooltip: s?.editProfileNameSave,
                                ),
                              ),
                        // Cancel button
                        if (!_saving)
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: cs.onSurfaceVariant, size: 20),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            onPressed: _cancelEditing,
                            tooltip: s?.commonCancel,
                          ),
                      ],
                    ),
                  ] else ...[
                    // Read-only display — tap the row or the pencil icon to edit
                    GestureDetector(
                      onTap: _startEditing,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.displayName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: cs.onSurface),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined,
                              color: cs.primary, size: 16),
                        ],
                      ),
                    ),
                  ],
                  if (widget.city != null && widget.city!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(widget.city!,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

