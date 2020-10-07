//
//  CardFormDisplayStyledView.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2020/03/13.
//

import Foundation

// swiftlint:disable type_body_length file_length
/// CardFormView with card animation.
@IBDesignable @objcMembers @objc(PAYCardFormDisplayStyledView)
public class CardFormDisplayStyledView: CardFormView, CardFormProperties {

    // MARK: CardFormProperties

    var isHolderRequired: Bool = true {
        didSet {
            viewModel.update(isCardHolderEnabled: isHolderRequired)
        }
    }

    @IBOutlet weak var brandLogoImage: UIImageView!
    var cvcIconImage: UIImageView!
    var ocrButton: UIButton!

    var cardNumberTextField: FormTextField!
    var expirationTextField: FormTextField!
    var cvcTextField: FormTextField!
    var cardHolderTextField: FormTextField!

    var cardNumberErrorLabel: UILabel!
    var expirationErrorLabel: UILabel!
    var cvcErrorLabel: UILabel!
    var cardHolderErrorLabel: UILabel!

    var inputTextColor: UIColor = Style.Color.label
    var inputTintColor: UIColor = Style.Color.blue
    var inputTextErrorColorEnabled: Bool = true
    var cardNumberSeparator: String = " "

    // MARK: Private

    @IBOutlet private weak var cardDisplayView: UIView!
    @IBOutlet private weak var cardFrontView: UIStackView!
    @IBOutlet private weak var cardBackView: UIView!

    @IBOutlet private weak var cardNumberDisplayLabel: UILabel!
    @IBOutlet private weak var cvcDisplayLabel: UILabel!
    @IBOutlet private weak var cvc4DisplayLabel: UILabel!
    @IBOutlet private weak var cardHolderDisplayLabel: UILabel!
    @IBOutlet private weak var expirationDisplayLabel: UILabel!

    @IBOutlet private weak var formScrollView: UIScrollView!
    @IBOutlet private weak var cvc4BorderView: BorderView!
    @IBOutlet private weak var cvcBorderView: BorderView!
    @IBOutlet private weak var cardNumberBorderView: BorderView!
    @IBOutlet private weak var cardHolderBorderView: BorderView!
    @IBOutlet private weak var expirationBorderView: BorderView!

    private var cardNumberFieldBackground: UIView!
    private var expirationFieldBackground: UIView!
    private var cvcFieldBackground: UIView!
    private var cardHolderFieldBackground: UIView!

    private var cardNumberFieldContentView: UIStackView!
    private var expirationFieldContentView: UIStackView!
    private var cvcFieldContentView: UIStackView!
    private var cardHolderFieldContentView: UIStackView!

    private var contentView: UIView!
    private let formContentStackView: UIStackView = UIStackView()
    private var isCardDisplayFront: Bool = true
    private var isScrolling: Bool = false
    private let inputFieldMargin: CGFloat = 16.0
    private var contentPositionX: CGFloat = 0.0

    /// Camera scan action
    ///
    /// - Parameter sender: sender
    @objc private func onTapOcrButton(_ sender: Any) {
        viewModel.requestOcr()
    }

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
        let nib = UINib(nibName: "CardFormDisplayStyledView", bundle: .payjpBundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView

        if let view = view {
            contentView = view
            view.frame = bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(view)
        }

        backgroundColor = .clear

        cardNumberDisplayLabel.adjustsFontSizeToFitWidth = true

        setupViews()
        setupInputFields()
        setupScrollableForm()
        apply(style: .defaultStyle)

        formScrollView.delegate = self
        textFieldDelegate = self
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

    // MARK: CardFormView

    override func inputCardNumberSuccess(value: CardNumber) {
        updateCvc4LabelVisibility()
        updateDisplayLabel(cardNumber: value)
        cardNumberErrorLabel.text = nil
    }

    override func inputCardNumberFailure(value: CardNumber?, error: Error, forceShowError: Bool, instant: Bool) {
        updateCvc4LabelVisibility()
        if let value = value {
            updateDisplayLabel(cardNumber: value)
        } else {
            cardNumberDisplayLabel.attributedText = nil
            cardNumberDisplayLabel.text = "XXXX XXXX XXXX XXXX"
        }
        cardNumberErrorLabel.text = forceShowError || instant ? error.localizedDescription : nil
    }

    override func inputExpirationSuccess(value: Expiration) {
        updateDisplayLabel(expiration: value)
        expirationErrorLabel.text = nil
    }

    override func inputExpirationFailure(value: Expiration?, error: Error, forceShowError: Bool, instant: Bool) {
        if let value = value {
            updateDisplayLabel(expiration: value)
        } else {
            expirationDisplayLabel.attributedText = nil
            expirationDisplayLabel.text = "MM/YY"
        }
        expirationErrorLabel.text = forceShowError || instant ? error.localizedDescription : nil
    }

    override func inputCvcSuccess(value: String) {
        updateDisplayLabel(cvc: value)
        cvcErrorLabel.text = nil
    }

    override func inputCvcFailure(value: String?, error: Error, forceShowError: Bool, instant: Bool) {
        if let value = value {
            updateDisplayLabel(cvc: value)
        } else {
            cvc4DisplayLabel.attributedText = nil
            cvcDisplayLabel.attributedText = nil
            cvc4DisplayLabel.text = "••••"
            cvcDisplayLabel.text = "•••"
        }
        cvcErrorLabel.text = forceShowError || instant ? error.localizedDescription : nil
    }

    override func inputCardHolderSuccess(value: String) {
        updateDisplayLabel(cardHolder: value)
        cardHolderErrorLabel.text = nil
    }

    override func inputCardHolderFailure(value: String?, error: Error, forceShowError: Bool, instant: Bool) {
        if let value = value {
            updateDisplayLabel(cardHolder: value)
        } else {
            cardHolderDisplayLabel.attributedText = nil
            cardHolderDisplayLabel.text = "NAME"
        }
        cardHolderErrorLabel.text = forceShowError || instant ? error.localizedDescription : nil
    }

    override func updateBrandLogo(brand: CardBrand?) {
        guard let brandLogoImage = brandLogoImage else { return }
        brandLogoImage.image = brand?.displayLogoImage
    }

    override func focusNextInputField(currentField: UITextField) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            self.focusNext(currentField: currentField)
        }
    }

    // MARK: Private

    /// 各Viewのセットアップ
    private func setupViews() {
        let backgroudFrame = CGRect(x: 0,
                                    y: 0,
                                    width: formScrollView.frame.width,
                                    height: 44)
        cardNumberFieldBackground = UIView(frame: backgroudFrame)
        expirationFieldBackground = UIView(frame: backgroudFrame)
        cvcFieldBackground = UIView(frame: backgroudFrame)
        cardHolderFieldBackground = UIView(frame: backgroudFrame)

        cardNumberErrorLabel = UILabel()
        expirationErrorLabel = UILabel()
        cvcErrorLabel = UILabel()
        cardHolderErrorLabel = UILabel()

        ocrButton = UIButton()
        ocrButton.addTarget(self,
                            action: #selector(onTapOcrButton(_:)),
                            for: UIControl.Event.touchUpInside)
        ocrButton.setImage("icon_camera".image, for: .normal)
        ocrButton.imageView?.contentMode = .scaleAspectFit
        ocrButton.contentHorizontalAlignment = .fill
        ocrButton.contentVerticalAlignment = .fill
        ocrButton.isHidden = !CardIOProxy.isCardIOAvailable()

        cardNumberDisplayLabel.textColor = Style.Color.displayLabel
        expirationDisplayLabel.textColor = Style.Color.displayLabel
        cvcDisplayLabel.textColor = Style.Color.displayLabel
        cvc4DisplayLabel.textColor = Style.Color.displayLabel
        cardHolderDisplayLabel.textColor = Style.Color.displayLabel

        // カードのシャドウ
        cardDisplayView.layer.shadowColor = UIColor.black.cgColor
        cardDisplayView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        cardDisplayView.layer.shadowOpacity = 0.4
        cardDisplayView.layer.shadowRadius = 4
    }

    private func setupInputFields() {
        cardNumberTextField = FormTextField()
        expirationTextField = FormTextField()
        cvcTextField = FormTextField()
        cardHolderTextField = FormTextField()

        cardNumberTextField.borderStyle = .none
        expirationTextField.borderStyle = .none
        cvcTextField.borderStyle = .none
        cardHolderTextField.borderStyle = .none

        cardNumberTextField.clearButtonMode = .whileEditing
        expirationTextField.clearButtonMode = .whileEditing
        cvcTextField.clearButtonMode = .whileEditing
        cardHolderTextField.clearButtonMode = .whileEditing

        if #available(iOS 10.0, *) {
            cardNumberTextField.textContentType = .creditCardNumber
        }
        cardNumberTextField.keyboardType = .numberPad
        expirationTextField.keyboardType = .numberPad
        cvcTextField.keyboardType = .numberPad
        cvcTextField.isSecureTextEntry = true
        cardHolderTextField.keyboardType = .alphabet
        cardHolderTextField.autocapitalizationType = .none
        cardHolderTextField.autocorrectionType = .no
        cardHolderTextField.returnKeyType = .done

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

        cardNumberTextField.delegate = self
        cardNumberTextField.deletionDelegate = self
        expirationTextField.delegate = self
        expirationTextField.deletionDelegate = self
        cvcTextField.delegate = self
        cvcTextField.deletionDelegate = self
        cardHolderTextField.delegate = self
        cardHolderTextField.deletionDelegate = self
    }

    /// 横スクロール可能なフォームの作成
    /// ScrollViewとStackViewの組み合わせで実装
    private func setupScrollableForm() {
        // 横ScrollViewにaddするStackView
        formContentStackView.spacing = 0.0
        formContentStackView.axis = .horizontal
        formContentStackView.alignment = .fill
        formContentStackView.distribution = .fillEqually
        formContentStackView.translatesAutoresizingMaskIntoConstraints = false
        formScrollView.addSubview(formContentStackView)

        NSLayoutConstraint.activate([
            formContentStackView.topAnchor.constraint(equalTo: formScrollView.topAnchor),
            formContentStackView.leadingAnchor.constraint(equalTo: formScrollView.leadingAnchor),
            formContentStackView.bottomAnchor.constraint(equalTo: formScrollView.bottomAnchor),
            formContentStackView.trailingAnchor.constraint(equalTo: formScrollView.trailingAnchor),
            formContentStackView.heightAnchor.constraint(equalTo: formScrollView.heightAnchor),
            // widthはscrollView.widthAnchor x ページ数
            formContentStackView.widthAnchor.constraint(equalTo: formScrollView.widthAnchor,
                                                        multiplier: CGFloat(4))
        ])

        // 各入力フィールド
        cardNumberFieldContentView = setupInputContentView(backgroundView: cardNumberFieldBackground,
                                                           textField: cardNumberTextField,
                                                           errorLabel: cardNumberErrorLabel,
                                                           actionButton: ocrButton,
                                                           spacing: 8.0)
        expirationFieldContentView = setupInputContentView(backgroundView: expirationFieldBackground,
                                                           textField: expirationTextField,
                                                           errorLabel: expirationErrorLabel)
        cvcFieldContentView = setupInputContentView(backgroundView: cvcFieldBackground,
                                                    textField: cvcTextField,
                                                    errorLabel: cvcErrorLabel)
        cardHolderFieldContentView = setupInputContentView(backgroundView: cardHolderFieldBackground,
                                                           textField: cardHolderTextField,
                                                           errorLabel: cardHolderErrorLabel)

        formContentStackView.addArrangedSubview(cardNumberFieldContentView)
        formContentStackView.addArrangedSubview(expirationFieldContentView)
        formContentStackView.addArrangedSubview(cvcFieldContentView)
        formContentStackView.addArrangedSubview(cardHolderFieldContentView)
    }

    private func setupInputContentView(backgroundView: UIView,
                                       textField: UITextField,
                                       errorLabel: UILabel,
                                       actionButton: UIButton? = nil,
                                       spacing: CGFloat = 0.0) -> UIStackView {

        let inputStackView = UIStackView()
        inputStackView.spacing = spacing
        inputStackView.axis = .horizontal
        inputStackView.alignment = .fill
        inputStackView.distribution = .fill
        inputStackView.translatesAutoresizingMaskIntoConstraints = false
        inputStackView.addArrangedSubview(textField)

        backgroundView.backgroundColor = FormStyle.defaultStyle.inputFieldBackgroundColor
        backgroundView.addSubview(inputStackView)

        NSLayoutConstraint.activate([
            inputStackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor,
                                                    constant: inputFieldMargin),
            inputStackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor,
                                                     constant: -inputFieldMargin),
            inputStackView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 30.0)
        ])

        if let button = actionButton {
            inputStackView.addArrangedSubview(button)
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 24.0)
            ])
        }

        let contentStackView = UIStackView()
        contentStackView.spacing = 4.0
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(backgroundView)
        contentStackView.addArrangedSubview(errorLabel)

        NSLayoutConstraint.activate([
            errorLabel.heightAnchor.constraint(equalToConstant: 24.0),
            contentStackView.heightAnchor.constraint(equalToConstant: 72.0)
        ])

        return contentStackView
    }

    private func backFlipCard() {
        isCardDisplayFront = false
        cardFrontView.isHidden = true
        cardBackView.isHidden = false
        UIView.transition(with: cardDisplayView,
                          duration: 0.4,
                          options: .transitionFlipFromRight,
                          animations: nil,
                          completion: nil)
    }

    private func frontFlipCard() {
        isCardDisplayFront = true
        cardFrontView.isHidden = false
        cardBackView.isHidden = true
        UIView.transition(with: cardDisplayView,
                          duration: 0.4,
                          options: .transitionFlipFromLeft,
                          animations: nil,
                          completion: nil)
    }

    private func updateCvc4LabelVisibility() {
        switch currentCardBrand {
        case .americanExpress:
            cvc4BorderView.isHidden = false
        default:
            cvc4BorderView.isHidden = true
        }
    }

    private func updateDisplayLabel(cardNumber: CardNumber) {
        let range = (cardNumber.display as NSString).range(of: cardNumber.formatted)
        cardNumberDisplayLabel.attributedText = createAttributeText(string: cardNumber.display,
                                                                    range: range)
    }

    private func updateDisplayLabel(expiration: Expiration) {
        let range = (expiration.display as NSString).range(of: expiration.formatted)
        expirationDisplayLabel.attributedText = createAttributeText(string: expiration.display,
                                                                    range: range)
    }

    private func updateDisplayLabel(cvc: String) {
        let mask = String(repeating: "•", count: currentCardBrand.cvcLength)
        let range = NSRange(location: 0, length: cvc.count)
        switch currentCardBrand {
        case .americanExpress:
            cvc4DisplayLabel.attributedText = createAttributeText(string: mask,
                                                                  range: range)
        default:
            cvcDisplayLabel.attributedText = createAttributeText(string: mask,
                                                                 range: range,
                                                                 textColor: Style.Color.displayCvcLabel)
        }
    }

    private func updateDisplayLabel(cardHolder: String) {
        let range = (cardHolder as NSString).range(of: cardHolder)
        cardHolderDisplayLabel.attributedText = createAttributeText(string: cardHolder,
                                                                    range: range)
    }

    private func updateDisplayLabelHighlight(textField: UITextField) {
        cardNumberBorderView.isHighlighted = textField == cardNumberTextField
        expirationBorderView.isHighlighted = textField == expirationTextField
        if currentCardBrand == .americanExpress {
            cvc4BorderView.isHighlighted = textField == cvcTextField
        } else {
            cvcBorderView.isHighlighted = textField == cvcTextField
        }
        cardHolderBorderView.isHighlighted = textField == cardHolderTextField
    }

    private func updateCardNumberMask(textField: UITextField) {
        switch textField {
        case cardNumberTextField:
            // maskなし
            if let cardNumber = currentCardNumber {
                updateDisplayLabel(cardNumber: cardNumber)
            }
        default:
            // maskして下4桁のみ
            if let cardNumber = currentCardNumber, !cardNumber.mask.isEmpty {
                let range = (cardNumber.mask as NSString).range(of: cardNumber.mask)
                cardNumberDisplayLabel.attributedText = createAttributeText(string: cardNumber.mask,
                                                                            range: range)
            }
        }
    }

    private func createAttributeText(string: String, range: NSRange, textColor: UIColor = .white)
        -> NSMutableAttributedString {
            let attributed = NSMutableAttributedString.init(string: string)
            attributed.addAttribute(.foregroundColor,
                                    value: textColor,
                                    range: range)
            return attributed
    }

    private func focusNext(currentField: UITextField) {
        switch currentField {
        case cardNumberTextField:
            if cardNumberTextField.isFirstResponder {
                expirationTextField.becomeFirstResponder()
            }
        case expirationTextField:
            if expirationTextField.isFirstResponder {
                cvcTextField.becomeFirstResponder()
            }
        case cvcTextField:
            if cvcTextField.isFirstResponder && isHolderRequired {
                cardHolderTextField.becomeFirstResponder()
            }
        default:
            break
        }
    }
}

// MARK: UIScrollViewDelegate
extension CardFormDisplayStyledView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 各入力Viewに設定しているマージン分だけスクロール位置がずれるため調整する
        let diff = contentPositionX - scrollView.contentOffset.x
        if !isScrolling &&
            (diff == inputFieldMargin || diff == -inputFieldMargin) {
            formScrollView.setContentOffset(CGPoint(x: contentPositionX, y: 0), animated: false)
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }
}

// MARK: CardFormViewProtocol
extension CardFormDisplayStyledView: CardFormStylable {

    public func apply(style: FormStyle) {
        let inputTextColor = style.inputTextColor
        let errorTextColor = style.errorTextColor
        let tintColor = style.tintColor
        let highlightColor = style.highlightColor
        self.inputTextColor = inputTextColor
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
        // highlight
        cardNumberBorderView.borderColor = highlightColor
        expirationBorderView.borderColor = highlightColor
        cvcBorderView.borderColor = highlightColor
        cvc4BorderView.borderColor = highlightColor
        cardHolderBorderView.borderColor = highlightColor
    }

    public func setCardHolderRequired(_ required: Bool) {
        isHolderRequired = required
    }
}

extension CardFormDisplayStyledView: CardFormViewTextFieldDelegate {

    func didBeginEditing(textField: UITextField) {
        updateDisplayLabelHighlight(textField: textField)
        updateCardNumberMask(textField: textField)

        if textField == cvcTextField && currentCardBrand != .americanExpress {
            if isCardDisplayFront {
                backFlipCard()
            }
        } else {
            if !isCardDisplayFront {
                frontFlipCard()
            }
        }

        // スクロール位置調整のため、各入力Viewのpositionを保持する
        switch textField {
        case cardNumberTextField:
            contentPositionX = cardNumberFieldContentView.frame.origin.x
        case expirationTextField:
            contentPositionX = expirationFieldContentView.frame.origin.x
        case cvcTextField:
            contentPositionX = cvcFieldContentView.frame.origin.x
        case cardHolderTextField:
            contentPositionX = cardHolderFieldContentView.frame.origin.x
        default:
            break
        }
    }

    func didDeleteBackward(textField: FormTextField) {
        focusPrevious(currentField: textField)
    }

    private func focusPrevious(currentField: UITextField) {
        switch currentField {
        case cardFormProperties.expirationTextField:
            if cardFormProperties.expirationTextField.isFirstResponder {
                cardFormProperties.cardNumberTextField.becomeFirstResponder()
            }
        case cardFormProperties.cvcTextField:
            if cardFormProperties.cvcTextField.isFirstResponder {
                cardFormProperties.expirationTextField.becomeFirstResponder()
            }
        case cardFormProperties.cardHolderTextField:
            if cardFormProperties.cardHolderTextField.isFirstResponder && cardFormProperties.isHolderRequired {
                cardFormProperties.cvcTextField.becomeFirstResponder()
            }
        default:
            break
        }
    }
}
// swiftlint:enable type_body_length file_length
