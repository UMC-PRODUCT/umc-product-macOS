# Created by euijjang97 on 10/13/26.
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import posixpath
import stat
import subprocess
import zipfile

def validate_archive(path: Path):
    with zipfile.ZipFile(path) as archive:
        if sum(item.file_size for item in archive.infolist()) > 1024 ** 3:
            raise ValueError("Cloud archive is too large")
        for item in archive.infolist():
            name = item.filename
            if name.startswith("/") or ".." in Path(name).parts:
                raise ValueError("Unsafe Cloud archive path")
            if stat.S_ISLNK(item.external_attr >> 16):
                target = archive.read(item).decode("utf-8")
                resolved = posixpath.normpath(posixpath.join(posixpath.dirname(name), target))
                if target.startswith("/") or resolved == ".." or resolved.startswith("../"):
                    raise ValueError("Cloud archive symlink escapes extraction directory")


def package(directory: Path, output: Path, identity: str, profile: str):
    from build_release_dmg import release

    cloud = json.loads((directory / "cloud.json").read_text())
    validate_archive(directory / "app.zip")
    extracted = directory / "extracted"
    subprocess.run(["ditto", "-x", "-k", str(directory / "app.zip"), str(extracted)], check=True)
    apps = list(extracted.glob("*.app"))
    if len(apps) != 1:
        raise ValueError("Expected exactly one Cloud app")
    app = apps[0]
    with (app / "Contents/Info.plist").open("rb") as file:
        info = plistlib.load(file)
    if (info["CFBundleIdentifier"] != "com.umc.product.macos"
            or info["CFBundleShortVersionString"] != cloud["version"]
            or info["CFBundleVersion"] != cloud["build"]):
        raise ValueError("Cloud app does not match requested release")
    executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
    architectures = subprocess.check_output(["lipo", "-archs", str(executable)], text=True).split()
    if set(architectures) != {"arm64", "x86_64"}:
        raise ValueError("Expected a universal app")
    for architecture in architectures:
        signature = subprocess.run(["codesign", "-d", "--verbose=4", "--arch", architecture,
                                    str(app)], check=True, capture_output=True, text=True).stderr
        if not all(value in signature for value in ["Authority=Developer ID Application:",
                   "TeamIdentifier=8B8B4462NV", "(runtime)", "Timestamp="]):
            raise ValueError("Cloud app is missing Developer ID, runtime or timestamp")
    dmg = release(app, output, identity, profile, already_notarized=True)
    tag = f'v{cloud["version"]}-build.{cloud["build"]}'
    base = f"https://github.com/UMC-PRODUCT/umc-product-macOS/releases"
    with dmg.open("rb") as file:
        checksum = hashlib.file_digest(file, "sha256").hexdigest()
    manifest = {"status": "available", "version": cloud["version"],
                "minimumMacOS": info["LSMinimumSystemVersion"],
                "dmgUrl": f"{base}/download/{tag}/{dmg.name}",
                "architecture": "Universal (Apple Silicon + Intel)",
                "sizeBytes": dmg.stat().st_size, "notesUrl": f"{base}/tag/{tag}",
                "sha256": checksum,
                "sourceSHA": cloud["sourceSHA"], "cloudRun": cloud["cloudRun"]}
    (output / "release.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (output / "release-notes.txt").write_text(
        f'UMC Desk {cloud["version"]} (build {cloud["build"]})\n\n'
        "Xcode Cloud app and DMG are Developer ID signed, notarized and stapled.\n\n"
        + "```json\n" + json.dumps(manifest, indent=2) + "\n```\n")
    print(f"Ready to publish: {dmg}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--identity", required=True)
    parser.add_argument("--profile", required=True)
    arguments = parser.parse_args()
    package(arguments.directory, arguments.output, arguments.identity, arguments.profile)
