# Created by euijjang97 on 10/11/26.
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from build_dmg import build


def notarize(path: Path, profile: str, logs: Path):
    logs.mkdir(parents=True, exist_ok=True)
    submission = subprocess.run(
        ["xcrun", "notarytool", "submit", str(path), "--keychain-profile", profile,
         "--output-format", "json"], check=True, capture_output=True, text=True)
    identifier = json.loads(submission.stdout)["id"]
    # Retain every submission ID so interrupted runs and earlier builds can be inspected.
    (logs / f"{path.name}.{identifier}.submission.json").write_text(submission.stdout)
    print(f"Notarization submitted: {identifier}", flush=True)
    result = subprocess.run(
        ["xcrun", "notarytool", "wait", identifier, "--keychain-profile", profile,
         "--output-format", "json"], check=True, capture_output=True, text=True)
    (logs / f"{path.name}.{identifier}.result.json").write_text(result.stdout)
    if json.loads(result.stdout)["status"] != "Accepted":
        raise RuntimeError(f"Notarization rejected; inspect submission {identifier}")


def staple(path: Path):
    subprocess.run(["xcrun", "stapler", "staple", str(path)], check=True)
    subprocess.run(["xcrun", "stapler", "validate", str(path)], check=True)


def release(app: Path, output_directory: Path, identity: str, profile: str,
            *, already_notarized: bool = False) -> Path:
    app = app.resolve()
    output_directory = output_directory.resolve()
    output_directory.mkdir(parents=True, exist_ok=True)
    logs = output_directory / ".notarization"
    with tempfile.TemporaryDirectory(prefix=".release-", dir=output_directory) as directory:
        temporary = Path(directory)
        archive = temporary / "UMC-Desk-notarization.zip"
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
        if already_notarized:
            subprocess.run(["xcrun", "stapler", "validate", str(app)], check=True)
        else:
            subprocess.run(["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(app),
                            str(archive)], check=True)
            notarize(archive, profile, logs)
            staple(app)
        subprocess.run(["spctl", "--assess", "--type", "execute", str(app)], check=True)
        dmg = build(app, temporary, release=True)
        output = output_directory / dmg.name
        if output.exists():
            raise FileExistsError(f"Use a new build number; {output} already exists")
        subprocess.run(["codesign", "--force", "--sign", identity, "--timestamp", str(dmg)],
                       check=True)
        notarize(dmg, profile, logs)
        staple(dmg)
        subprocess.run(["codesign", "--verify", "--strict", str(dmg)], check=True)
        subprocess.run(["spctl", "--assess", "--type", "open", "--context",
                        "context:primary-signature", str(dmg)], check=True)
        dmg.replace(output)
        shutil.copyfile(temporary / "설치 안내.txt", output_directory / "설치 안내.txt")
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Notarize a Developer ID-signed UMC Desk DMG")
    parser.add_argument("app", type=Path)
    parser.add_argument("output_directory", type=Path)
    parser.add_argument("--identity", required=True)
    parser.add_argument("--profile", required=True)
    arguments = parser.parse_args()
    print(f"Notarized DMG: {release(arguments.app, arguments.output_directory,
                                    arguments.identity, arguments.profile)}")
