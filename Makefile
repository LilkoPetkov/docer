.PHONY: build-small build-safe build-fast run build-and-run build-test

build-run: build-safe run
	./zig-out/bin/docer

run:
	./zig-out/bin/docer

test:
	zig build -Doptimize=ReleaseSafe test --summary new

build-small:
	zig build -Doptimize=ReleaseSmall

build-safe:
	zig build -Doptimize=ReleaseSafe

build-fast:
	zig build -Doptimize=ReleaseFast
