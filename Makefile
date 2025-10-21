.PHONY: generate iOS vision macOS all test

all: iOS vision macOS

generate:
	xcodegen generate

iOS: generate
	xcodebuild -scheme MyOwnJournal -destination 'platform=iOS Simulator,name=iPhone Air' build

vision: generate
	xcodebuild -scheme MyOwnJournal-Vision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

macOS: generate
	xcodebuild -scheme MyOwnJournal-macOS -destination 'platform=macOS' build

test: generate
	xcodebuild -scheme MyOwnJournal -destination 'platform=iOS Simulator,name=iPhone Air' test
