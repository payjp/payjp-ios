//
//  ExtraAttribute.swift
//  PAYJP
//
//  Created by Tatsuya Kitagawa on 2024/08/20.
//  Copyright © 2024 PAY, Inc. All rights reserved.
//

import Foundation

/// Extra attributes for card form.
/// For now it is mainly used for 3-D Secure.
/// see [https://help.pay.jp/ja/articles/9556161]
@objc(PAYExtraAttribute)
public protocol ExtraAttribute {}

@objc(PAYExtraAttributeEmail)
public final class ExtraAttributeEmail: NSObject, ExtraAttribute {
    public let preset: String?

    /// - parameters:
    ///   - preset: preset email for card form.
    @objc
    public init(preset: String? = nil) {
        self.preset = preset
    }
}

@objc(PAYExtraAttributePhone)
public final class ExtraAttributePhone: NSObject, ExtraAttribute {
    public let presetNumber: String?
    public let presetRegion: String?

    /// - parameters:
    ///   - presetNumber: preset phone number for card form. You can pass either a local phone number  or an international phone number format.
    ///   - presetRegion: preset region code for phone number. (ISO 3166-1 alpha-2) e.g.`JP`
    @objc
    public init(presetNumber: String? = nil, presetRegion: String? = nil) {
        self.presetNumber = presetNumber
        self.presetRegion = presetRegion
    }
}
