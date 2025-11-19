.PHONY: setup format analyze test security e2e secrets check all

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

secrets:
	if command -v docker >/dev/null 2>&1; then \
		docker run --rm -v $(PWD):/repo zricethezav/gitleaks:8.18.2 detect --source=/repo --no-git --redact; \
	else \
		curl -sSL https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz -o /tmp/gitleaks.tar.gz && \
		tar -xzf /tmp/gitleaks.tar.gz -C /tmp && \
		/tmp/gitleaks detect --source=$(PWD) --no-git --redact; \
	fi

check: format analyze test e2e security secrets

all: setup check
