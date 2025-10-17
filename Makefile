.PHONY: generate iOS vision all test

all: iOS vision

generate:
	xcodegen generate

iOS: generate
	xcodebuild -scheme MyOwnJournal -destination 'platform=iOS Simulator,name=iPhone Air' build

vision: generate
	xcodebuild -scheme MyOwnJournal-Vision -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

test: generate
	xcodebuild -scheme MyOwnJournal -destination 'platform=iOS Simulator,name=iPhone Air' test
