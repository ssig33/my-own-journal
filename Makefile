.PHONY: generate iOS iOSRun vision macOS macOSRun macRelease all test testflight testflight-iOS testflight-macOS testflight-vision

# TestFlight に上げる build の番号。App Store Connect は同じバージョンで増えていく番号を求める。
BUILD_NUMBER := $(shell date +%Y%m%d.%H%M)

all: iOS vision macOS

generate:
	xcodegen generate

iOS: generate
	xcodebuild -scheme MyOwnJournal -destination 'platform=iOS Simulator,name=iPhone Air' -derivedDataPath build build

iOSRun: iOS
	xcrun simctl boot 'iPhone Air' || true
	xcrun simctl install 'iPhone Air' build/Build/Products/Debug-iphonesimulator/MyApp.app
	xcrun simctl launch 'iPhone Air' com.ssig33.MyOwnJournal

vision: generate
	xcodebuild -scheme MyOwnJournal-Vision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' -derivedDataPath build build

macOS: generate
	xcodebuild -scheme MyOwnJournal-macOS -destination 'platform=macOS' -derivedDataPath build -allowProvisioningUpdates build

macOSRun: macOS
	open build/Build/Products/Release/JournalMac.app

macRelease: macOS
	rm -rf ~/Applications/JournalMac.app ; true
	mv build/Build/Products/Release/JournalMac.app ~/Applications/JournalMac.app

test: generate
	xcodebuild -scheme MyOwnJournal -destination 'platform=iOS Simulator,name=iPhone Air' -derivedDataPath build test

# iOS・macOS・visionOS のアプリを archive して TestFlight にアップロードする。
testflight: testflight-iOS testflight-macOS testflight-vision

# scheme を archive し、ExportOptions.plist に従って export する。$(1) は scheme、$(2) は platform。
# export は内部で rsync を使い、Homebrew の rsync が PATH にあると失敗するので /usr/bin を先にする。
define archive_and_export
	rm -rf build/$(1).xcarchive build/export/$(1)
	xcodebuild -scheme $(1) -destination 'generic/platform=$(2)' -archivePath build/$(1).xcarchive -allowProvisioningUpdates CURRENT_PROJECT_VERSION=$(BUILD_NUMBER) archive
	PATH=/usr/bin:$$PATH xcodebuild -exportArchive -archivePath build/$(1).xcarchive -exportOptionsPlist $(EXPORT_OPTIONS) -exportPath build/export/$(1) -allowProvisioningUpdates
endef

EXPORT_OPTIONS ?= ExportOptions.plist

testflight-iOS: generate
	$(call archive_and_export,MyOwnJournal,iOS)

testflight-macOS: generate
	$(call archive_and_export,MyOwnJournal-macOS,macOS)

testflight-vision: generate
	$(call archive_and_export,MyOwnJournal-Vision,visionOS)
