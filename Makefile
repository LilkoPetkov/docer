.PHONY: build-app-small build-app-safe build-app-fast run build-and-run

build-and-run: build-app-safe run

build-app-small:
	zig build -Doptimize=ReleaseSmall

build-app-safe:
	zig build -Doptimize=ReleaseSafe

build-app-fast:
	zig build -Doptimize=ReleaseFast

run: 
	./zig-out/bin/docer
