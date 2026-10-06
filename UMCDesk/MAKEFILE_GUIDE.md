# UMCDesk development

Requirements: Xcode with the macOS 26 SDK or later, Swift 6, and mise.
Tuist is pinned to 4.208.0, matching UMC App.

Commands work from the repository root or from `UMCDesk/`. The root Makefile delegates to `UMCDesk/Makefile`, preserving variable overrides.

```sh
cd UMCDesk
make bootstrap
make install
make generate
make edit
```

`make edit` opens the Tuist manifest editor for the app, all seven Core projects, all seven Feature projects, and ProjectDescriptionHelpers. The shared package manifest is available in the generated app workspace; open `../Packages/UMCNetworkKit/Package.swift` separately to edit its SwiftPM configuration. Changes to generated Xcode projects should instead be made in these manifests.

```sh
make help
make doctor
make build
make pick
make build CONFIGURATION=Release
make test
make test-pick
make test SCHEME=CoreDI
make test-network
make graph
make open
make generate-open
make cache-warm
```

Feature projects create Domain, Data and Presentation static frameworks. Core projects create a single static framework. All destinations are macOS 26. The app owns dependency registration. No navigation or service screens are implemented.

Configure the API environment in `Secrets/Secrets.xcconfig` using the template before connecting to the server. A clean checkout can generate and build with the committed `.invalid` placeholder. The app entry contains only `EmptyView` for build validation. Feature Presentation, CoreRouting, CoreDesignSystem and CoreUIComponents contain module boundaries only; screen code, design tokens, layout and navigation await approved design inputs.

`Packages/UMCNetworkKit` contains the transport and token refresh code extracted from UMC App, together with its unit tests. It has no dependency on app bundles, UserDefaults or SwiftUI. Keychain storage remains in CoreNetwork. The remote shared repository is empty; publishing the package and switching both apps to the same pinned release is follow-up work.

`make edit-project` creates a permanent, non-blocking Tuist edit project for automated inspection. Generated project files and build artifacts are ignored.

Verified locally: package installation, workspace generation, permanent manifest editing, clean-source generation, unsigned Debug/Release builds, 37 shared-package tests and 6 app/DI tests. Use `CODE_SIGNING_ALLOWED=NO` for unsigned local checks.

The command names and grouped help follow UMC App. `pick` and `test-pick` select a scheme with fzf when installed and numbered input otherwise. Use a scheme with a test target, such as `UMCDesk` or `CoreDI`, for tests. `graph` writes `graph.png` and needs Graphviz (`brew install graphviz`).

Deployment branches such as `release/7` and `testFlight/8` export their trailing number as `TUIST_BUILD_NUMBER`. `CI_BRANCH` supports CI checkouts; an explicit `TUIST_BUILD_NUMBER` overrides automatic parsing. The new macOS app accepts build numbers starting at 1.

```sh
make clean      # Remove generated projects and resolved Tuist artifacts
make clean-dd   # Remove local Xcode build data
make reset      # Run both cleanup commands
make install    # Restore dependencies after clean/reset
make generate
```

Cleanup operates inside `UMCDesk/` and preserves module sources and secret configuration. `test-network` runs the extracted UMCNetworkKit tests.
