# Promo Assets

Place promotional images here if you want image-backed promo carousel slides.

Currently the promo carousel uses **gradient + icon** slides (no network or local
images) so this directory is a placeholder for future brand illustrations.

## If you add images

1. Add files here (e.g. `promo1.png`, `promo2.png`, …)
2. Update `lib/features/home/presentation/widgets/promo_carousel.dart` to
   reference them with `AssetImage('assets/promo/promo1.png')`.
3. The `pubspec.yaml` already declares `assets/promo/` so no further config needed.
