# Wedge

macOS menu-bar focus list. Product docs: [docs/product/overview.md](docs/product/overview.md).

**Requires macOS 15 Sequoia** or later.

## Develop

1. Open `wedge.xcodeproj` in Xcode.
2. Run the `wedge` scheme (menu bar icon; no Dock window after v1 shell lands).
3. Unit tests: Product → Test, or:

```bash
xcodebuild test -scheme wedge -destination 'platform=macOS' -only-testing:wedgeTests
```
