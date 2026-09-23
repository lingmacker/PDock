PROJECT := PDock.xcodeproj
SCHEME := PDock
CONFIGURATION := Debug
DERIVED_DATA := .build
APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/PDock.app
XCODE_ARGS := -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -derivedDataPath "$(DERIVED_DATA)" CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES

.PHONY: build run clean

build:
	xcodebuild $(XCODE_ARGS) build

run: build
	open -n "$(APP_PATH)"

clean:
	rm -rf "$(DERIVED_DATA)"
