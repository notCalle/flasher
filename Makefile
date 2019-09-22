WORKSPACE ?= flasher.xcodeproj/project.xcworkspace
SCHEME ?= flasher
PREFIX ?= /usr/local
INSTALL_TARGET := $(PREFIX)/bin/flasher
BUILD_TARGET := derived_data/Build/Products/Release/flasher
ARCHIVE_ROOT := derived_data/Build/Intermediates.noindex/ArchiveIntermediates/flasher/InstallationBuildProductsLocation
TAG := $(shell git describe 2>/dev/null || echo notag-`git describe --always`)
PACKAGE ?= derived_data/flasher-$(TAG).pkg
xcodebuild = xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME)
xcodebuild += -derivedDataPath derived_data

.PHONY: release
release:
	$(xcodebuild) -configuration release build

.PHONY: $(ARCHIVE_ROOT)
$(ARCHIVE_ROOT):
	$(xcodebuild) -configuration release install

$(PACKAGE): $(ARCHIVE_ROOT)
	productbuild --root $(ARCHIVE_ROOT) $@

.PHONY: pkg
pkg: $(PACKAGE)

.PHONY: install
install: $(INSTALL_TARGET)

$(BUILD_TARGET): release

$(INSTALL_TARGET): $(BUILD_TARGET)
	install -CSv $< $@

.PHONY: clean
clean:
	rm -rf derived_data
