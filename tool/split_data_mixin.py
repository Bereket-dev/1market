#!/usr/bin/env python3
"""Split DataStateMixin into composable sub-mixins."""

from __future__ import annotations

from pathlib import Path

IMPORTS = '''import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/application.dart';
import '../models/chat.dart';
import '../models/hiring_post.dart';
import '../models/listing.dart';
import '../models/profile.dart';
import '../models/service.dart';
import '../models/service_review.dart';
import '../models/syncable_entity.dart';
import 'cloudinary_upload_service.dart';
import 'local_storage.dart' as app_local;
import 'offline/sync_service.dart';
import 'recommendation_engine.dart';
import 'supabase_repository.dart';
'''

SECTIONS: list[tuple[str, str, int, int]] = [
    ("app_state_data_fields_mixin.dart", "DataStateFieldsMixin", 21, 60, "ChangeNotifier"),
    ("app_state_data_loading_mixin.dart", "DataStateLoadingMixin", 61, 206, "DataStateFieldsMixin"),
    ("app_state_data_filters_mixin.dart", "DataStateFiltersMixin", 207, 237, "DataStateFieldsMixin"),
    ("app_state_data_listings_mixin.dart", "DataStateListingsMixin", 238, 366, "DataStateFieldsMixin"),
    ("app_state_data_services_mixin.dart", "DataStateServicesMixin", 368, 547, "DataStateFieldsMixin"),
    ("app_state_data_hiring_mixin.dart", "DataStateHiringMixin", 549, 686, "DataStateFieldsMixin"),
    ("app_state_data_reviews_mixin.dart", "DataStateReviewsMixin", 687, 798, "DataStateFieldsMixin"),
]


def main() -> None:
    lib = Path(__file__).resolve().parents[1] / "lib"
    src = lib / "shared/services/app_state_data_mixin.dart"
    lines = src.read_text().splitlines(keepends=True)

    services_dir = lib / "shared/services"
    mixin_names = []

    for filename, mixin_name, start, end, on_type in SECTIONS:
        body = "".join(lines[start - 1 : end]).strip()
        # Remove outer mixin wrapper lines from original if present
        content = f"{IMPORTS}\n/// Sub-mixin extracted from [DataStateMixin].\n"
        content += f"mixin {mixin_name} on {on_type} {{\n"
        content += body + "\n}\n"
        (services_dir / filename).write_text(content)
        mixin_names.append(mixin_name)
        print(f"  {filename}: {end - start + 1} lines")

    barrel = f"{IMPORTS}\n"
    for filename, mixin_name, _, _, _ in SECTIONS:
        barrel += f"import '{filename.replace('.dart', '')}.dart';\n"
    barrel += "\n/// Composed data-state mixin — import this from [KoolanAppState].\n"
    barrel += "mixin DataStateMixin on ChangeNotifier\n"
    barrel += "    with\n"
    for i, name in enumerate(mixin_names):
        suffix = "," if i < len(mixin_names) - 1 else " {}\n"
        barrel += f"        {name}{suffix}"
    (services_dir / "app_state_data_mixin.dart").write_text(barrel)
    print(f"OK app_state_data_mixin.dart barrel: {len(barrel.splitlines())} lines")


if __name__ == "__main__":
    main()
