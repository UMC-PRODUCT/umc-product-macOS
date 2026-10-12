# Cloud DMG publication

Pushing `prerelease/<version>/<build>` starts Xcode Cloud and
`.github/workflows/publish-cloud-dmg.yml`. The latter waits up to 45 minutes for
the matching branch, commit and Pre-release workflow to succeed. It downloads
only `STAPLED_NOTARIZED_ARCHIVE`, verifies the bundle/version/build, both CPU
signatures, Developer ID team, runtime, timestamp and stapled ticket, then reuses
the DMG tools. The DMG is signed, notarized, stapled and assessed before upload.

Configure these encrypted repository Actions secrets:

| Name | Value |
| --- | --- |
| `APPLE_KEY_ID` | App Store Connect API key ID |
| `APPLE_ISSUER_ID` | API team issuer UUID |
| `APPLE_PRIVATE_KEY` | Entire `.p8` PEM, including BEGIN/END lines |
| `DEVELOPER_ID_P12_BASE64` | Base64 of the **single** Developer ID Application identity, including its private key |
| `DEVELOPER_ID_P12_PASSWORD` | Password protecting that P12 |

The selected identity is `Developer ID Application: euichan Jeong (8B8B4462NV)`.
Do not export unrelated keychain identities. Cloud-managed signing keys cannot
sign a custom DMG using `codesign`, so this pipeline uses the existing local
Developer ID identity. The runner imports it into a temporary keychain and removes
the keychain and credential files in an always-run cleanup step.

Publication uses the job's `GITHUB_TOKEN` with `contents: write`; no PAT is needed.
The source commit must already be in `origin/develop`. Existing tags/releases are
never overwritten. Assets are uploaded to a draft, then published together.
Failure leaves the prior public download available. If upload leaves a draft,
inspect it before manually recovering; a retry does not overwrite it.

Use workflow dispatch with an existing prerelease branch to recover a missed
trigger before its tag has been published. The Cloud run counter is independent
of the app build number. Notarization records are retained as Actions artifacts.

The installation website reads release metadata from public GitHub Releases,
including prereleases. It requires both the uploaded DMG and `release.json`, and
checks the manifest in the release notes against the asset URL and size. The
website refreshes its cached discovery within five minutes on a fresh page load.

Checks:

```sh
node --test tools/tests/*.test.mjs
python3 -m unittest discover -s tools/tests -v
```

Run the Python suite with `UMCDesk/.local-dmg-tools/bin/python` to include real
macOS image creation and copy checks. Apple API JWTs, private keys and signed
artifact download URLs are never logged or included in release assets.
