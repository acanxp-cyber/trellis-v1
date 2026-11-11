import Dispatch
import XCTest
@testable import Trellis

final class VoiceCapturePermissionsTests: XCTestCase {
    @MainActor
    func testPermissionBridgeCompletesFromBackgroundQueue() async {
        let result = await VoiceCapturePermissions.value { finish in
            DispatchQueue.global(qos: .userInitiated).async {
                finish(true)
            }
        }

        XCTAssertTrue(result)
    }
}
