.PHONY: generate iOS all

all: iOS

generate:
	xcodegen generate

iOS: generate
	xcodebuild -scheme MyOwnJournal -destination 'platform=iOS Simulator,name=iPhone Air' build
