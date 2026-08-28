import 'package:flutter/material.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../shared/services/app_state.dart';
import '../../../shared/widgets/brand_logo.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selected;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const BrandLogo(iconOnly: true, width: 56, height: 56),
              const SizedBox(height: 20),
              Text(
                s.languageTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.appSlogan,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.languageSubtitle,
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              _LanguageOption(
                label: s.languageEnglish,
                sublabel: 'English',
                value: 'en',
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: s.languageAmharic,
                sublabel: 'አማርኛ',
                value: 'am',
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: s.languageSomali,
                sublabel: 'Soomaali',
                value: 'so',
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: cs.error)),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected == null || _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          try {
                            await state.completeLanguageOnboarding(_selected!);
                          } catch (e) {
                            if (mounted) {
                              setState(
                                () => _error = ErrorMapper.userMessage(e, s),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  child: Text(
                      _isLoading ? s.authPleaseWait : s.languageContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _LanguageOption({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = groupValue == value;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant.withOpacity(0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: selected ? cs.onPrimaryContainer : cs.onSurface)),
                Text(sublabel,
                    style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? cs.onPrimaryContainer.withOpacity(0.7)
                            : cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
