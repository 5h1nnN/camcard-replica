# Stage 0 Baseline

- Xcode: 26.4 (17E192)
- Scheme: `CamCardReplica`
- Deployment target: iOS 26.4
- Screenshot comparison device: iPhone 17 Pro, iOS 26.4
- Appearance: Light
- Unit test target: `CamCardReplicaTests`
- UI test target: `CamCardReplicaUITests`
- Synthetic OCR fixture: `SyntheticBusinessCard` in the asset catalog
- Validation tooling: `xcodebuild` and `simctl` (Xcode MCP was not exposed in this session)

The synthetic card uses an `example.com` address and clearly marked demonstration data. It contains no real personal information.
