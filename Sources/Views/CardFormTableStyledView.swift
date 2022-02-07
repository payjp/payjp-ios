//
//  CardFormTableStyledView.swift
//  PAYJP
//
//  Created by Li-Hsuan Chen on 2019/07/17.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import UIKit

/// CardFormView without label.
/// It's suitable for UITableView design.
@IBDesignable @objcMembers @objc(PAYCardFormTableStyledView)
public class CardFormTableStyledView: CardFormView, CardFormProperties {

    // MARK: CardFormView

    /// Card holder input field enabled.
    @IBInspectable var isHolderRequired: Bool = false {
        didSet {
            holderContainer.isHidden = !isHolderRequired
            holderSeparator.isHidden = !isHolderRequired
            viewModel.update(isCardHolderEnabled: isHolderRequired)
            notifyIsValidChanged()
        }
    }

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

    var inputTextColor: UIColor = Style.Color.blue
    var inputTintColor: UIColor = Style.Color.blue
    var inputTextErrorColorEnabled: Bool = false
    var cardNumberSeparator: String = "-"

    // MARK: Private

    @IBOutlet private weak var expirationSeparator: UIView!
    @IBOutlet private weak var cvcSeparator: UIView!
    @IBOutlet private weak var holderSeparator: UIView!

    @IBOutlet private weak var expirationSeparatorConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cvcSeparatorConstraint: NSLayoutConstraint!
    @IBOutlet private weak var holderSeparatorConstraint: NSLayoutConstraint!

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
        let nib = UINib(nibName: "CardFormTableStyledView", bundle: .payjpBundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView

        if let view = view {
            contentView = view
            view.frame = bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(view)
        }

        backgroundColor = Style.Color.groupedBackground

        // set images
        brandLogoImage.image = "icon_card".image
        cvcIconImage.image = "icon_card_cvc_3".image

        ocrButton.setImage("icon_camera".image, for: .normal)
        ocrButton.imageView?.contentMode = .scaleAspectFit
        ocrButton.contentHorizontalAlignment = .fill
        ocrButton.contentVerticalAlignment = .fill
        ocrButton.isHidden = !CardIOProxy.isCardIOAvailable()

        // separatorのheightを 0.5 で指定すると太さが統一ではなくなってしまうためscaleを使って対応
        // cf. https://stackoverflow.com/a/21553495
        let height = 1.0 / UIScreen.main.scale
        expirationSeparatorConstraint.constant = height
        cvcSeparatorConstraint.constant = height
        holderSeparatorConstraint.constant = height

        expirationSeparator.backgroundColor = Style.Color.separator
        cvcSeparator.backgroundColor = Style.Color.separator
        holderSeparator.backgroundColor = Style.Color.separator

        setupInputFields()
        apply(style: .defaultStyle)

        cardFormProperties = self
    }

    override public var intrinsicContentSize: CGSize {
        return contentView.intrinsicContentSize
    }

    // MARK: Private

    private func setupInputFields() {
        cardHolderTextField.keyboardType = .alphabet
        // placeholder
        cardNumberTextField.attributedPlaceholder = NSAttributedString(
            string: "payjp_card_form_number_placeholder".localized,
            attributes: [NSAttributedString.Key.foregroundColor: Style.Color.placeholderText])
        expirationTextField.attributedPlaceholder = NSAttributedString(
            string: "payjp_card_form_expiration_placeholder".localized,
            attributes: [NSAttributedString.Key.foregroundColor: Style.Color.placeholderText])
        cvcTextField.attributedPlaceholder = NSAttributedString(
            string: "payjp_card_form_cvc_placeholder".localized,
            attributes: [NSAttributedString.Key.foregroundColor: Style.Color.placeholderText])
        cardHolderTextField.attributedPlaceholder = NSAttributedString(
            string: "payjp_card_form_holder_name_placeholder".localized,
            attributes: [NSAttributedString.Key.foregroundColor: Style.Color.placeholderText])

        [cardNumberTextField, expirationTextField, cvcTextField, cardHolderTextField].forEach { textField in
            guard let textField = textField else { return }
            textField.delegate = self
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
}

extension CardFormTableStyledView: CardFormStylable {

    public func apply(style: FormStyle) {
        let inputTextColor = style.inputTextColor
        let errorTextColor = style.errorTextColor
        let tintColor = style.tintColor
        self.inputTintColor = tintColor

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
    }

    public func setCardHolderRequired(_ required: Bool) {
        isHolderRequired = required
    }
}
