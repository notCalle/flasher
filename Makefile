PREFIX ?= /usr/local
INSTALL_TARGET := $(PREFIX)/bin/flasher
BUILD_TARGET := .build/release/flasher
TAG := $(shell git describe 2>/dev/null || echo notag-`git describe --always`)
PACKAGE ?= derived_data/flasher-$(TAG).pkg
xcodebuild = xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME)
xcodebuild += -derivedDataPath derived_data

.PHONY: release
release:
	swift build --configuration release

.PHONY: install
install: $(INSTALL_TARGET)

$(BUILD_TARGET): release

$(INSTALL_TARGET): $(BUILD_TARGET)
	install -CSv $< $@

.PHONY: clean
clean:
	swift package reset
