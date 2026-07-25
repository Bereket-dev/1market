#!/usr/bin/env python3
"""Split a Dart library into part files without changing logic."""

from __future__ import annotations

from pathlib import Path

# (main_file_relative_to_lib, [(part_filename, start_line, end_line), ...])
SPLITS: list[tuple[str, list[tuple[str, int, int]]]] = [
    # ── Hiring ────────────────────────────────────────────────────────────────
    (
        "features/hiring/presentation/screens/hiring_applicant_detail_screen.dart",
        [
            ("hiring_applicant_detail_widgets.dart", 331, 762),
            ("hiring_applicant_detail_helpers.dart", 763, 968),
        ],
    ),
    (
        "features/hiring/presentation/screens/hiring_detail_screen.dart",
        [
            ("hiring_detail_hero.dart", 392, 647),
            ("hiring_detail_picker.dart", 648, 732),
        ],
    ),
    (
        "features/hiring/presentation/screens/hiring_edit_screen.dart",
        [("hiring_edit_widgets.dart", 420, 580)],
    ),
    (
        "features/hiring/presentation/screens/hiring_browse_screen.dart",
        [("hiring_browse_widgets.dart", 225, 424)],
    ),
    # ── Services ──────────────────────────────────────────────────────────────
    (
        "features/services/presentation/screens/service_detail_screen.dart",
        [
            ("service_detail_hero.dart", 274, 562),
            ("service_detail_reviews.dart", 563, 951),
        ],
    ),
    (
        "features/services/presentation/screens/service_edit_screen.dart",
        [("service_edit_widgets.dart", 494, 859)],
    ),
    (
        "features/services/presentation/screens/service_management_screen.dart",
        [
            ("service_management_empty.dart", 68, 197),
            ("service_management_list.dart", 198, 517),
            ("service_management_actions.dart", 518, 598),
        ],
    ),
    (
        "features/services/presentation/screens/service_browse_screen.dart",
        [("service_browse_widgets.dart", 260, 475)],
    ),
    (
        "features/services/presentation/screens/service_reviews_screen.dart",
        [("service_reviews_widgets.dart", 256, 396)],
    ),
    # ── Favorites / listings / profile ────────────────────────────────────────
    (
        "features/favorites/presentation/screens/saved_screen.dart",
        [
            ("saved_header.dart", 110, 317),
            ("saved_tiles.dart", 318, 606),
            ("saved_compare.dart", 607, 850),
        ],
    ),
    (
        "features/listings/presentation/screens/edit_listing_screen.dart",
        [("edit_listing_widgets.dart", 375, 535)],
    ),
    (
        "features/listings/presentation/screens/my_listings_screen.dart",
        [
            ("my_listings_empty.dart", 70, 136),
            ("my_listings_tiles.dart", 137, 400),
        ],
    ),
    (
        "features/profile/presentation/screens/settings_screen.dart",
        [
            ("settings_name_card.dart", 178, 419),
            ("settings_rows.dart", 420, 779),
        ],
    ),
    (
        "features/profile/presentation/screens/public_profile_screen.dart",
        [
            ("public_profile_header.dart", 180, 368),
            ("public_profile_tabs.dart", 369, 662),
        ],
    ),
    # ── Onboarding / chat ─────────────────────────────────────────────────────
    (
        "features/onboarding/screens/auth_screen.dart",
        [("auth_social_buttons.dart", 504, 585)],
    ),
    (
        "features/chat/presentation/screens/messages_screen.dart",
        [("messages_widgets.dart", 215, 388)],
    ),
    # ── Shared widgets ──────────────────────────────────────────────────────────
    (
        "shared/widgets/similar_section.dart",
        [
            ("similar_services_section.dart", 75, 136),
            ("similar_hiring_section.dart", 137, 193),
            ("similar_shared_widgets.dart", 194, 518),
        ],
    ),
    (
        "shared/widgets/auth_gate_sheet.dart",
        [
            ("auth_gate_content.dart", 55, 388),
            ("auth_gate_logos.dart", 389, 490),
        ],
    ),
    (
        "features/cars/presentation/widgets/car_card.dart",
        [
            ("car_card_compact.dart", 140, 262),
            ("car_card_shared.dart", 320, 518),
        ],
    ),
]


def split_file(lib_root: Path, rel_path: str, parts: list[tuple[str, int, int]]) -> None:
    main_path = lib_root / rel_path
    if not main_path.exists():
        print(f"SKIP missing: {rel_path}")
        return

    lines = main_path.read_text().splitlines(keepends=True)
    widgets_dir = main_path.parent / "widgets"
    widgets_dir.mkdir(exist_ok=True)

    first_start = parts[0][1]
    header = lines[: first_start - 1]

    part_paths: list[str] = []
    for name, start, end in parts:
        part_file = widgets_dir / name
        body = "".join(lines[start - 1 : end])
        part_file.write_text(f"part of '../{main_path.name}';\n\n{body}")
        part_paths.append(part_file.relative_to(main_path.parent).as_posix())

    last_import = max(
        (i for i, line in enumerate(header) if line.startswith(("import ", "export "))),
        default=-1,
    )

    new_lines: list[str] = []
    new_lines.extend(header[: last_import + 1])
    if new_lines and not new_lines[-1].endswith("\n"):
        new_lines[-1] += "\n"
    new_lines.append("\n")
    for p in part_paths:
        new_lines.append(f"part '{p}';\n")
    new_lines.append("\n")
    new_lines.extend(header[last_import + 1 :])

    main_path.write_text("".join(new_lines))
    print(
        f"OK {rel_path}: main {len(new_lines)} lines, "
        f"{len(parts)} parts ({sum(e - s + 1 for _, s, e in parts)} extracted)"
    )


def main() -> None:
    lib_root = Path(__file__).resolve().parents[1] / "lib"
    for rel_path, parts in SPLITS:
        split_file(lib_root, rel_path, parts)


if __name__ == "__main__":
    main()
