test-linux:
	docker build --tag parser-printer . \
		&& docker run --rm parser-printer

test-swift:
	swift test

test-all: test-linux test-macos test-ios


swift -I .build/debug -L .build/debug -F .build/debug -lPartialIso -lURLRequestRouter -lSyntax ParserPrinter.playground/Contents.swift  

