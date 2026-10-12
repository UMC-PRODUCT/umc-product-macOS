# Created by euijjang97 on 10/12/26.
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "UMCDesk/ci_scripts/ci_post_clone.sh"


class XcodeCloudPostCloneTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SCRIPT.is_file(), "Xcode Cloud needs a post-clone script")
        directory = tempfile.TemporaryDirectory(prefix="umc cloud ")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.project = self.root / "repository with spaces/UMCDesk"
        self.scripts = self.project / "ci_scripts"
        self.scripts.mkdir(parents=True)
        shutil.copy2(SCRIPT, self.scripts / SCRIPT.name)
        shutil.copy2(ROOT / "UMCDesk/Makefile", self.project / "Makefile")
        shutil.copy2(ROOT / "UMCDesk/mise.toml", self.project / "mise.toml")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.environment = os.environ | {
            "PATH": f"{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "CI_PRIMARY_REPOSITORY_PATH": str(self.project.parent),
            "CI_BUILD_NUMBER": "37",
            "TUIST_BUILD_NUMBER": "999",
            "HOMEBREW_NO_AUTO_UPDATE": "1",
        }
        self.mise = self.bin / "mise-fixture"
        self.write_executable(self.mise, """\
            #!/bin/sh
            set -eu
            case "$*" in
                trust) ;;
                install)
                    test -f mise.toml
                    touch tools-ready
                    ;;
                'exec -- tuist version') test -f tools-ready ;;
                'exec -- tuist install')
                    test -f tools-ready
                    test "${FAIL_STAGE:-}" != install
                    touch dependencies-ready
                    ;;
                'exec -- tuist generate --no-open')
                    test -f dependencies-ready
                    test "${FAIL_STAGE:-}" != generate
                    printf '%s' "$TUIST_BUILD_NUMBER" > generated-build-number
                    ;;
                *) exit 2 ;;
            esac
            """)
        shutil.copy2(self.mise, self.bin / "mise")
        self.write_executable(self.bin / "brew", """\
            #!/bin/sh
            set -eu
            test "$*" = 'install mise'
            cp "$MISE_FIXTURE" "$(dirname "$MISE_FIXTURE")/mise"
            """)
        self.environment["MISE_FIXTURE"] = str(self.mise)

    def write_executable(self, path, source):
        path.write_text(textwrap.dedent(source))
        path.chmod(0o755)

    def run_script(self):
        script = self.scripts / SCRIPT.name
        self.assertTrue(os.access(script, os.X_OK), "Cloud scripts must be executable")
        return subprocess.run([str(script)], cwd=self.scripts, env=self.environment,
                              capture_output=True, text=True, timeout=10)

    def test_generates_in_repository_with_cloud_build_number(self):
        completed = self.run_script()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual((self.project / "generated-build-number").read_text(), "37")

    def test_installs_mise_when_runner_does_not_have_it(self):
        (self.bin / "mise").unlink()
        completed = self.run_script()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual((self.project / "generated-build-number").read_text(), "37")

    def test_missing_cloud_environment_stops_before_preparation(self):
        for name in ["CI_PRIMARY_REPOSITORY_PATH", "CI_BUILD_NUMBER"]:
            with self.subTest(variable=name):
                value = self.environment.pop(name)
                try:
                    completed = self.run_script()
                    self.assertNotEqual(completed.returncode, 0)
                    self.assertIn(name, completed.stderr)
                    self.assertFalse((self.project / "tools-ready").exists())
                finally:
                    self.environment[name] = value

    def test_invalid_build_number_stops_before_preparation(self):
        for number in ["", "0", "000", "-1", "1.2", "abc", "1\n2", "1'bad"]:
            with self.subTest(number=number):
                self.environment["CI_BUILD_NUMBER"] = number
                completed = self.run_script()
                self.assertNotEqual(completed.returncode, 0)
                self.assertFalse((self.project / "tools-ready").exists())

    def test_dependency_or_generation_failure_stops_the_script(self):
        for stage in ["install", "generate"]:
            with self.subTest(stage=stage):
                self.environment["FAIL_STAGE"] = stage
                completed = self.run_script()
                self.assertNotEqual(completed.returncode, 0)
                self.assertFalse((self.project / "generated-build-number").exists())


if __name__ == "__main__":
    unittest.main()
