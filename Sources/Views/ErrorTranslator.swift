//
//  ErrorTranslator.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/11/29.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation

protocol ErrorTranslatorType {
    func translate(error: Error) -> String
}

struct ErrorTranslator: ErrorTranslatorType {

    static let shared = ErrorTranslator()

    func translate(error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .serviceError(let response):
                let codeDescription = " (code:\(response.code ?? "none"))"
                switch response.status {
                case 402:
                    return response.message ?? "payjp_card_form_screen_error_unknown".localized + codeDescription
                case 500..<600:
                    return "payjp_card_form_screen_error_server".localized + codeDescription
                default:
                    return "payjp_card_form_screen_error_application".localized + codeDescription
                }
            case .rateLimitExceeded:
                return "payjp_card_form_screen_error_rate_limit_exceeded".localized
            case .systemError(let error):
                return error.localizedDescription
            default:
                return "payjp_card_form_screen_error_unknown".localized
            }
        }
        return error.localizedDescription
    }
}
