# Legacy Web Prototype

This directory is retained only as a visual and interaction prototype.

The product route is now native SwiftUI at the repository root:

- `Trellis/`
- `TrellisTests/`
- `Trellis.xcodeproj`

Do not add production features to `index.html`. Do not bridge HealthKit,
CloudKit, StoreKit, notifications, camera, microphone, PencilKit, or Watch
through the Capacitor scaffold.

The health data boundary is documented in:

- `../docs/ADR-0001-native-swiftui-health-boundary.md`

