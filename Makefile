.PHONY: setup format analyze test security e2e secrets check all run-web run-ios run-android mock-api

RUN_ARGS ?=
PORT ?= 5050
GITLEAKS_VERSION := 8.18.2
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
GITLEAKS_ARCH := linux_x64
ifeq ($(UNAME_S),Darwin)
  ifeq ($(UNAME_M),arm64)
    GITLEAKS_ARCH := darwin_arm64
  else
    GITLEAKS_ARCH := darwin_x64
  endif
endif
GITLEAKS_ARCHIVE := gitleaks_$(GITLEAKS_VERSION)_$(GITLEAKS_ARCH).tar.gz
GITLEAKS_URL := https://github.com/gitleaks/gitleaks/releases/download/v$(GITLEAKS_VERSION)/$(GITLEAKS_ARCHIVE)
GITLEAKS_BIN := /tmp/gitleaks_$(GITLEAKS_VERSION)

setup:
	flutter pub get

format:
	dart format lib test integration_test

analyze:
	flutter analyze

test:
	flutter test

security:
	dart pub outdated
	flutter pub deps --style=compact

e2e:
	flutter test integration_test -d flutter-tester

run-web:
	flutter run -d chrome $(RUN_ARGS)

run-ios:
	flutter run -d ios $(RUN_ARGS)

run-android:
	flutter run -d android $(RUN_ARGS)

mock-api:
	dart run tool/mock_template_go.dart --port=$(PORT)

secrets:
	if command -v docker >/dev/null 2>&1; then \
		docker run --rm -v $(PWD):/repo zricethezav/gitleaks:$(GITLEAKS_VERSION) detect --source=/repo --no-git --redact || \
			(curl -sSL $(GITLEAKS_URL) -o /tmp/$(GITLEAKS_ARCHIVE) && \
			tar -xzf /tmp/$(GITLEAKS_ARCHIVE) -C /tmp && \
			rm -f $(GITLEAKS_BIN) && mv /tmp/gitleaks $(GITLEAKS_BIN) && chmod +x $(GITLEAKS_BIN) && \
			$(GITLEAKS_BIN) detect --source=$(PWD) --no-git --redact); \
	else \
		curl -sSL $(GITLEAKS_URL) -o /tmp/$(GITLEAKS_ARCHIVE) && \
		tar -xzf /tmp/$(GITLEAKS_ARCHIVE) -C /tmp && \
		rm -f $(GITLEAKS_BIN) && mv /tmp/gitleaks $(GITLEAKS_BIN) && chmod +x $(GITLEAKS_BIN) && \
		$(GITLEAKS_BIN) detect --source=$(PWD) --no-git --redact; \
	fi

check: format analyze test e2e security secrets

all: setup check
