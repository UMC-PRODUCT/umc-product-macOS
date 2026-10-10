#
#  Makefile
#  UMCDesk
#
#  Created by euijjang97 on 10/6/26.
#

# UMCDesk Tuist Makefile
#
# 팀 전원이 동일한 Tuist 버전(mise.toml 고정)으로 작업하기 위한 래퍼입니다.
# mise가 tuist 버전을 관리하므로, 모든 tuist 호출은 `mise exec --` 로 감쌉니다.
#
# 사용법:
#   cd UMCDesk
#   make bootstrap   # 최초 1회: mise + tuist 설치
#   make generate    # 프로젝트 생성 (가장 자주 쓰는 커맨드)
#   make help        # 전체 타겟 목록

SHELL := /bin/bash
.DEFAULT_GOAL := help

SCHEME ?= UMCDesk
WORKSPACE := UMCDesk.xcworkspace
DESTINATION ?= platform=macOS
CONFIGURATION ?= Debug
CODE_SIGNING_ALLOWED ?= YES
DERIVED_DATA ?= .local-derived-data

MISE ?= mise
TUIST := $(MISE) exec -- tuist
DMG_PYTHON := .local-dmg-tools/bin/python

# UMC App처럼 배포 브랜치(release/번호, testFlight/번호)에서 빌드 번호를 읽습니다.
# CI_BRANCH 또는 TUIST_BUILD_NUMBER로 직접 지정할 수 있습니다.
# 개발 브랜치는 매니페스트 기본값 1을 사용합니다.
BRANCH := $(if $(CI_BRANCH),$(CI_BRANCH),$(shell git rev-parse --abbrev-ref HEAD 2>/dev/null))
TUIST_BUILD_NUMBER ?= $(shell printf '%s' '$(BRANCH)' | sed -nE 's,^(release|testFlight|testflight/external)/([0-9.]+/)?([0-9]+)$$,\3,p')
# 새 macOS 앱의 배포 빌드 번호는 1부터 시작합니다.
MIN_BUILD_NUMBER := 1
ifneq ($(strip $(TUIST_BUILD_NUMBER)),)
ifneq ($(shell [ "$(TUIST_BUILD_NUMBER)" -ge $(MIN_BUILD_NUMBER) ] 2>/dev/null && echo ok),ok)
$(error 빌드 번호 $(TUIST_BUILD_NUMBER) 는 사용할 수 없다 — $(MIN_BUILD_NUMBER) 이상이어야 한다. 배포 브랜치명을 확인하거나 TUIST_BUILD_NUMBER 를 직접 넘겨라)
endif
export TUIST_BUILD_NUMBER
endif

# ──────────────────────────────────────────────────────────────
# Help
# ──────────────────────────────────────────────────────────────

.PHONY: help
help: ## 이 도움말 출력
	@awk 'BEGIN {FS = ":.*?## "; printf "\nUMCDesk Makefile — 사용 가능한 타겟:\n\n"} \
		/^[a-zA-Z_-]+:.*?## / { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)
	@echo ""
	@echo "환경 변수 오버라이드 예시:"
	@echo "  make pick                                     # 스킴 골라서 빌드 (대화형)"
	@echo "  make test-pick                                # 스킴 골라서 테스트 (대화형)"
	@echo "  make build SCHEME=AuthDomain                  # 모듈 단위 빌드"
	@echo "  make test  SCHEME=CoreDI                      # 모듈 단위 테스트"
	@echo "  make test  DESTINATION='platform=macOS'"
	@echo "  make build CONFIGURATION=Release"
	@echo ""
	@echo "사용 가능한 스킴 목록:"
	@echo "  xcodebuild -workspace $(WORKSPACE) -list"
	@echo ""

##@ 환경 설정

.PHONY: bootstrap
bootstrap: check-mise ## 최초 환경 구축 (mise로 tuist 설치)
	@$(MISE) trust
	@echo "▶︎ mise.toml 도구 설치 중..."
	@$(MISE) install
	@echo "▶︎ tuist 버전 확인"
	@$(TUIST) version
	@echo "bootstrap 완료. 이제 'make generate' 를 실행하세요."

.PHONY: check-mise
check-mise: ## mise 설치 여부 확인
	@if ! command -v $(MISE) >/dev/null 2>&1; then \
		echo "mise 가 설치되어 있지 않습니다."; \
		echo "설치: brew install mise"; \
		echo "셸 설정: https://mise.jdx.dev/getting-started.html"; \
		exit 1; \
	fi

.PHONY: doctor
doctor: check-mise ## 개발 환경 진단
	@$(MISE) --version
	@$(TUIST) version
	@xcodebuild -version
	@cat mise.toml

##@ Tuist

.PHONY: install
install: ## SPM 의존성 설치 (tuist install)
	@$(TUIST) install

.PHONY: generate
generate: ## 워크스페이스/프로젝트 생성
	@$(TUIST) generate --no-open

.PHONY: gen
gen: generate ## generate 별칭

.PHONY: generate-open
generate-open: ## 생성 후 Xcode로 열기
	@$(TUIST) generate

.PHONY: edit
edit: ## Tuist 매니페스트 편집 모드
	@$(TUIST) edit

.PHONY: edit-project
edit-project: ## 영구 Tuist 매니페스트 편집 프로젝트 생성
	@$(TUIST) edit --permanent

.PHONY: graph
graph: ## 의존성 그래프(graph.png) 생성
	@$(TUIST) graph --format png --output-path .

.PHONY: cache-warm
cache-warm: ## Tuist 바이너리 캐시 워밍업
	@$(TUIST) cache

##@ Xcode

.PHONY: open
open: ## Xcode 워크스페이스 열기
	@if [ ! -d "$(WORKSPACE)" ]; then \
		echo "⚠️  $(WORKSPACE) 없음 → 먼저 'make generate' 실행"; \
		$(MAKE) generate; \
	fi
	@open "$(WORKSPACE)"

.PHONY: build
build: ## 빌드 ($(CONFIGURATION))
	@xcodebuild \
		-workspace "$(WORKSPACE)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination "$(DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" CODE_SIGNING_ALLOWED=$(CODE_SIGNING_ALLOWED) \
		build

.local-dmg-tools/.ready: ../tools/dmg/requirements.txt
	@python3 -m venv .local-dmg-tools
	@$(DMG_PYTHON) -m pip install --disable-pip-version-check -r $<
	@touch $@

.PHONY: dmg-test
dmg-test: generate .local-dmg-tools/.ready ## 팀 내부 테스트 DMG 생성 (공증 없음)
	@xcodebuild \
		-workspace "$(WORKSPACE)" -scheme UMCDesk -configuration Debug \
		-destination 'generic/platform=macOS' -derivedDataPath "$(DERIVED_DATA)" \
		CONFIGURATION_BUILD_DIR="$(abspath $(DERIVED_DATA))/Build/Products/Debug" \
		ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
		CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
		build
	@$(DMG_PYTHON) ../tools/dmg/build_test_dmg.py \
		"$(DERIVED_DATA)/Build/Products/Debug/UMC Desk.app" dist

.PHONY: test-dmg
test-dmg: .local-dmg-tools/.ready ## DMG 생성·설치·Finder 배치 자동 테스트
	@cd .. && UMCDesk/$(DMG_PYTHON) -m unittest discover -s tools/tests -v

.PHONY: pick test-pick
pick: PICK_ACTION = build
pick: ## 스킴을 골라 빌드 (fzf 또는 번호 선택)
test-pick: PICK_ACTION = test
test-pick: ## 스킴을 골라 테스트 (fzf 또는 번호 선택)
pick test-pick:
	@if [ ! -d "$(WORKSPACE)" ]; then \
		echo "$(WORKSPACE) 없음 → 먼저 'make generate' 실행"; exit 1; \
	fi
	@SCHEMES=$$(xcodebuild -workspace "$(WORKSPACE)" -list 2>/dev/null \
		| awk '/Schemes:/{found=1; next} found && NF{sub(/^[[:space:]]+/, ""); print}'); \
	if [ -z "$$SCHEMES" ]; then \
		echo "스킴을 찾지 못했습니다."; exit 1; \
	fi; \
	if command -v fzf >/dev/null 2>&1; then \
		SCHEME=$$(printf '%s\n' "$$SCHEMES" | fzf --prompt="$(PICK_ACTION) 스킴 > " --height=40% --reverse); \
	else \
		echo "$(PICK_ACTION) 스킴 번호를 입력하세요 (Ctrl+C 취소):"; \
		PS3="> "; IFS=$$'\n'; \
		select selected in $$SCHEMES; do \
			if [ -n "$$selected" ]; then SCHEME=$$selected; break; fi; \
		done; \
	fi; \
	if [ -z "$$SCHEME" ]; then echo "선택 취소"; exit 1; fi; \
	$(MAKE) $(PICK_ACTION) SCHEME="$$SCHEME"

.PHONY: test
test: ## 테스트 실행
	@xcodebuild \
		-workspace "$(WORKSPACE)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination "$(DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" CODE_SIGNING_ALLOWED=$(CODE_SIGNING_ALLOWED) \
		test

.PHONY: test-network
test-network: ## Aquila 연동 네트워크·토큰 테스트
	@$(MAKE) test SCHEME=CoreNetwork

##@ 정리

.PHONY: clean
clean: ## Tuist Derived/빌드 산출물 제거
	@echo "▶︎ Tuist 생성물 제거"
	@rm -rf Derived
	@rm -rf */Derived
	@rm -rf */*/Derived
	@rm -rf Tuist/.build
	@rm -f graph.dot graph.png graph.json
	@echo "▶︎ 생성된 xcodeproj/xcworkspace 제거"
	@find . -maxdepth 3 -type d -name "*.xcodeproj" -not -path "./Tuist/*" -prune -exec rm -rf {} +
	@find . -maxdepth 3 -type d -name "*.xcworkspace" -not -path "./Tuist/*" -prune -exec rm -rf {} +
	@echo "clean 완료"

.PHONY: clean-dd
clean-dd: ## 로컬 DerivedData 제거
	@rm -rf .local-derived-data .local-derived-data-* Build
	@echo "로컬 DerivedData 제거 완료"

.PHONY: reset
reset: clean clean-dd ## 전체 초기화 (clean + clean-dd)
	@echo "전체 리셋 완료. 'make install' 후 'make generate' 로 다시 생성하세요."

## 제작자 : 제옹
