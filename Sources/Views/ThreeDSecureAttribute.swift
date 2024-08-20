//
//  ThreeDSecureAttribute.swift
//  PAYJP
//
//  Created by Tatsuya Kitagawa on 2024/08/20.
//  Copyright © 2024 PAY, Inc. All rights reserved.
//

import Foundation

/// Protocol for 3D-Secure additional attributes.
@objc(PAYThreeDSecureAttribute)
public protocol ThreeDSecureAttribute {}

@objc(PAYThreeDSecureAttributeEmail)
public final class ThreeDSecureAttributeEmail: NSObject, ThreeDSecureAttribute {
    public let preset: String?

    @objc
    public init(preset: String? = nil) {
        self.preset = preset
    }
}

@objc(PAYThreeDSecureAttributePhone)
public final class ThreeDSecureAttributePhone: NSObject, ThreeDSecureAttribute {
    public let presetNumber: String?
    public let presetRegion: String?

    @objc
    public init(presetNumber: String? = nil, presetRegion: String? = nil) {
        self.presetNumber = presetNumber
        self.presetRegion = presetRegion
    }
}
