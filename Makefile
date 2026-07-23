PROJECT ?= PDock.xcodeproj
SCHEME ?= PDock
CONFIGURATION ?= Debug
DERIVED_DATA ?= .build
DESTINATION ?= platform=macOS,arch=arm64
CODE_SIGN_IDENTITY ?= -
CODE_SIGN_STYLE ?= Manual
DEVELOPMENT_TEAM ?=
INSTALL_DIR ?= /Applications

APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/PDock.app
INSTALL_PATH := $(INSTALL_DIR)/PDock.app
XCODEBUILD := xcodebuild
XCODE_ARGS := \
	-project "$(PROJECT)" \
	-scheme "$(SCHEME)" \
	-configuration "$(CONFIGURATION)" \
	-destination "$(DESTINATION)" \
	-derivedDataPath "$(DERIVED_DATA)"
SIGNING_ARGS := \
	CODE_SIGN_STYLE="$(CODE_SIGN_STYLE)" \
	CODE_SIGN_IDENTITY="$(CODE_SIGN_IDENTITY)" \
	DEVELOPMENT_TEAM="$(DEVELOPMENT_TEAM)"

.DEFAULT_GOAL := build

.PHONY: build install test run clean open-project print-app help

build:
	$(XCODEBUILD) $(XCODE_ARGS) $(SIGNING_ARGS) build
	@printf 'Built PDock: %s\n' "$(APP_PATH)"

install: build
	@if [ -w "$(INSTALL_DIR)" ]; then \
		rm -rf "$(INSTALL_PATH)"; \
		mv "$(APP_PATH)" "$(INSTALL_PATH)"; \
	else \
		printf 'Installing to %s requires administrator permission.\n' "$(INSTALL_DIR)"; \
		sudo rm -rf "$(INSTALL_PATH)"; \
		sudo mv "$(APP_PATH)" "$(INSTALL_PATH)"; \
	fi
	@printf 'Installed PDock: %s\n' "$(INSTALL_PATH)"

test:
	$(XCODEBUILD) $(XCODE_ARGS) CODE_SIGNING_ALLOWED=NO test

run: build
	open -n "$(APP_PATH)"

clean:
	$(XCODEBUILD) $(XCODE_ARGS) clean
	@rm -rf "$(DERIVED_DATA)"

open-project:
	open "$(PROJECT)"

print-app:
	@printf '%s\n' "$(APP_PATH)"

help:
	@printf '%s\n' \
		'make                       Build an ad-hoc signed Debug app' \
		'make install               Build and move PDock.app to /Applications' \
		'make run                   Build and launch PDock' \
		'make test                  Run the Xcode test suite' \
		'make clean                 Remove generated build products' \
		'make open-project          Open PDock.xcodeproj in Xcode' \
		'make print-app             Print the built app path' \
		'make build CONFIGURATION=Release CODE_SIGN_IDENTITY="Developer ID Application: …" DEVELOPMENT_TEAM=TEAMID'
