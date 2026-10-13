# Cloud DMG publication

Verified against repository code on 2026-10-13. Cloud configuration, secret
availability, successful runs and the external installation website are separate
operational checks.

## Trigger and source

Push `prerelease/<version>/<build>` from an approved commit already merged into
`origin/develop`. For example, `prerelease/0.0.1/12` specifies app version `0.0.1`
and positive integer build `12`; choose an unused number after inspecting prior
tags. This example does not identify the latest release.

The external Xcode Cloud Pre-release workflow must be configured to build the
branch and run Developer ID distribution and notarization. In parallel,
[publish-cloud-dmg.yml](../../.github/workflows/publish-cloud-dmg.yml) runs on the
branch push. A workflow dispatch can recover a missed trigger using an existing
prerelease branch before its release tag is published. There is no webhook
receiver or repository_dispatch step in this implementation.

The publication job validates branch syntax and that its source SHA is an
ancestor of `origin/develop`. It refuses to overwrite an existing release tag.
Repository source validation does not itself establish that a PR was approved.

## Cloud preparation and selection

[ci_post_clone.sh](../../UMCDesk/ci_scripts/ci_post_clone.sh) installs the pinned
Tuist version and dependencies, then generates the workspace. It requires a
positive `CI_BUILD_NUMBER`. For prerelease branches, the branch version must
match `MARKETING_VERSION`; the branch build becomes `TUIST_BUILD_NUMBER` and
`TUIST_PRERELEASE=1`. Other Cloud branches use the Cloud run counter and clear the
prerelease flag. The app build and Cloud run numbers can therefore differ.

[download_notarized.mjs](download_notarized.mjs) waits up to 45 minutes for a
successful run matching the branch, source SHA and configured workflow. The
Cloud product and workflow IDs are constants in that script; update them if the
Cloud project is recreated. Pagination is handled for runs, actions and artifacts.

Only one `STAPLED_NOTARIZED_ARCHIVE` from successful actions is accepted. The
download URL must use the allowed Apple HTTPS storage host, and the response size
must match the declared size, up to 1 GiB. Signed URLs and Apple API JWTs are not
printed or included in release assets. A missing or ambiguous notarized archive
fails publication; an ordinary signed archive is not substituted.

## Required configuration

Configure these encrypted repository Actions secrets:

| Name | Value |
| --- | --- |
| `APPLE_KEY_ID` | App Store Connect API key ID |
| `APPLE_ISSUER_ID` | API team issuer UUID |
| `APPLE_PRIVATE_KEY` | Entire `.p8` PEM, including BEGIN/END lines |
| `DEVELOPER_ID_P12_BASE64` | Base64 of the selected Developer ID Application identity, including its private key |
| `DEVELOPER_ID_P12_PASSWORD` | Password protecting that P12 |

The workflow selects `Developer ID Application: euichan Jeong (8B8B4462NV)`;
the packaging validator also requires team `8B8B4462NV`. Export only the intended
identity. Actions uses a temporary Keychain and removes that Keychain and
credential files in an always-run cleanup step.

Publication uses the job's `GITHUB_TOKEN` with `contents: write`. No PAT is
required by the workflow. App API configuration is separate: the current Cloud
preparation script does not create `Secrets.xcconfig`, and committed defaults use
an `.invalid` API host. See [app configuration](../../UMCDesk/Secrets/README.md).

## Packaging and publication

[package_cloud_dmg.py](../dmg/package_cloud_dmg.py) rejects unsafe ZIP paths and
escaping symlinks. It checks the app bundle ID, version, build and exact universal
architecture set (`arm64` and `x86_64`). Both CPU signatures must have Developer
ID, the expected team, Hardened Runtime and a timestamp. The shared release tool
then validates the app signature, stapled ticket and Gatekeeper assessment
without resubmitting the already notarized app.

The existing DMG layout and installer guide are reused. The DMG is signed,
notarized, stapled and assessed before upload. The workflow creates
`v<version>-build.<build>` as a draft Pre-release containing:

- `UMC-Desk-<version>-build<build>.dmg`
- `release.json`
- `설치 안내.txt`

The release notes also include the manifest JSON. The manifest records version,
minimum macOS, download and notes URLs, architecture, size, SHA-256, source SHA
and Cloud run ID. It does not currently have a separate `build` field; the build
number is encoded in the release tag and DMG filename.

After `gh release create` finishes uploading the assets, the workflow publishes
the draft. It does not overwrite existing tags/releases. A failure preserves
previous public releases; a failed upload can leave a draft that needs inspection
before recovery. The script does not perform a second download from GitHub to
recalculate the uploaded asset checksum.

Notarization submission IDs/results are retained as the `notarization-records`
Actions artifact. Inspect a saved submission ID before repeating an interrupted
submission. The publication job timeout is 75 minutes.

## Installation website boundary

This repository produces the DMG and release metadata. It contains no website
implementation, download API or cache configuration. A separate website can use
the public GitHub Releases list, including prereleases, and validate `release.json`
against uploaded assets. `/releases/latest` alone does not serve this prerelease
channel. Website discovery, cache duration, deployment and the live download
button must be verified in that website's source and environment.

## Checks

From the repository root:

```sh
node --test tools/tests/*.test.mjs
python3 -m unittest discover -s tools/tests -v
```

Run the Python suite with `UMCDesk/.local-dmg-tools/bin/python` after
`make test-dmg` has prepared packaging dependencies to include real macOS disk
image and copy checks. These tests cover selection and packaging behavior;
they do not submit a live notarization or publish a GitHub Release.
