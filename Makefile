.PHONY: build-small build-safe build-fast run build-and-run build-test clean

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

clean:
	rm -r .zig-cache
	rm -r zig-out
	
