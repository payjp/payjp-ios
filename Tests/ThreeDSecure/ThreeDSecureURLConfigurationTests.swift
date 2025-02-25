import XCTest
@testable import PAYJP

class ThreeDSecureURLConfigurationTests: XCTestCase {
    override func setUp() {
        super.setUp()

        PAYJPSDK.publicKey = "public_key"
    }

    func testMakeThreeDSecureEntryURL() {
        let redirectURL = URL(string: "test://")!
        let redirectURLKey = "test"
        let configuration = ThreeDSecureURLConfiguration(redirectURL: redirectURL, redirectURLKey: redirectURLKey)
        let resourceId = "ch_123"
        let expectedUrlString = "\(PAYJPApiEndpoint)tds/\(resourceId)/start?publickey=\(PAYJPSDK.publicKey!)&back=\(redirectURLKey)"
        let threeDSecureEntryURL = configuration.makeThreeDSecureEntryURL(resourceId: resourceId)

        XCTAssertEqual(threeDSecureEntryURL.absoluteString, expectedUrlString)
    }
}
