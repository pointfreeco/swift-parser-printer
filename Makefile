XCPRETTY := $(if $(shell command -v xcpretty 2> /dev/null),xcpretty,cat)

generate-xcodeproj:
	swift package generate-xcodeproj

xcodeproj: generate-xcodeproj
	xed .

test-linux:
	docker build --tag parser-printer . \
		&& docker run --rm parser-printer

test-swift:
	swift test

test-macos: generate-xcodeproj
	set -o pipefail && \
	xcodebuild test \
		-scheme ParserPrinter-Package \
		-destination platform="macOS" \
		-derivedDataPath ./.derivedData \
		| $(XCPRETTY)

test-ios: generate-xcodeproj
	set -o pipefail && \
	xcodebuild test \
		-scheme ParserPrinter-Package \
		-destination platform="iOS Simulator,name=iPhone XR,OS=12.0" \
		-derivedDataPath ./.derivedData \
		| $(XCPRETTY)

test-playgrounds: test-macos
	swift \
		-F .derivedData/Build/Products/Debug/ \
		-suppress-warnings \
		ParserPrinter.playground/Contents.swift

test-all: test-linux test-macos test-ios test-playgrounds

clean:
	rm -rf .build/
	rm -rf .derivedData
