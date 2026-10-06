# macOS Tuist Modules Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement the tasks inline. The user has authorized implementation of the design presented in this chat.

**Goal:** Generate a macOS workspace whose app, seven Core modules and seven three-layer Features are managed through Tuist manifests and `tuist edit`.

**Architecture:** Keep UMC App's Feature-based Clean Architecture. Extract its transport and token refresh code into a local UMCNetworkKit package; retain Keychain storage and app composition in the macOS project. The remote network repository is empty, so publishing it and migrating iOS are follow-up work.

**Tech Stack:** Swift 6, SwiftUI, macOS 26, Tuist 4.208.0, Moya, Swift Testing.

**Spec:** `docs/specs/macOS앱_전 사용자 데스크톱_설계.md`, sections 7–8, with the module ownership decisions approved in this chat.

## Global Constraints

- Use branch `chore/31`; preserve unrelated local changes.
- App target: UMCDesk. Core: Foundation, Domain, Network, DI, Routing, DesignSystem, UIComponents.
- Features: Auth, Home, Notice, Activity, Community, Matching, ProjectWorkspace.
- Presentation depends on Domain; Data implements Domain contracts. Domain must not import Data or transport implementations.
- Every target and test target uses macOS destinations. Pin Tuist to the installed UMC App version, 4.208.0.
- App-owned DI registrations share a single TokenStore and NetworkClient across windows.
- Keep module boundaries only. Do not implement screens, navigation, layout or design tokens before design inputs are provided; retain only an EmptyView app entry for compilation.
- Do not publish packages or alter the iOS or server repositories.

## Review Focus

- `tuist edit` includes every app/Core/Feature manifest and helper. The shared SwiftPM manifest is opened separately and referenced in the generated app workspace.
- A clean checkout generates without secret files or stale iOS dependencies.
- Logging out while refresh is pending cannot restore cleared tokens.
- Session cache reset must not replace the app-wide TokenStore/NetworkClient.
- Release and Debug builds must both compile on macOS.

## Task 1: Project manifests and module graph

**Files:** Rename `AppName/` to `UMCDesk/`; replace its Project/Workspace/Tuist manifests and helpers; create Core and Feature manifests and source entry points.

**Interfaces:** Produce `coreProject`, `featureProject`, common macOS settings, all Core and Feature targets.

- [x] Create macOS helpers, seven Core projects and seven Feature projects.
- [x] Create the minimal SwiftUI app entry without screen or navigation implementation.
- [x] Update Makefile, setup guide, ignore rules and CI for macOS.
- [x] Run `make install`, `make generate`, and inspect the generated target graph.

## Task 2: Network and token infrastructure

**Files:** `Packages/UMCNetworkKit/`, `UMCDesk/Core/Network/`, app dependency composition.

**Interfaces:** Consume the package from Tuist. Produce NetworkClient, MoyaNetworkAdapter, TokenStore, KeychainTokenStore and app-owned dependency registrations.

- [x] Port existing UMC App network tests and run them against the extraction.
- [x] Remove app configuration and storage dependencies from the shared package; add explicit environment and session-reset injection.
- [x] Keep the existing 401 refresh, bounded retry and transient-error handling policies.
- [x] Verify cancellation and shared DI instance lifetime with focused tests.
- [x] Run `swift test --package-path Packages/UMCNetworkKit` and the macOS CoreNetwork/DI tests.

## Task 3: Verification and review

**Interfaces:** Consume the complete target graph and sources from tasks 1–2.

- [x] Generate a permanent Tuist edit project and verify its manifest references.
- [x] Build Debug and Release and run the app/module test suite.
- [x] Obtain one read-only code review and fix actionable issues.
- [x] Record verified commands and the local-package publication limitation in the setup guide.

## Verified Results

- `make install`, `make generate`, `make graph`, and `make edit-project` succeeded.
- The permanent editor references all 15 app/Core/Feature manifests and all shared helpers.
- A clean-source export containing only Git-eligible project files passed install and generation.
- Debug and Release macOS builds succeeded with `CODE_SIGNING_ALLOWED=NO`.
- Shared package: 37 tests passed. App and DI: 6 tests passed.
- Regression checks cover logout during refresh and token persistence, Keychain deletion failure, numeric overflow, and shared dependency lifetime.
- One read-only review and its focused follow-up found no remaining issues.
- Live authentication/API integration and signed distribution builds remain outside this module-setup task.
