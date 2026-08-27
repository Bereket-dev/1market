#!/usr/bin/env python3
"""Upload the release AAB to Google Play internal testing track.

Requires:
  pip install google-api-python-client google-auth
  PLAY_SERVICE_ACCOUNT_JSON=/path/to/service-account.json
  (service account must be invited in Play Console → Users and permissions)

Optional:
  PLAY_PACKAGE_NAME=com.jigjigamarket.koolan
  PLAY_AAB=build/app/outputs/bundle/release/app-release.aab
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    json_path = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON")
    if not json_path or not Path(json_path).is_file():
        print(
            "Set PLAY_SERVICE_ACCOUNT_JSON to a Play Developer API service-account JSON.\n"
            "Create one in Google Cloud, enable Android Publisher API, then invite the\n"
            "service account email in Play Console → Users and permissions (Release manager).",
            file=sys.stderr,
        )
        return 1

    package = os.environ.get("PLAY_PACKAGE_NAME", "com.jigjigamarket.koolan")
    aab = Path(os.environ.get("PLAY_AAB", ROOT / "build/app/outputs/bundle/release/app-release.aab"))
    if not aab.is_file():
        print(f"AAB not found: {aab}", file=sys.stderr)
        return 1

    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload
    except ImportError:
        print("Install deps: pip install google-api-python-client google-auth", file=sys.stderr)
        return 1

    creds = service_account.Credentials.from_service_account_file(
        json_path,
        scopes=["https://www.googleapis.com/auth/androidpublisher"],
    )
    service = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)

    edit = service.edits().insert(body={}, packageName=package).execute()
    edit_id = edit["id"]
    print(f"Created edit {edit_id}")

    media = MediaFileUpload(str(aab), mimetype="application/octet-stream", resumable=True)
    bundle = (
        service.edits()
        .bundles()
        .upload(editId=edit_id, packageName=package, media_body=media)
        .execute()
    )
    version_code = bundle["versionCode"]
    print(f"Uploaded AAB versionCode={version_code}")

    service.edits().tracks().update(
        editId=edit_id,
        packageName=package,
        track="internal",
        body={
            "track": "internal",
            "releases": [
                {
                    "name": f"1.0.0 ({version_code})",
                    "status": "completed",
                    "versionCodes": [str(version_code)],
                }
            ],
        },
    ).execute()

    service.edits().commit(editId=edit_id, packageName=package).execute()
    print("Committed release to internal testing track.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
