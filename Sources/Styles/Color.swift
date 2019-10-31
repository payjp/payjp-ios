//
//  Color.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/09/24.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation

extension Style {
    final class Color {
        static var black: UIColor {
            return .init(hex: "030300")
        }
        static var gray: UIColor {
            return .init(hex: "8e8e93")
        }
        static var red: UIColor {
            return .init(hex: "ff0000")
        }
        static var blue: UIColor {
            return .init(hex: "007aff")
        }
    }
}