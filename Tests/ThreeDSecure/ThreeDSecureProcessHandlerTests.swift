//
//  ThreeDSecureProcessHandlerTests.swift
//  PAYJPTests
//
//  Created by Tadashi Wakayanagi on 2020/04/03.
//  Copyright © 2020 PAY, Inc. All rights reserved.
//

import XCTest
import SafariServices
@testable import PAYJP

class ThreeDSecureProcessHandlerTests: XCTestCase {

    private func mockToken(tdsStatus: PAYThreeDSecureStatus? = nil) -> Token {
        let card = Card(identifier: "car_123",
                        name: "paykun",
                        last4Number: "1234",
                        brand: "visa",
                        expirationMonth: 12,
                        expirationYear: 19,
                        fingerprint: "abcdefg",
                        liveMode: false,
                        createAt: Date(),
                        threeDSecureStatus: tdsStatus,
                        email: "test@example.com",
                        phone: "+919012345678")
        let token = Token(identifier: "tok_123",
                          livemode: false,
                          used: false,
                          card: card,
                          createAt: Date())
        return token
    }

    func testStartThreeDSecureProcess() {
        let mockDriver = MockWebDriver()
        let handler = ThreeDSecureProcessHandler(webDriver: mockDriver)
        let token = self.mockToken(tdsStatus: .unverified)
        let mockVC = MockViewController()

        handler.startThreeDSecureProcess(viewController: mockVC,
                                         delegate: mockVC,
                                         token: token)

        XCTAssertEqual(mockDriver.openWebBrowserUrl?.absoluteString, token.tdsEntryUrl.absoluteString)
    }

    func testCompleteThreeDSecureProcess() {
        PAYJPSDK.threeDSecureURLConfiguration = ThreeDSecureURLConfiguration(redirectURL: URL(string: "test://")!,
                                                                             redirectURLKey: "test")

        let mockDriver = MockWebDriver(isSafariVC: true)
        let handler = ThreeDSecureProcessHandler(webDriver: mockDriver)
        let token = self.mockToken(tdsStatus: .unverified)
        let mockVC = MockViewController()
        let url = URL(string: "test://")!

        handler.startThreeDSecureProcess(viewController: mockVC,
                                         delegate: mockVC,
                                         token: token)

        let result = handler.completeThreeDSecureProcess(url: url)

        XCTAssertTrue(result)
        XCTAssertEqual(mockVC.tdsStatus, ThreeDSecureProcessStatus.completed)
    }

    func testCompleteThreeDSecureProcess_invalidUrl() {
        PAYJPSDK.threeDSecureURLConfiguration = ThreeDSecureURLConfiguration(redirectURL: URL(string: "test://")!,
                                                                             redirectURLKey: "test")

        let mockDriver = MockWebDriver(isSafariVC: true)
        let handler = ThreeDSecureProcessHandler(webDriver: mockDriver)
        let token = self.mockToken(tdsStatus: .unverified)
        let mockVC = MockViewController()
        let url = URL(string: "unknown://")!

        handler.startThreeDSecureProcess(viewController: mockVC,
                                         delegate: mockVC,
                                         token: token)

        let result = handler.completeThreeDSecureProcess(url: url)

        XCTAssertFalse(result)
        XCTAssertNil(mockVC.tdsStatus)
    }

    func testCompleteThreeDSecureProcess_notSafariVC() {
        PAYJPSDK.threeDSecureURLConfiguration = ThreeDSecureURLConfiguration(redirectURL: URL(string: "test://")!,
                                                                             redirectURLKey: "test")

        let mockDriver = MockWebDriver(isSafariVC: false)
        let handler = ThreeDSecureProcessHandler(webDriver: mockDriver)
        let token = self.mockToken(tdsStatus: .unverified)
        let mockVC = MockViewController()
        let url = URL(string: "test://")!

        handler.startThreeDSecureProcess(viewController: mockVC,
                                         delegate: mockVC,
                                         token: token)

        let result = handler.completeThreeDSecureProcess(url: url)

        XCTAssertFalse(result)
        XCTAssertNil(mockVC.tdsStatus)
    }

    func testWebBrowseDidFinish() {
        PAYJPSDK.threeDSecureURLConfiguration = ThreeDSecureURLConfiguration(redirectURL: URL(string: "test://")!,
                                                                             redirectURLKey: "test")

        let mockDriver = MockWebDriver(isSafariVC: true)
        let handler = ThreeDSecureProcessHandler(webDriver: mockDriver)
        let token = self.mockToken(tdsStatus: .unverified)
        let mockVC = MockViewController()

        handler.startThreeDSecureProcess(viewController: mockVC,
                                         delegate: mockVC,
                                         token: token)
        // Webブラウザを閉じた場合を想定
        handler.webBrowseDidFinish(mockDriver)

        XCTAssertEqual(mockVC.tdsStatus, ThreeDSecureProcessStatus.canceled)
    }
}
