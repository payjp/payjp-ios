//
//  PresetPhoneNumberTextField.swift
//  PAYJP
//
//  Created by Tatsuya Kitagawa on 2024/08/22.
//  Copyright © 2024 PAY, Inc. All rights reserved.
//

import Foundation
import PhoneNumberKit

class PresetPhoneNumberTextField : PhoneNumberTextField {
    override var defaultRegion: String {
        get {
            presetRegion ?? super.defaultRegion
        }
        set {
            // no-op (for only compatibility)
        }
    }

    var presetRegion: String? {
        didSet {
            if let presetRegion {
                partialFormatter.defaultRegion = presetRegion
                withDefaultPickerUIOptions
                updatePlaceholder()
            }
        }
    }
}
