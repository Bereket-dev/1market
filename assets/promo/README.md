# Promo Assets & Admin Contract

The home-screen promo carousel is driven by the `home_promos` Supabase table.
An admin website (separate from this app) manages the content via the
**service_role** key, which bypasses Row Level Security.

The Flutter app only ever **reads** active rows (anon + authenticated SELECT).
When the table returns no rows the carousel falls back to the built-in
hardcoded slides so the home screen is never blank.

---

## `home_promos` table – field reference

| Field        | Type           | Required | Notes |
|--------------|----------------|----------|-------|
| `slot`       | `int` (1–4)    | ✓        | Fixed card position. Matches the 4 carousel slots. |
| `headline`   | `text`         | ✓        | Shown as large bold text. Admin may write in any language. |
| `subtitle`   | `text`         | –        | Shown in smaller text below the headline (max 2 lines rendered). |
| `image_url`  | `text` (URL)   | –        | Public HTTPS URL. `null` = icon-only card (the default look). |
| `theme`      | `enum`         | ✓        | Controls the gradient. Must be one of: `navy`, `teal`, `purple`, `red`. |
| `is_active`  | `boolean`      | ✓        | `false` hides the slot from the app; the hardcoded fallback for that slot is shown instead. |
| `updated_at` | `timestamptz`  | ✓        | Set automatically by the DB; update it manually on writes if needed. |

### Theme palette

| Value    | Accent (dark stop) | Accent Light (bright stop) | Default icon |
|----------|--------------------|----------------------------|--------------|
| `navy`   | `#00288E`          | `#1E40AF`                  | Storefront   |
| `teal`   | `#0F766E`          | `#14B8A6`                  | Verified user|
| `purple` | `#6D28D9`          | `#8B5CF6`                  | Add circle   |
| `red`    | `#B91C1C`          | `#EF4444`                  | Handyman     |

---

## Hosting promo images

Upload to **Cloudinary** (preferred — same CDN used for listing images) or to a
public Supabase Storage `promos` bucket. Store the resulting public URL in
`image_url`.

Recommended dimensions: **400 × 340 px** at 2×, JPEG or WebP, ≤ 120 KB.

When an `image_url` is set the carousel renders:
- A **faded full-bleed version** of the image on the right half of the card
  (ShaderMask blend, no hard edge).
- A **circular thumbnail** of the image on the far right, replacing the icon
  circle.
- If the image fails to load the icon circle is shown as a graceful fallback.

---

## Local placeholder files

This directory may also hold static fallback asset images (e.g. `promo1.png`)
that are bundled with the app. The `pubspec.yaml` already declares
`assets/promo/` so no further config is needed.

Currently the carousel uses network images only; no local assets are referenced.
