#!/usr/bin/env python3
"""Bump VERSION_PATCH in version.mk and sync AndroidManifest.xml on commit."""

import glob
import os
import re
import subprocess
import sys


def update_manifest_version(manifest_path, version_name, version_code):
    """Update version in a single AndroidManifest.xml file."""
    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest_data = f.read()

        version_name_match = re.search(r'android:versionName="(.*?)"', manifest_data)
        version_code_match = re.search(r'android:versionCode="(\d+)"', manifest_data)

        if not version_name_match or not version_code_match:
            print(f"Warning: Could not find version info in {manifest_path}")
            return False

        current_version_name = version_name_match.group(1)
        current_version_code = version_code_match.group(1)

        if current_version_name != version_name or current_version_code != version_code:
            print(
                f"Updating {manifest_path} from "
                f"{current_version_name} ({current_version_code}) to "
                f"{version_name} ({version_code})"
            )
            manifest_data = re.sub(
                r'android:versionName="(.*?)"',
                f'android:versionName="{version_name}"',
                manifest_data,
            )
            manifest_data = re.sub(
                r'android:versionCode="(\d+)"',
                f'android:versionCode="{version_code}"',
                manifest_data,
            )

            with open(manifest_path, "w", encoding="utf-8") as f:
                f.write(manifest_data)

            subprocess.run(["git", "add", manifest_path], check=True)
            return True

        print(f"No update needed for {manifest_path}. Versions match.")
        return False
    except Exception as e:
        print(f"Error updating {manifest_path}: {e}")
        return False


def main(staged_files=None):
    version_file = "version.mk"
    if not os.path.exists(version_file):
        print("version.mk not found, skipping version update.")
        return 0

    with open(version_file, "r", encoding="utf-8") as f:
        version_data = f.read()

    version_major = re.search(r"VERSION_MAJOR=(\d+)", version_data)
    version_minor = re.search(r"VERSION_MINOR=(\d+)", version_data)
    version_patch = re.search(r"VERSION_PATCH=(\d+)", version_data)
    if not version_major or not version_minor or not version_patch:
        print("Invalid version.mk; expected VERSION_MAJOR/MINOR/PATCH")
        return 1

    try:
        mj = int(version_major.group(1))
        mn = int(version_minor.group(1))
        pt = int(version_patch.group(1))
    except ValueError:
        print("Invalid version numbers in version.mk; expecting integers")
        return 1

    pt += 1

    new_version_data = re.sub(
        r"^VERSION_PATCH=\d+$",
        f"VERSION_PATCH={pt}",
        version_data,
        flags=re.MULTILINE,
    )
    if new_version_data != version_data:
        with open(version_file, "w", encoding="utf-8") as f:
            f.write(new_version_data)
        try:
            subprocess.run(["git", "add", version_file], check=True)
        except Exception as e:
            print(f"Warning: git add {version_file} failed: {e}")
        print(f"Bumped version to {mj}.{mn}.{pt}")

    # Android versionName: MAJOR.MINOR-PATCH (dapchainvpn-client style)
    version_name = f"{mj}.{mn}-{pt}"
    # versionCode: M mm ppp
    version_code = f"{mj}{mn:02d}{pt:03d}"

    manifest_pattern = "cpp/android/AndroidManifest.xml"
    manifest_files = glob.glob(manifest_pattern)

    if not manifest_files:
        print(f"No AndroidManifest.xml found at {manifest_pattern}")
        return 0

    updated_count = 0
    for manifest_file in manifest_files:
        if update_manifest_version(manifest_file, version_name, version_code):
            updated_count += 1

    print(f"Updated {updated_count} out of {len(manifest_files)} manifest files.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
