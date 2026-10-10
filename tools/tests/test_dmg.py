# Created by euijjang97 on 10/10/26.
import importlib.util
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools/dmg/build_test_dmg.py"
HAS_TOOLS = sys.platform == "darwin" and importlib.util.find_spec("dmgbuild") is not None


@unittest.skipUnless(HAS_TOOLS, "Run make test-dmg on macOS to install packaging tools")
class TestDMGTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SCRIPT.is_file(), "DMG packaging script must exist")
        specification = importlib.util.spec_from_file_location("build_test_dmg", SCRIPT)
        self.builder = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(self.builder)
        self.directory = tempfile.TemporaryDirectory(prefix="umc dmg ")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.app = self.root / "UMC Desk.app"
        executable = self.app / "Contents/MacOS/TestApp"
        executable.parent.mkdir(parents=True)
        shutil.copy("/usr/bin/true", executable)
        subprocess.run(["codesign", "--remove-signature", str(executable)], check=True)
        resources = self.app / "Contents/Resources"
        resources.mkdir()
        shutil.copy("/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/"
                    "GenericApplicationIcon.icns", resources / "AppIcon.icns")
        with (self.app / "Contents/Info.plist").open("wb") as file:
            plistlib.dump({"CFBundleExecutable": "TestApp", "CFBundlePackageType": "APPL",
                          "CFBundleIdentifier": "com.umc.test-dmg-fixture",
                          "CFBundleShortVersionString": "0.0.1", "CFBundleVersion": "7",
                          "CFBundleIconFile": "AppIcon.icns"}, file)
        self.output = self.root / "output folder"

    def test_dmg_has_installable_app_and_saved_finder_layout(self):
        from ds_store import DSStore

        subprocess.run(["codesign", "--force", "--sign", "-", str(self.app)], check=True,
                       capture_output=True)
        dmg = self.builder.build(self.app, self.output)
        self.assertEqual(dmg.name, "UMC-Desk-0.0.1-build7-test.dmg")
        mount = self.root / "mounted"
        mount.mkdir()
        subprocess.run(["hdiutil", "attach", "-readonly", "-nobrowse", "-mountpoint",
                        str(mount), str(dmg)], check=True, capture_output=True)
        try:
            self.assertEqual((mount / "Applications").readlink(), Path("/Applications"))
            visible = {path.name for path in mount.iterdir() if not path.name.startswith(".")}
            self.assertEqual(visible, {"UMC Desk.app", "Applications"})
            with DSStore.open(str(mount / ".DS_Store"), "r") as store:
                self.assertEqual(store["UMC Desk.app"]["Iloc"], (180, 180))
                self.assertEqual(store["Applications"]["Iloc"], (480, 180))
                self.assertEqual(store["."]["icvp"]["iconSize"], 128)
                self.assertIn("backgroundImageAlias", store["."]["icvp"])
            installed = self.root / "Applications/UMC Desk.app"
            installed.parent.mkdir()
            subprocess.run(["ditto", str(mount / self.app.name), str(installed)], check=True)
        finally:
            subprocess.run(["hdiutil", "detach", str(mount)], check=True, capture_output=True)
        signature = subprocess.run(["codesign", "--verify", "--deep", "--strict", str(installed)],
                                   capture_output=True, text=True)
        self.assertEqual(signature.returncode, 0, signature.stderr)
        self.assertEqual(subprocess.run([str(installed / "Contents/MacOS/TestApp")]).returncode,
                         0)

    def test_unsigned_app_leaves_previous_artifact_untouched(self):
        self.output.mkdir()
        previous = self.output / "previous.dmg"
        previous.write_bytes(b"previous build")
        with self.assertRaises(subprocess.CalledProcessError):
            self.builder.build(self.app, self.output)
        self.assertEqual(previous.read_bytes(), b"previous build")
        self.assertEqual(list(self.output.iterdir()), [previous])

    def test_failed_app_copy_leaves_previous_artifact_untouched(self):
        import dmgbuild.core

        subprocess.run(["codesign", "--force", "--sign", "-", str(self.app)], check=True,
                       capture_output=True)
        self.output.mkdir()
        previous = self.output / "UMC-Desk-0.0.1-build7-test.dmg"
        previous.write_bytes(b"previous build")
        original_call = subprocess.call

        def failed_copy(command, *arguments, **keywords):
            result = original_call(command, *arguments, **keywords)
            if command[:2] == ["/usr/bin/ditto", str(self.app.resolve())]:
                (Path(command[2]) / "Contents/MacOS/TestApp").unlink()
                return 1
            return result

        with patch.object(dmgbuild.core.subprocess, "call", side_effect=failed_copy):
            with self.assertRaises(subprocess.CalledProcessError):
                self.builder.build(self.app, self.output)
        self.assertEqual(previous.read_bytes(), b"previous build")
        self.assertEqual(list(self.output.iterdir()), [previous])


if __name__ == "__main__":
    unittest.main()
