import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../shared/services/app_state.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Location helps us show nearby listings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We use your location to show you nearby listings and services. You can continue even if you deny permission.',
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isRequesting
                    ? null
                    : () async {
                        setState(() => _isRequesting = true);
                        await _requestLocationPermission();
                        if (!mounted) return;
                        setState(() => _isRequesting = false);
                        await state.completeLocationOnboarding();
                      },
                child: Text(_isRequesting ? 'Requesting...' : 'Continue'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isRequesting
                      ? null
                      : () async {
                          await state.completeLocationOnboarding();
                        },
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted || status.isLimited) {
      return;
    }
  }
}
