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
if ! command -v mise >/dev/null 2>&1; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install mise
fi

# Tuist must receive the Cloud number when it generates CURRENT_PROJECT_VERSION.
export TUIST_BUILD_NUMBER="$CI_BUILD_NUMBER"
make bootstrap
make install
make generate
