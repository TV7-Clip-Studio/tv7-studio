APP_DIR := forgotten_client
FLAVOR ?= dev
ENV_FILE ?= .env.$(FLAVOR)
DEVICE ?= macos
NO_FLAVOR ?= 0

ifeq ($(NO_FLAVOR),1)
RUN_FLAVOR_FLAG :=
else
RUN_FLAVOR_FLAG := --flavor $(FLAVOR)
endif

define FLUTTER
	@cd $(APP_DIR) && $(1)
endef

.PHONY: help
help:
	@echo "Common targets:"
	@echo "  make format       - dart format lib/ test/"
	@echo "  make analyze      - flutter analyze"
	@echo "  make test         - flutter test"
	@echo "  make check        - format + analyze + test"
	@echo "  make run          - flutter run $(RUN_FLAVOR_FLAG) --dart-define-from-file=$(ENV_FILE)"
	@echo "      vars: FLAVOR=$(FLAVOR) ENV_FILE=$(ENV_FILE)"
	@echo "  make run-desktop  - flutter run -d $(DEVICE) (no flavor flag; useful for macOS/Windows/Linux)"
	@echo "      vars: DEVICE=$(DEVICE) ENV_FILE=$(ENV_FILE)"
	@echo "  make gen-api      - regenerate OpenAPI client (requires openapi/forgotten-app.yaml)"

.PHONY: format
format:
	$(call FLUTTER,flutter format lib test)

.PHONY: analyze
analyze:
	$(call FLUTTER,flutter analyze)

.PHONY: test
test:
	$(call FLUTTER,flutter test)

.PHONY: check
check: format analyze test

.PHONY: run
run:
	$(call FLUTTER,flutter run $(RUN_FLAVOR_FLAG) --dart-define-from-file=$(ENV_FILE))

.PHONY: run-desktop
run-desktop:
	$(call FLUTTER,flutter run -d $(DEVICE) --dart-define-from-file=$(ENV_FILE))

.PHONY: gen-api
gen-api:
	$(call FLUTTER,./tool/generate_api.sh)
