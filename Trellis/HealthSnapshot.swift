import Foundation

/// Ephemeral health data used only to render the current screen.
///
/// Architecture red line: this type must never conform to `Codable`, never be
/// persisted by the app repository, and never be sent to CloudKit or iCloud.
struct HealthSnapshot: Sendable, Equatable {
    let sleepMinutes: Int?
    let restingHeartRate: Int?
    let capturedAt: Date
}

protocol HealthSnapshotProviding: Sendable {
    func snapshot(for date: Date) async throws -> HealthSnapshot?
}

