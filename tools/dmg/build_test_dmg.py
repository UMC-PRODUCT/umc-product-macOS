# Created by euijjang97 on 10/10/26.
import argparse
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

import dmgbuild


def build(app: Path, output_directory: Path) -> Path:
    app = app.resolve()
    with (app / "Contents/Info.plist").open("rb") as file:
        info = plistlib.load(file)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    version = info["CFBundleShortVersionString"]
    build_number = info["CFBundleVersion"]
    # Plist values become a filename; reject path separators and malformed version strings.
    for value in (version, build_number):
        if not isinstance(value, str) or not all(part.isdecimal() for part in value.split(".")):
            raise ValueError("App version and build number must contain digits and dots only")
    output_directory.mkdir(parents=True, exist_ok=True)
    output = output_directory / f"UMC-Desk-{version}-build{build_number}-test.dmg"

    def verify_copy(mount_point, options):
        # dmgbuild does not check ditto's exit code; validate the copy before publishing.
        subprocess.run(["codesign", "--verify", "--deep", "--strict",
                        str(Path(mount_point) / app.name)], check=True)

    with tempfile.TemporaryDirectory(prefix=".test-dmg-", dir=output_directory) as directory:
        temporary = Path(directory) / output.name
        dmgbuild.build_dmg(str(temporary), "UMC Desk",
                          settings_file=str(Path(__file__).with_name("settings.py")),
                          settings={"create_hook": verify_copy},
                          defines={"app": str(app), "background": str(
                              Path(__file__).with_name("background.png").resolve())})
        subprocess.run(["hdiutil", "verify", str(temporary)], check=True)
        temporary.replace(output)
    shutil.copyfile(Path(__file__).with_name("install.txt"), output_directory / "설치 안내.txt")
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Package an ad-hoc signed UMC Desk test app")
    parser.add_argument("app", type=Path)
    parser.add_argument("output_directory", type=Path)
    arguments = parser.parse_args()
    print(f"Test DMG: {build(arguments.app, arguments.output_directory)}")
