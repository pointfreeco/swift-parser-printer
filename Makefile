test-linux:
	docker build --tag parser-printer . \
		&& docker run --rm parser-printer

test-swift:
	swift test

test-all: test-linux test-macos test-ios
