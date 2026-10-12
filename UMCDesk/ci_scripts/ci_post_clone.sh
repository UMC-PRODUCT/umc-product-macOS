#!/bin/bash
# Created by euijjang97 on 10/12/26.
set -euo pipefail

: "${CI_PRIMARY_REPOSITORY_PATH:?CI_PRIMARY_REPOSITORY_PATH must be set by Xcode Cloud.}"
: "${CI_BUILD_NUMBER:?CI_BUILD_NUMBER must be set by Xcode Cloud.}"
if [[ ! "$CI_BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
    echo 'CI_BUILD_NUMBER must be a positive integer.' >&2
    exit 1
fi

cd "$CI_PRIMARY_REPOSITORY_PATH/UMCDesk"
source_branch="${CI_BRANCH:-${CI_GIT_REF:-}}"
source_branch="${source_branch#refs/heads/}"
build_number="$CI_BUILD_NUMBER"
if [[ "$source_branch" == prerelease/* ]]; then
    if [[ ! "$source_branch" =~ ^prerelease/([0-9]+\.[0-9]+\.[0-9]+)/([1-9][0-9]*)$ ]]; then
        echo 'Expected prerelease/<app-version>/<positive-build-number>.' >&2
        exit 1
    fi
    branch_version="${BASH_REMATCH[1]}"
    build_number="${BASH_REMATCH[2]}"
    app_version=$(sed -nE 's/.*"MARKETING_VERSION": "([^"]+)".*/\1/p' \
        Tuist/ProjectDescriptionHelpers/Settings+Recommended.swift)
    if [[ "$branch_version" != "$app_version" ]]; then
        echo "prerelease version $branch_version does not match app version $app_version." >&2
        exit 1
    fi
fi

if ! command -v mise >/dev/null 2>&1; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install mise
fi

# Keep the app build number aligned with its prerelease branch, not the Cloud run counter.
export TUIST_BUILD_NUMBER="$build_number"
make bootstrap
make install
make generate
