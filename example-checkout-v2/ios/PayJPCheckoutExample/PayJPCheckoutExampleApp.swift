//
//  PayJPCheckoutExampleApp.swift
//  PayJPCheckoutExample
//
//  2026/01/19.
//

import SwiftUI

@main
struct PayJPCheckoutExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // URL Scheme処理
                    // payjpcheckoutexample://checkout/success または
                    // payjpcheckoutexample://checkout/cancel
                    NotificationCenter.default.post(
                        name: .checkoutRedirect,
                        object: nil,
                        userInfo: ["url": url]
                    )
                }
        }
    }
}

extension Notification.Name {
    static let checkoutRedirect = Notification.Name("checkoutRedirect")
}
