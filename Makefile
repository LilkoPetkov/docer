.PHONY: build-small build-safe build-fast run build-and-run build-test clean
.DEFAULT_GOAL := help

build-run: build-safe run ## Build and run the binary with ReleaseSafe flag

run: ## Run the built binary
	./zig-out/bin/docer

test: ## Build and test the project
	zig build -Doptimize=ReleaseSafe test --summary new

build-small: ## Build with `ReleaseSmall` flag
	zig build -Doptimize=ReleaseSmall

build-safe: ## Build with `ReleaseSafe` flag
	zig build -Doptimize=ReleaseSafe

build-fast: ## Build with `ReleaseFast` flag
	zig build -Doptimize=ReleaseFast

clean: ## Clean all temporary zig resources
	rm -r .zig-cache
	rm -r zig-out
	
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
