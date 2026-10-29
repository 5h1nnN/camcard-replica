# Stage 1 Visual Shell

Completed on 2026-10-29 using Xcode 26.4 and the built-in Xcode MCP server.

## Reachable states

1. Launch
2. Local login appearance flow
3. Home with shared tab bar
4. Card list with demo detail entry
5. Capture shell
6. Card review shell
7. Save result shell
8. Card detail shell
9. Enterprise and profile tab shells

Non-core controls use one dismissible placeholder sheet. Core navigation and placeholder controls use separate accessibility identifiers.

## Validation

- Xcode MCP build: passed
- Xcode Issue Navigator warnings: 0
- Unit tests: 5 passed
- UI tests: 3 passed
- Preview snapshots inspected: launch, login, home with tab bar, card list, capture, review, result, and detail

The capture-to-review path uses the synthetic fixture in Stage 1. Real photo selection, OCR, and persistence are intentionally deferred to later stages.
