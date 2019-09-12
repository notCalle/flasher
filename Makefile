WORKSPACE ?= flasher.xcodeproj/project.xcworkspace
SCHEME ?= flasher
PREFIX ?= /usr/local
INSTALL_TARGET = $(PREFIX)/bin/flasher
BUILD_TARGET = derived_data/Build/Products/Release/flasher

xcodebuild = xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME)
xcodebuild += -derivedDataPath derived_data

.PHONY: release
release:
	$(xcodebuild) -configuration release build

.PHONY: install
install: $(INSTALL_TARGET)

$(BUILD_TARGET): release

$(INSTALL_TARGET): $(BUILD_TARGET)
	install -CSv $< $@

.DEFAULT:
	$(xcodebuild) $@
