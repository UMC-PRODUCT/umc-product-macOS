# Created by euijjang97 on 10/8/26.
import json
import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest


WORKFLOW = Path(__file__).resolve().parents[2] / ".github/workflows/discord-ci.yml"
SCRIPT = textwrap.dedent(WORKFLOW.read_text().split("        run: |\n", 1)[1])
REPOSITORY = "UMC-PRODUCT/umc-product-macOS"
RUN_URL = f"https://github.com/{REPOSITORY}/actions/runs/123"


class DiscordCINotificationTests(unittest.TestCase):
    def run_workflow(self, result="success", pull_requests=None, webhook="https://example.test",
                     curl_exit="0", author="JEONG-J", branch="chore/53"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            event = {"workflow_run": {
                "conclusion": result, "head_branch": branch, "html_url": RUN_URL,
                "head_sha": "7adc9e3abcdef", "actor": {"login": author},
                "pull_requests": pull_requests or [],
            }}
            (root / "event.json").write_text(json.dumps(event))
            curl = root / "curl"
            curl.write_text('#!/bin/sh\ncp payload.json sent.json\n'
                            'printf "%s\\n" "$@" > curl-args.txt\n'
                            'exit "$CURL_EXIT_CODE"\n')
            curl.chmod(0o755)
            environment = os.environ | {
                "PATH": f"{root}:{os.environ['PATH']}",
                "GITHUB_EVENT_PATH": str(root / "event.json"),
                "GITHUB_REPOSITORY": REPOSITORY, "GITHUB_SERVER_URL": "https://github.com",
                "DISCORD_WEBHOOK_URL": webhook, "CURL_EXIT_CODE": curl_exit,
            }
            completed = subprocess.run(["bash", "-e", "-o", "pipefail", "-c", SCRIPT],
                                       cwd=root, env=environment, capture_output=True, text=True)
            payload = json.loads((root / "sent.json").read_text()) \
                if (root / "sent.json").exists() else None
            arguments = (root / "curl-args.txt").read_text().splitlines() \
                if (root / "curl-args.txt").exists() else []
            return completed, payload, arguments

    def test_ci_result_is_one_compact_embed_with_pr_links(self):
        completed, payload, arguments = self.run_workflow(
            pull_requests=[{"number": 54}, {"number": 55}])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertNotIn("content", payload)
        self.assertEqual(payload["allowed_mentions"], {"parse": []})
        self.assertEqual(len(payload["embeds"]), 1)
        embed = payload["embeds"][0]
        self.assertEqual(embed["url"], RUN_URL)
        self.assertEqual([field["name"] for field in embed["fields"]],
                         ["Build Status", "Branch", "Commit", "PR"])
        self.assertTrue(all(field["inline"] for field in embed["fields"][:3]))
        self.assertEqual(embed["fields"][1]["value"], "chore/53")
        self.assertEqual(embed["fields"][2]["value"], "`7adc9e3` by JEONG-J")
        self.assertEqual(embed["fields"][3]["value"],
                         f"https://github.com/{REPOSITORY}/pull/54\n"
                         f"https://github.com/{REPOSITORY}/pull/55")
        self.assertFalse(embed["fields"][3]["inline"])
        self.assertEqual(embed["footer"]["text"], REPOSITORY)
        self.assertIn("--fail", arguments)
        self.assertIn("--data-binary", arguments)
        self.assertIn("@payload.json", arguments)

    def test_push_has_no_pr_field_and_results_have_distinct_statuses(self):
        cases = [("success", "SUCCESS ✅", 5763719), ("failure", "FAILURE ❌", 15548997),
                 ("cancelled", "CANCELLED ⚠️", 16705372),
                 ("timed_out", "TIMED_OUT ❌", 15548997), ("neutral", "NEUTRAL ⚪", 9807270)]
        for result, status, color in cases:
            with self.subTest(result=result):
                completed, payload, _ = self.run_workflow(result=result)
                self.assertEqual(completed.returncode, 0, completed.stderr)
                embed = payload["embeds"][0]
                self.assertEqual(embed["fields"][0]["value"], status)
                self.assertEqual(embed["color"], color)
                self.assertEqual(len(embed["fields"]), 3)

    def test_missing_secret_and_delivery_failure_fail_the_step(self):
        completed, payload, _ = self.run_workflow(webhook="")
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("DISCORD_WEBHOOK_URL Secret is not configured.", completed.stderr)
        self.assertIsNone(payload)
        completed, _, _ = self.run_workflow(curl_exit="22")
        self.assertEqual(completed.returncode, 22)

    def test_event_strings_are_json_escaped_and_missing_author_has_a_fallback(self):
        branch = 'feature/"quoted"-branch'
        completed, payload, _ = self.run_workflow(branch=branch, author=None)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        fields = payload["embeds"][0]["fields"]
        self.assertEqual(fields[1]["value"], branch)
        self.assertEqual(fields[2]["value"], "`7adc9e3` by Unknown")


if __name__ == "__main__":
    unittest.main()
