# The lint checks (brew install swiftlint swiftformat). Both tools read their configuration from
# the repository root. The app itself builds and tests in Xcode.
.PHONY: lint format

# Checks only; fails on any finding.
lint:
	swiftformat --lint .
	swiftlint lint --strict

# Rewrites the files SwiftFormat can fix, then reports what SwiftLint still finds.
format:
	swiftformat .
	swiftlint lint --strict
