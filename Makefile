# The lint checks (brew install swiftlint swiftformat), and the test/coverage targets for BRIQKit
# (needs llvm-cov/llvm-profdata, part of the Swift toolchain). Both lint tools read their
# configuration from the repository root. The app itself builds and tests in Xcode.
.PHONY: lint format test coverage

# Checks only; fails on any finding.
lint:
	swiftformat --lint .
	swiftlint lint --strict

# Rewrites the files SwiftFormat can fix, then reports what SwiftLint still finds.
format:
	swiftformat .
	swiftlint lint --strict

# BRIQKit's own tests (BRIQKit/Tests/BRIQKitTests): runs anywhere, Linux included.
test:
	swift test --package-path BRIQKit --parallel

# The line-coverage percentage the tests first reached, with a few points of slack for edge-case
# branches added later without matching tests. Lower this only if a tracked drop is accepted;
# never raise it to make a single failing run pass.
COVERAGE_MIN := 95
# Excludes the build directory (ZIPFoundation's own sources, pulled in as a checkout), the
# auto-generated tables (same as `lint`, see CLAUDE.md) and the test sources themselves.
COVERAGE_IGNORE_REGEX := \.build/|Auto-Generated|/Tests/

# On macOS the xctest product is a bundle (the binary is inside it) and llvm-cov is reached
# through xcrun, not PATH; on Linux the xctest product is the binary itself and llvm-cov is on
# PATH directly.
coverage:
	swift test --package-path BRIQKit --enable-code-coverage
	@bin=$$(swift build --package-path BRIQKit --show-bin-path); \
	xctest="$$bin/BRIQKitPackageTests.xctest"; \
	if [ "$$(uname -s)" = "Darwin" ]; then \
		llvm_cov="$$(xcrun --find llvm-cov)"; \
		xctest="$$xctest/Contents/MacOS/BRIQKitPackageTests"; \
	else \
		llvm_cov="llvm-cov"; \
	fi; \
	report=$$("$$llvm_cov" report "$$xctest" \
		-instr-profile="$$bin/codecov/default.profdata" \
		-ignore-filename-regex='$(COVERAGE_IGNORE_REGEX)') \
		|| { echo "llvm-cov failed"; exit 1; }; \
	echo "$$report"; \
	pct=$$(echo "$$report" | awk '/^TOTAL/ { gsub("%","",$$10); print $$10 }'); \
	echo "Line coverage: $$pct% (minimum $(COVERAGE_MIN)%)"; \
	awk -v pct="$$pct" -v min="$(COVERAGE_MIN)" 'BEGIN { exit !(pct >= min) }' \
		|| { echo "Line coverage $$pct% is below the $(COVERAGE_MIN)% minimum"; exit 1; }
