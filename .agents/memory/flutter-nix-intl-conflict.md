---
name: Flutter Nix intl version conflict
description: Flutter 3.32.0 (Dart 3.8.0) from Nix conflicts with intl 0.20.x; requires dependency_override to fix.
---

# Flutter 3.32.0 Nix + intl conflict

## The rule
Flutter 3.32.0 installed via Nix ships with a bundled `flutter_localizations` that calls `intl.DateSymbols()`, which was **removed in intl 0.20.0**. Any project that transitively resolves `intl >=0.20.0` will crash the Dart compiler with cascade errors (`DateSymbols not found`, `Matrix4 isn't a type`, `InvalidType`).

**Fix:** add to `pubspec.yaml`:
```yaml
dependency_overrides:
  intl: '>=0.19.0 <0.20.0'
```

**Why:** `supabase_flutter 2.15.4 → gotrue 2.25.0` declares `intl: ^0.20.0`, forcing the resolver to pick 0.20.x. The override pins it back to 0.19.x, which is API-compatible with gotrue's actual runtime usage even though the version constraint says otherwise.

**How to apply:** Any Flutter project on this Replit that uses supabase_flutter (or any package that pulls in intl >=0.20.0) needs this override as long as the Nix Flutter version is 3.32.0 / Dart 3.8.0.
