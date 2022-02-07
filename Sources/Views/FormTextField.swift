//
//  FormTextField.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2020/04/30.
//  Copyright © 2020 PAY, Inc. All rights reserved.
//

import UIKit

protocol FormTextFieldDelegate: AnyObject {
    func didDeleteBackward(_ textField: FormTextField)
}

/// UITextFieldでdeleteキーが押されたことを検知する
class FormTextField: UITextField {
    weak var deletionDelegate: FormTextFieldDelegate?

    override func deleteBackward() {
        super.deleteBackward()
        deletionDelegate?.didDeleteBackward(self)
    }
}
