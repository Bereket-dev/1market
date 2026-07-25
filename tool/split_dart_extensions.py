#!/usr/bin/env python3
"""Split SupabaseRepository and SyncService into extension part files."""

from __future__ import annotations

from pathlib import Path


def dedent_class_body(text: str) -> str:
    lines = text.splitlines()
    out = []
    for line in lines:
        if line.startswith("  "):
            out.append(line[2:])
        else:
            out.append(line)
    return "\n".join(out).strip()


def split_repository(lib_root: Path) -> None:
    main_path = lib_root / "shared/services/supabase_repository.dart"
    parts_dir = lib_path = lib_root / "shared/services/parts"
    parts_dir.mkdir(exist_ok=True)

    lines = main_path.read_text().splitlines(keepends=True)

    header = lines[:18]  # imports + class header through currentUserId

    sections: list[tuple[str, int, int, str]] = [
        ("supabase_repository_profile.dart", 20, 81, "SupabaseRepositoryProfile"),
        ("supabase_repository_listings.dart", 85, 230, "SupabaseRepositoryListings"),
        ("supabase_repository_chat.dart", 231, 382, "SupabaseRepositoryChat"),
        ("supabase_repository_reviews.dart", 383, 458, "SupabaseRepositoryReviews"),
        ("supabase_repository_services.dart", 459, 483, "SupabaseRepositoryServices"),
        ("supabase_repository_hiring_write.dart", 484, 540, "SupabaseRepositoryHiringWrite"),
        ("supabase_repository_hiring_read.dart", 541, 647, "SupabaseRepositoryHiringRead"),
        ("supabase_repository_notifications.dart", 648, 737, "SupabaseRepositoryNotifications"),
    ]

    part_names = []
    for name, start, end, ext_class in sections:
        body = dedent_class_body("".join(lines[start - 1 : end]))
        part_file = parts_dir / name
        part_file.write_text(
            f"part of '../supabase_repository.dart';\n\n"
            f"extension {ext_class} on SupabaseRepository {{\n"
            f"{body}\n"
            f"}}\n"
        )
        part_names.append(f"parts/{name}")
        print(f"  repo part {name}: {end - start + 1} lines")

    new_main: list[str] = []
    new_main.extend(header)
    if new_main and not new_main[-1].endswith("\n"):
        new_main[-1] += "\n"
    new_main.append("\n")
    for p in part_names:
        new_main.append(f"part '{p}';\n")
    new_main.append("\n")
    new_main.append("  static const int kPageSize = 30;\n")
    new_main.append("}\n")

    main_path.write_text("".join(new_main))
    print(f"OK supabase_repository.dart: {len(new_main)} lines")


def split_sync_service(lib_root: Path) -> None:
    main_path = lib_root / "shared/services/offline/sync_service.dart"
    parts_dir = lib_root / "shared/services/offline/parts"
    parts_dir.mkdir(exist_ok=True)

    lines = main_path.read_text().splitlines(keepends=True)

    # Main: through requestSync (line 210), then close class.
    header = lines[:210]

    sections: list[tuple[str, int, int, str]] = [
        ("sync_service_enqueue.dart", 212, 357, "SyncServiceEnqueue"),
        ("sync_service_sync.dart", 358, 815, "SyncServiceSync"),
    ]

    part_names = []
    for name, start, end, ext_class in sections:
        body = dedent_class_body("".join(lines[start - 1 : end]))
        part_file = parts_dir / name
        part_file.write_text(
            f"part of '../sync_service.dart';\n\n"
            f"extension {ext_class} on SyncService {{\n"
            f"{body}\n"
            f"}}\n"
        )
        part_names.append(f"parts/{name}")
        print(f"  sync part {name}: {end - start + 1} lines")

    new_main = header[:]
    # Insert part directives after imports
    last_import = max(
        (i for i, line in enumerate(header) if line.startswith(("import ", "export "))),
        default=-1,
    )
    rebuilt = header[: last_import + 1]
    if rebuilt and not rebuilt[-1].endswith("\n"):
        rebuilt[-1] += "\n"
    rebuilt.append("\n")
    for p in part_names:
        rebuilt.append(f"part '{p}';\n")
    rebuilt.append("\n")
    rebuilt.extend(header[last_import + 1 :])
    rebuilt.append("}\n")

    main_path.write_text("".join(rebuilt))
    print(f"OK sync_service.dart: {len(rebuilt)} lines")


if __name__ == "__main__":
    lib = Path(__file__).resolve().parents[1] / "lib"
    print("=== supabase_repository ===")
    split_repository(lib)
    print("=== sync_service ===")
    split_sync_service(lib)
