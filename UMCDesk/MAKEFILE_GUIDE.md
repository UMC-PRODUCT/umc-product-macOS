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

`make edit` opens the Tuist manifest editor for the app, all seven Core projects, all seven Feature projects, and ProjectDescriptionHelpers. Remote SwiftPM dependencies are configured in `Tuist/Package.swift`, which is also included in the generated app workspace. Changes to generated Xcode projects should instead be made in these manifests.

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

[Aquila](https://github.com/JEONG-J/Aquila) provides HTTP transport, shared token refresh, Moya request mapping and Debug logging. `Tuist/Package.swift` pins the same commit used by UMC App. CoreNetwork retains UMC response decoding, localized error mapping, the macOS Keychain service and app-owned session cleanup. There is no local network package under `Packages/`.

`make edit-project` creates a permanent, non-blocking Tuist edit project for automated inspection. Generated project files and build artifacts are ignored.

Validate changes with package installation, workspace generation, network integration tests, app/DI tests and Debug/Release builds. Use `CODE_SIGNING_ALLOWED=NO` for unsigned local checks. `make test` includes CoreNetwork tests in the app workspace scheme.

The command names and grouped help follow UMC App. `pick` and `test-pick` select a scheme with fzf when installed and numbered input otherwise. Use a scheme with a test target, such as `UMCDesk` or `CoreDI`, for tests. `graph` writes `graph.png` and needs Graphviz (`brew install graphviz`).

Deployment branches such as `release/7` and `testFlight/8` export their trailing number as `TUIST_BUILD_NUMBER`. `CI_BRANCH` supports CI checkouts; an explicit `TUIST_BUILD_NUMBER` overrides automatic parsing. The new macOS app accepts build numbers starting at 1.

```sh
make clean      # Remove generated projects and resolved Tuist artifacts
make clean-dd   # Remove local Xcode build data
make reset      # Run both cleanup commands
make install    # Restore dependencies after clean/reset
make generate
```

Cleanup operates inside `UMCDesk/` and preserves module sources and secret configuration. `test-network` runs the CoreNetwork tests against the pinned Aquila dependency.
