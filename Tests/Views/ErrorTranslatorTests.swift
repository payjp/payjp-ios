//
//  ErrorTranslatorTests.swift
//  PAYJPTests
//
//  Created by Tadashi Wakayanagi on 2019/11/29.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import XCTest
@testable import PAYJP

class MockPAYErrorResponse: NSObject, PAYErrorResponseType, LocalizedError {

    public let status: Int
    public let message: String?
    public let param: String?
    public let code: String?
    public let type: String?

    init(status: Int, message: String?, param: String? = nil, code: String? = nil, type: String? = nil) {
        self.status = status
        self.message = message
        self.param = param
        self.code = code
        self.type = type
    }

    public override var description: String {
        // swiftlint:disable line_length
        return "status: \(status) message: \(message ?? "") param: \(param ?? "") code: \(code ?? "") type: \(type ?? "")"
        // swiftlint:enable line_length
    }

    public var errorDescription: String? { return description }
}

class ErrorTranslatorTests: XCTestCase {

    let translator = ErrorTranslator()

    let nsErrorConverter = NSErrorConverter.shared
    let decoder = JSONDecoder.shared

    func testTranslate_error402() {
        let payError = MockPAYErrorResponse(status: 402, message: "402 error")
        let apiError = APIError.serviceError(payError)

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "402 error")
    }

    func testTranslate_error402_nomessage() {
        let payError = MockPAYErrorResponse(status: 402, message: nil, code: "something_wrong")
        let apiError = APIError.serviceError(payError)

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "payjp_card_form_screen_error_unknown".localized + " (code:something_wrong)")
    }

    func testTranslate_error403() {
        let payError = MockPAYErrorResponse(status: 403, message: "403 error", code: "something_wrong")
        let apiError = APIError.serviceError(payError)

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "payjp_card_form_screen_error_application".localized + " (code:something_wrong)")
    }

    func testTranslate_error401() {
        let payError = MockPAYErrorResponse(status: 401, message: "401 error", code: "something_wrong")
        let apiError = APIError.serviceError(payError)

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "payjp_card_form_screen_error_application".localized + " (code:something_wrong)")
    }

    func testTranslate_error400() {
        let payError = MockPAYErrorResponse(status: 400, message: "400 error")
        let apiError = APIError.serviceError(payError)

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "payjp_card_form_screen_error_application".localized + " (code:none)")
    }

    func testTranslate_error500() {
        let payError = MockPAYErrorResponse(status: 500, message: "500 error", code: "maintenance")
        let apiError = APIError.serviceError(payError)

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "payjp_card_form_screen_error_server".localized + " (code:maintenance)")
    }

    func testTranslate_rateLimitExceeded() {
        let apiError = APIError.rateLimitExceeded

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "payjp_card_form_screen_error_rate_limit_exceeded".localized)
    }

    func testTranslate_systemError() {
        var userInfo = [String: Any]()
        userInfo[NSLocalizedDescriptionKey] = "Network is offline."
        let error = NSError(domain: "domain", code: -1, userInfo: userInfo)
        let apiError = APIError.systemError(error)

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "Network is offline.")
    }

    func testTranslate_unknownError() {
        let apiError = APIError.invalidResponse(nil)

        let result = translator.translate(error: apiError)
        XCTAssertEqual(result, "payjp_card_form_screen_error_unknown".localized)
    }

    func testTranslate_notApiError() {
        let error = LocalError.invalidFormInput

        let result = translator.translate(error: error)
        XCTAssertEqual(result, "Form input data is invalid.")
    }
}
