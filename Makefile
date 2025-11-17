.PHONY: format analyze test security e2e secrets check

format:
	flutter format lib test

analyze:
	flutter analyze

test:
	flutter test

security:
	dart pub outdated --mode=null-safety
	flutter pub deps --style=compact

e2e:
	flutter test integration_test

secrets:
	docker run --rm -v $(PWD):/repo zricethezav/gitleaks:8.18.2 detect --source=/repo --no-git --redact

check: format analyze test e2e security secrets
