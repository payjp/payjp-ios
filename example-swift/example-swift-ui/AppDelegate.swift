//
//  AppDelegate.swift
//  example-swift-ui
//
//  Created by Tatsuya Kitagawa on 2020/07/21.
//

import UIKit
import PAYJP

let PAYJPPublicKey = "pk_test_0383a1b8f91e8a6e3ea0e2a9"
let App3DSRedirectURL = "exampleswift://tds/complete"
let App3DSRedirectURLKey = "swift-app"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        PAYJPSDK.publicKey = PAYJPPublicKey
        PAYJPSDK.locale = Locale.current
        PAYJPSDK.threeDSecureURLConfiguration =
            ThreeDSecureURLConfiguration(redirectURL: URL(string: App3DSRedirectURL)!,
                                         redirectURLKey: App3DSRedirectURLKey)
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return ThreeDSecureProcessHandler.shared.completeThreeDSecureProcess(url: url)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
