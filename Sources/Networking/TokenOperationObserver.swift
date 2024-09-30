//
//  TokenOperationObserver.swift
//  PAYJP
//
//  Created by 北川達也 on 2020/09/11.
//  Copyright © 2020 PAY, Inc. All rights reserved.
//

import Foundation

public extension Notification.Name {
    static let payjpTokenOperationStatusChanged = Notification.Name("jp.pay.ios.tokenOperationStatusChanged")
}

@objc public extension NSNotification {
    static let payjpTokenOperationStatusChanged = Notification.Name.payjpTokenOperationStatusChanged
}

@objc public extension PAYNotificationKey {
    static let newTokenOperationStatus: String = "newTokenOperationStatus"
}

public protocol TokenOperationObserverType {
    var status: TokenOperationStatus { get }
}

protocol TokenOperationObserverInternalType: TokenOperationObserverType {
    func startRequest()

    func completeRequest()
}

class TokenOperationObserver: TokenOperationObserverInternalType {

    static let shared = TokenOperationObserver()
    static let throttleSecond: DispatchTimeInterval = DispatchTimeInterval.seconds(2)

    private let queue = DispatchQueue(label: "jp.pay.ios.queue.TokenOperationObserver",
                                      qos: .userInitiated)
    private var dispatchAcceptable: DispatchWorkItem?
    private var dispatchRunning: DispatchWorkItem?
    private var dispatchThrottled: DispatchWorkItem?

    // MARK: - TokenOperationObserverType

    private(set) var status: TokenOperationStatus = .acceptable {
        didSet {
            if status != oldValue {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let userInfo = [PAYNotificationKey.newTokenOperationStatus: self.status.rawValue]
                    NotificationCenter.default.post(name: .payjpTokenOperationStatusChanged,
                                                    object: self,
                                                    userInfo: userInfo)
                }
            }
        }
    }

    // MARK: - TokenOperationObserverInternalType

    func startRequest() {
        cancelCurrentDispatch()
        dispatchRunning = makeDispatchUpdate(status: .running)
        if let dispatchRunning = dispatchRunning {
            queue.async(execute: dispatchRunning)
        }
    }

    func completeRequest() {
        cancelCurrentDispatch()
        dispatchThrottled = makeDispatchUpdate(status: .throttled)
        if let dispatchThrottled = dispatchThrottled {
            queue.async(execute: dispatchThrottled)
        }
        dispatchAcceptable = makeDispatchUpdate(status: .acceptable)
        if let dispatchAcceptable = dispatchAcceptable {
            queue.asyncAfter(deadline: .now() + TokenOperationObserver.throttleSecond,
                             execute: dispatchAcceptable)
        }
    }

    private func cancelCurrentDispatch() {
        dispatchAcceptable?.cancel()
        dispatchAcceptable = nil
        dispatchRunning?.cancel()
        dispatchRunning = nil
        dispatchThrottled?.cancel()
        dispatchThrottled = nil
    }

    private func makeDispatchUpdate(status: TokenOperationStatus) -> DispatchWorkItem {
        return DispatchWorkItem { [weak self] in
            self?.status = status
        }
    }
}
