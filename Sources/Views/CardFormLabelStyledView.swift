//
//  CardFormLabelStyledView.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/09/19.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import UIKit

/// CardFormView with label.
/// It's recommended to implement with UIScrollView.
@IBDesignable @objcMembers @objc(PAYCardFormLabelStyledView)
public class CardFormLabelStyledView: CardFormView, CardFormProperties {

    // MARK: CardFormProperties

    @IBOutlet weak var brandLogoImage: UIImageView!
    @IBOutlet weak var cvcIconImage: UIImageView!
    @IBOutlet weak var holderContainer: UIStackView!
    @IBOutlet weak var ocrButton: UIButton!

    @IBOutlet weak var cardNumberTextField: FormTextField!
    @IBOutlet weak var expirationTextField: FormTextField!
    @IBOutlet weak var cvcTextField: FormTextField!
    @IBOutlet weak var cardHolderTextField: FormTextField!

    @IBOutlet weak var cardNumberErrorLabel: UILabel!
    @IBOutlet weak var expirationErrorLabel: UILabel!
    @IBOutlet weak var cvcErrorLabel: UILabel!
    @IBOutlet weak var cardHolderErrorLabel: UILabel!

    var inputTextColor: UIColor = Style.Color.label
    var inputTintColor: UIColor = Style.Color.blue
    var inputTextErrorColorEnabled: Bool = true
    var cardNumberSeparator: String = "-"

    // MARK: Private

    @IBOutlet private weak var cardNumberLabel: UILabel!
    @IBOutlet private weak var expirationLabel: UILabel!
    @IBOutlet private weak var cvcLabel: UILabel!
    @IBOutlet private weak var cardHolderLabel: UILabel!

    @IBOutlet private weak var cardNumberFieldBackground: UIView!
    @IBOutlet private weak var expirationFieldBackground: UIView!
    @IBOutlet private weak var cvcFieldBackground: UIView!
    @IBOutlet private weak var cardHolderFieldBackground: UIView!

    /// Camera scan action
    ///
    /// - Parameter sender: sender
    @IBAction func onTapOcrButton(_ sender: Any) {
        viewModel.requestOcr()
    }

    private var contentView: UIView!

    // MARK: Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        let nib = UINib(nibName: "CardFormLabelStyledView", bundle: .payjpBundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView

        if let view = view {
            contentView = view
            view.frame = bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(view)
        }

        backgroundColor = .clear

        // label
        cardNumberLabel.text = "payjp_card_form_number_label".localized
        expirationLabel.text = "payjp_card_form_expiration_label".localized
        cvcLabel.text = "payjp_card_form_cvc_label".localized
        cardHolderLabel.text = "payjp_card_form_holder_name_label".localized

        // set images
        brandLogoImage.image = "icon_card".image
        cvcIconImage.image = "icon_card_cvc_3".image

        ocrButton.setImage("icon_camera".image, for: .normal)
        ocrButton.imageView?.contentMode = .scaleAspectFit
        ocrButton.contentHorizontalAlignment = .fill
        ocrButton.contentVerticalAlignment = .fill
        ocrButton.isHidden = !CardIOProxy.isCardIOAvailable()

        setupInputFields()
        apply(style: .defaultStyle)

        cardFormProperties = self
    }

    override public var intrinsicContentSize: CGSize {
        return contentView.intrinsicContentSize
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        cardNumberFieldBackground.roundingCorners(corners: .allCorners, radius: 4.0)
        expirationFieldBackground.roundingCorners(corners: .allCorners, radius: 4.0)
        cvcFieldBackground.roundingCorners(corners: .allCorners, radius: 4.0)
        cardHolderFieldBackground.roundingCorners(corners: .allCorners, radius: 4.0)
    }

    // MARK: Private

    private func setupInputFields() {
        cardHolderTextField.keyboardType = .alphabet
        // placeholder
        cardNumberTextField.attributedPlaceholder = NSAttributedString(
            string: "payjp_card_form_label_style_number_placeholder".localized,
            attributes: [NSAttributedString.Key.foregroundColor: Style.Color.placeholderText])
        expirationTextField.attributedPlaceholder = NSAttributedString(
            string: "payjp_card_form_label_style_expiration_placeholder".localized,
            attributes: [NSAttributedString.Key.foregroundColor: Style.Color.placeholderText])
        cvcTextField.attributedPlaceholder = NSAttributedString(
            string: "payjp_card_form_label_style_cvc_placeholder".localized,
            attributes: [NSAttributedString.Key.foregroundColor: Style.Color.placeholderText])
        cardHolderTextField.attributedPlaceholder = NSAttributedString(
            string: "payjp_card_form_label_style_holder_name_placeholder".localized,
            attributes: [NSAttributedString.Key.foregroundColor: Style.Color.placeholderText])

        [cardNumberTextField, expirationTextField, cvcTextField, cardHolderTextField].forEach { textField in
            guard let textField = textField else { return }
            textField.delegate = self
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
}

// MARK: CardFormViewProtocol
extension CardFormLabelStyledView: CardFormStylable {

    public func apply(style: FormStyle) {
        let labelTextColor = style.labelTextColor
        let inputTextColor = style.inputTextColor
        let errorTextColor = style.errorTextColor
        let tintColor = style.tintColor
        let inputFieldBackgroundColor = style.inputFieldBackgroundColor
        self.inputTextColor = inputTextColor
        self.inputTintColor = tintColor

        // label text
        cardNumberLabel.textColor = labelTextColor
        expirationLabel.textColor = labelTextColor
        cvcLabel.textColor = labelTextColor
        cardHolderLabel.textColor = labelTextColor
        // input text
        cardNumberTextField.textColor = inputTextColor
        expirationTextField.textColor = inputTextColor
        cvcTextField.textColor = inputTextColor
        cardHolderTextField.textColor = inputTextColor
        // error text
        cardNumberErrorLabel.textColor = errorTextColor
        expirationErrorLabel.textColor = errorTextColor
        cvcErrorLabel.textColor = errorTextColor
        cardHolderErrorLabel.textColor = errorTextColor
        // tint
        cardNumberTextField.tintColor = tintColor
        expirationTextField.tintColor = tintColor
        cvcTextField.tintColor = tintColor
        cardHolderTextField.tintColor = tintColor
        // input field background
        cardNumberFieldBackground.backgroundColor = inputFieldBackgroundColor
        expirationFieldBackground.backgroundColor = inputFieldBackgroundColor
        cvcFieldBackground.backgroundColor = inputFieldBackgroundColor
        cardHolderFieldBackground.backgroundColor = inputFieldBackgroundColor
    }
}
