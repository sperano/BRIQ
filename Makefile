# The lint checks (brew install swiftlint swiftformat). Both tools read their configuration from
# the repository root. The app itself builds and tests in Xcode.
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

coverage:
	swift test --package-path BRIQKit --enable-code-coverage
	@bin=$$(swift build --package-path BRIQKit --show-bin-path); \
	report=$$(llvm-cov report "$$bin/BRIQKitPackageTests.xctest" \
		-instr-profile="$$bin/codecov/default.profdata" \
		-ignore-filename-regex='$(COVERAGE_IGNORE_REGEX)'); \
	echo "$$report"; \
	pct=$$(echo "$$report" | awk '/^TOTAL/ { gsub("%","",$$10); print $$10 }'); \
	echo "Line coverage: $$pct% (minimum $(COVERAGE_MIN)%)"; \
	awk -v pct="$$pct" -v min="$(COVERAGE_MIN)" 'BEGIN { exit !(pct >= min) }' \
		|| { echo "Line coverage $$pct% is below the $(COVERAGE_MIN)% minimum"; exit 1; }
