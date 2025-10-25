.PHONY: generate iOS iOSRun vision macOS macOSRun macRelease all test

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
	xcodebuild -scheme MyOwnJournal-Vision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

macOS: generate
	xcodebuild -scheme MyOwnJournal-macOS -destination 'platform=macOS' -derivedDataPath build build

macOSRun: macOS
	open build/Build/Products/Release/JournalMac.app

macRelease: macOS
	rm -rf ~/Applications/JournalMac.app ; true
	mv build/Build/Products/Release/JournalMac.app ~/Applications/JournalMac.app

test: generate
	xcodebuild -scheme MyOwnJournal -destination 'platform=iOS Simulator,name=iPhone Air' test
