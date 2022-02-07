//
//  CardFormView.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/10/10.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import UIKit

/// CardForm style protocol.
public protocol CardFormStylable {
    /// Apply card form style.
    ///
    /// - Parameter style: card form style
    func apply(style: FormStyle)

    /// Set whether to enable card holder form.
    ///
    /// - Parameter required: card holder required
    func setCardHolderRequired(_ required: Bool)
}

protocol CardFormProperties {
    var brandLogoImage: UIImageView! { get }
    var cvcIconImage: UIImageView! { get }
    var ocrButton: UIButton! { get }

    var cardNumberTextField: FormTextField! { get }
    var expirationTextField: FormTextField! { get }
    var cvcTextField: FormTextField! { get }
    var cardHolderTextField: FormTextField! { get }

    var cardNumberErrorLabel: UILabel! { get }
    var expirationErrorLabel: UILabel! { get }
    var cvcErrorLabel: UILabel! { get }
    var cardHolderErrorLabel: UILabel! { get }

    var inputTextColor: UIColor { get }
    var inputTintColor: UIColor { get }
    var inputTextErrorColorEnabled: Bool { get }
    var isHolderRequired: Bool { get }
    var cardNumberSeparator: String { get }
}

protocol CardFormViewTextFieldDelegate: AnyObject {
    func didBeginEditing(textField: UITextField)
    func didDeleteBackward(textField: FormTextField)
}

// swiftlint:disable type_body_length file_length
/// Base class of CardFormView.
@objcMembers
public class CardFormView: UIView {

    private let expirationFormatter: ExpirationFormatterType = ExpirationFormatter()
    private let nsErrorConverter: NSErrorConverterType = NSErrorConverter()
    private var cardIOProxy: CardIOProxy!

    /// CardFormView delegate.
    public weak var delegate: CardFormViewDelegate?
    weak var textFieldDelegate: CardFormViewTextFieldDelegate?
    var viewModel: CardFormViewViewModelType = CardFormViewViewModel()
    var cardFormProperties: CardFormProperties!

    var currentCardBrand: CardBrand {
        return viewModel.cardBrand
    }
    var currentCardNumber: CardNumber? {
        return viewModel.cardNumber
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        cardIOProxy = CardIOProxy(delegate: self)
        viewModel.delegate = self
    }

    /// カード番号の入力フィールドを更新する
    ///
    /// - Parameters:
    ///   - input: カード番号
    ///   - forceShowError: エラー表示を強制するか
    private func updateCardNumberInput(input: String?, forceShowError: Bool = false, separator: String) {
        cardFormProperties.cardNumberTextField.tintColor = .clear
        let result = viewModel.update(cardNumber: input, separator: separator)
        switch result {
        case let .success(cardNumber):
            cardFormProperties.cardNumberTextField.text = cardNumber.formatted
            if cardFormProperties.inputTextErrorColorEnabled {
                cardFormProperties.cardNumberTextField.textColor = cardFormProperties.inputTextColor
            }
            inputCardNumberSuccess(value: cardNumber)
            updateBrandLogo(brand: cardNumber.brand)
            updateCvcIcon(brand: cardNumber.brand)
            focusNextInputField(currentField: cardFormProperties.cardNumberTextField)
        case let .failure(error):
            switch error {
            case let .cardNumberEmptyError(value, instant),
                 let .cardNumberInvalidError(value, instant),
                 let .cardNumberInvalidBrandError(value, instant):
                cardFormProperties.cardNumberTextField.text = value?.formatted
                if cardFormProperties.inputTextErrorColorEnabled {
                    cardFormProperties.cardNumberTextField.textColor = forceShowError ||
                        instant ? Style.Color.red : cardFormProperties.inputTextColor
                }
                inputCardNumberFailure(value: value, error: error, forceShowError: forceShowError, instant: instant)
                updateBrandLogo(brand: value?.brand)
                updateCvcIcon(brand: value?.brand)
            default:
                break
            }
        }
        cardFormProperties.cardNumberErrorLabel.isHidden = cardFormProperties.cardNumberTextField.text == nil

        // ブランドが変わったらcvcのチェックを走らせる
        if viewModel.isCardBrandChanged || input?.isEmpty == true {
            updateCvcInput(input: cardFormProperties.cvcTextField.text)
        }
    }

    /// ブランドロゴの表示を更新する
    ///
    /// - Parameter brand: カードブランド
    func updateBrandLogo(brand: CardBrand?) {
        guard let brandLogoImage = cardFormProperties.brandLogoImage else { return }
        guard let brand = brand else {
            brandLogoImage.image = "icon_card".image
            return
        }
        brandLogoImage.image = brand.logoImage
    }

    /// 有効期限の入力フィールドを更新する
    ///
    /// - Parameters:
    ///   - input: 有効期限
    ///   - forceShowError: エラー表示を強制するか
    private func updateExpirationInput(input: String?, forceShowError: Bool = false) {
        cardFormProperties.expirationTextField.tintColor = .clear
        let result = viewModel.update(expiration: input)
        switch result {
        case let .success(expiration):
            cardFormProperties.expirationTextField.text = expiration.formatted
            if cardFormProperties.inputTextErrorColorEnabled {
                cardFormProperties.expirationTextField.textColor = cardFormProperties.inputTextColor
            }
            inputExpirationSuccess(value: expiration)
            focusNextInputField(currentField: cardFormProperties.expirationTextField)
        case let .failure(error):
            switch error {
            case let .expirationEmptyError(value, instant),
                 let .expirationInvalidError(value, instant):
                cardFormProperties.expirationTextField.text = value?.formatted
                if cardFormProperties.inputTextErrorColorEnabled {
                    cardFormProperties.expirationTextField.textColor = forceShowError ||
                        instant ? Style.Color.red : cardFormProperties.inputTextColor
                }
                inputExpirationFailure(value: value, error: error, forceShowError: forceShowError, instant: instant)
            default:
                break
            }
        }
        cardFormProperties.expirationErrorLabel.isHidden = cardFormProperties.expirationTextField.text == nil
    }

    /// CVCの入力フィールドを更新する
    ///
    /// - Parameters:
    ///   - input: CVC
    ///   - forceShowError: エラー表示を強制するか
    private func updateCvcInput(input: String?, forceShowError: Bool = false) {
        cardFormProperties.cvcTextField.tintColor = .clear
        let result = viewModel.update(cvc: input)
        switch result {
        case let .success(cvc):
            cardFormProperties.cvcTextField.text = cvc
            if cardFormProperties.inputTextErrorColorEnabled {
                cardFormProperties.cvcTextField.textColor = cardFormProperties.inputTextColor
            }
            inputCvcSuccess(value: cvc)
            focusNextInputField(currentField: cardFormProperties.cvcTextField)
        case let .failure(error):
            switch error {
            case let .cvcEmptyError(value, instant),
                 let .cvcInvalidError(value, instant):
                cardFormProperties.cvcTextField.text = value
                if cardFormProperties.inputTextErrorColorEnabled {
                    cardFormProperties.cvcTextField.textColor = forceShowError ||
                        instant ? Style.Color.red : cardFormProperties.inputTextColor
                }
                inputCvcFailure(value: value, error: error, forceShowError: forceShowError, instant: instant)
            default:
                break
            }
        }
        cardFormProperties.cvcErrorLabel.isHidden = cardFormProperties.cvcTextField.text == nil
    }

    /// cvcアイコンの表示を更新する
    ///
    /// - Parameter brand: カードブランド
    private func updateCvcIcon(brand: CardBrand?) {
        guard let cvcIconImage = cardFormProperties.cvcIconImage else { return }
        guard let brand = brand else {
            cvcIconImage.image = "icon_card_cvc_3".image
            return
        }
        cvcIconImage.image = brand.cvcIconImage
    }

    /// カード名義の入力フィールドを更新する
    ///
    /// - Parameters:
    ///   - input: カード名義
    ///   - forceShowError: エラー表示を強制するか
    private func updateCardHolderInput(input: String?, forceShowError: Bool = false) {
        let result = viewModel.update(cardHolder: input)
        switch result {
        case let .success(cardHolder):
            cardFormProperties.cardHolderTextField.text = cardHolder
            if cardFormProperties.inputTextErrorColorEnabled {
                cardFormProperties.cardHolderTextField.textColor = cardFormProperties.inputTextColor
            }
            inputCardHolderSuccess(value: cardHolder)
        case let .failure(error):
            switch error {
            case let .cardHolderEmptyError(value, instant):
                cardFormProperties.cardHolderTextField.text = value
                if cardFormProperties.inputTextErrorColorEnabled {
                    cardFormProperties.cardHolderTextField.textColor = forceShowError ||
                        instant ? Style.Color.red : cardFormProperties.inputTextColor
                }
                inputCardHolderFailure(value: value, error: error, forceShowError: forceShowError, instant: instant)
            default:
                break
            }
        }
        cardFormProperties.cardHolderErrorLabel.isHidden = cardFormProperties.cardHolderTextField.text == nil
    }

    func inputCardNumberSuccess(value: CardNumber) {
        cardFormProperties.cardNumberErrorLabel.text = nil
    }

    func inputCardNumberFailure(value: CardNumber?, error: Error, forceShowError: Bool, instant: Bool) {
        cardFormProperties.cardNumberErrorLabel.text = forceShowError || instant ? error.localizedDescription : nil
    }

    func inputExpirationSuccess(value: Expiration) {
        cardFormProperties.expirationErrorLabel.text = nil
    }

    func inputExpirationFailure(value: Expiration?, error: Error, forceShowError: Bool, instant: Bool) {
        cardFormProperties.expirationErrorLabel.text = forceShowError || instant ? error.localizedDescription : nil
    }

    func inputCvcSuccess(value: String) {
        cardFormProperties.cvcErrorLabel.text = nil
    }

    func inputCvcFailure(value: String?, error: Error, forceShowError: Bool, instant: Bool) {
        cardFormProperties.cvcErrorLabel.text = forceShowError || instant ? error.localizedDescription : nil
    }

    func inputCardHolderSuccess(value: String) {
        cardFormProperties.cardHolderErrorLabel.text = nil
    }

    func inputCardHolderFailure(value: String?, error: Error, forceShowError: Bool, instant: Bool) {
        cardFormProperties.cardHolderErrorLabel.text = forceShowError || instant ? error.localizedDescription : nil
    }

    func inputCardHolderComplete() {
        cardFormProperties.cardHolderErrorLabel.isHidden = cardFormProperties.cardHolderTextField.text == nil
    }

    /// バリデーションOKの場合、次のTextFieldへフォーカスを移動する
    ///
    /// - Parameter currentField: 現在のTextField
    func focusNextInputField(currentField: UITextField) {
        switch currentField {
        case cardFormProperties.cardNumberTextField:
            if cardFormProperties.cardNumberTextField.isFirstResponder {
                cardFormProperties.expirationTextField.becomeFirstResponder()
            }
        case cardFormProperties.expirationTextField:
            if cardFormProperties.expirationTextField.isFirstResponder {
                cardFormProperties.cvcTextField.becomeFirstResponder()
            }
        case cardFormProperties.cvcTextField:
            if cardFormProperties.cvcTextField.isFirstResponder && cardFormProperties.isHolderRequired {
                cardFormProperties.cardHolderTextField.becomeFirstResponder()
            }
        default:
            break
        }
    }

    /// textFieldのtintColorをリセットする
    private func resetTintColor() {
        cardFormProperties.cardNumberTextField.tintColor = cardFormProperties.inputTintColor
        cardFormProperties.expirationTextField.tintColor = cardFormProperties.inputTintColor
        cardFormProperties.cvcTextField.tintColor = cardFormProperties.inputTintColor
        cardFormProperties.cardHolderTextField.tintColor = cardFormProperties.inputTintColor
    }

    /// textField入力値を取得する
    func cardFormInput(completion: (Result<CardFormInput, Error>) -> Void) {
        viewModel.cardFormInput(completion: completion)
    }

    /// カメラ使用を許可していない場合にアラートを表示する
    private func showCameraPermissionAlert() {
        let alertController = UIAlertController(title: "payjp_scanner_camera_permission_denied_title".localized,
                                                message: "payjp_scanner_camera_permission_denied_message".localized,
                                                preferredStyle: .alert)

        let settingsAction = UIAlertAction(
            title: "payjp_common_settings".localized,
            style: .default,
            handler: { (_) -> Void in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString ) else {
                    return
                }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(settingsURL)
                }
            })
        let closeAction = UIAlertAction(title: "payjp_common_ok".localized,
                                        style: .default,
                                        handler: nil)
        alertController.addAction(closeAction)
        alertController.addAction(settingsAction)
        alertController.preferredAction = settingsAction

        guard let viewController = UIApplication.topViewController() else {
            return
        }
        viewController.present(alertController, animated: true, completion: nil)
    }

    func notifyIsValidChanged() {
        self.delegate?.formInputValidated(in: self, isValid: isValid)
    }
}

// MARK: CardFormAction
extension CardFormView: CardFormAction {

    public var isValid: Bool {
        return viewModel.isValid
    }

    @nonobjc public func createToken(tenantId: String? = nil, completion: @escaping (Result<Token, Error>) -> Void) {
        viewModel.createToken(with: tenantId, completion: completion)
    }

    public func createTokenWith(_ tenantId: String?, completion: @escaping (Token?, NSError?) -> Void) {
        viewModel.createToken(with: tenantId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let result):
                completion(result, nil)
            case .failure(let error):
                completion(nil, self.nsErrorConverter.convert(from: error))
            }
        }
    }

    @nonobjc public func fetchBrands(tenantId: String?, completion: CardBrandsResult?) {
        viewModel.fetchAcceptedBrands(with: tenantId, completion: completion)
    }

    public func fetchBrandsWith(_ tenantId: String?, completion: (([NSString]?, NSError?) -> Void)?) {
        viewModel.fetchAcceptedBrands(with: tenantId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let result):
                let converted = result.map { (brand: CardBrand) -> NSString in return brand.rawValue as NSString }
                completion?(converted, nil)
            case .failure(let error):
                completion?(nil, self.nsErrorConverter.convert(from: error))
            }
        }
    }

    public func validateCardForm() -> Bool {
        updateCardNumberInput(input: cardFormProperties.cardNumberTextField.text,
                              forceShowError: true,
                              separator: cardFormProperties.cardNumberSeparator)
        updateExpirationInput(input: cardFormProperties.expirationTextField.text, forceShowError: true)
        updateCvcInput(input: cardFormProperties.cvcTextField.text, forceShowError: true)
        updateCardHolderInput(input: cardFormProperties.cardHolderTextField.text, forceShowError: true)
        resetTintColor()
        notifyIsValidChanged()
        return isValid
    }

    public func setupInputAccessoryView(view: UIView) {
        cardFormProperties.cardNumberTextField.inputAccessoryView = view
        cardFormProperties.expirationTextField.inputAccessoryView = view
        cardFormProperties.cvcTextField.inputAccessoryView = view
        cardFormProperties.cardHolderTextField.inputAccessoryView = view
    }
}

// MARK: Event

@objc extension CardFormView {
    func textFieldDidChange(_ textField: UITextField) {
        if textField.markedTextRange != nil {
            return
        }
        let selectedTextRangeOriginal = textField.selectedTextRange
        if let newText = textField.text {
            switch textField {
            case cardFormProperties.cardNumberTextField:
                updateCardNumberInput(input: newText, separator: cardFormProperties.cardNumberSeparator)
            case cardFormProperties.expirationTextField:
                updateExpirationInput(input: newText)
            case cardFormProperties.cvcTextField:
                updateCvcInput(input: newText)
            case cardFormProperties.cardHolderTextField:
                updateCardHolderInput(input: newText)
            default:
                break
            }
        }
        notifyIsValidChanged()
        resetTintColor()

        guard let selectedTextRange = selectedTextRangeOriginal else {
            return
        }
        // テキスト変更時にカーソル位置を復元するが、デリミタや0埋め前後でずらす
        if let beforePosition = textField.position(from: selectedTextRange.start, offset: -1),
           let beforeRange = textField.textRange(from: beforePosition, to: selectedTextRange.start),
           let textBeforeCursor = textField.text(in: beforeRange),
           !textBeforeCursor.isDigitsOnly || (textBeforeCursor == "0" && textField == cardFormProperties.expirationTextField),
           let adjustPosition = textField.position(from: selectedTextRange.start, offset: 1),
           let adjustSelectedRange = textField.textRange(from: adjustPosition, to: adjustPosition) {
            textField.selectedTextRange = adjustSelectedRange
        } else {
            textField.selectedTextRange = selectedTextRange
        }
    }
}

// MARK: UITextFieldDelegate
extension CardFormView: UITextFieldDelegate {

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {

        switch textField {
        case cardFormProperties.cardNumberTextField:
            updateCardNumberInput(input: nil, separator: cardFormProperties.cardNumberSeparator)
            updateCvcInput(input: cardFormProperties.cvcTextField.text)
        case cardFormProperties.expirationTextField:
            updateExpirationInput(input: nil)
        case cardFormProperties.cvcTextField:
            updateCvcInput(input: nil)
        case cardFormProperties.cardHolderTextField:
            updateCardHolderInput(input: nil)
        default:
            break
        }
        resetTintColor()
        notifyIsValidChanged()

        return true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        cardFormProperties.cardHolderTextField.resignFirstResponder()
        if isValid {
            delegate?.formInputDoneTapped(in: self)
        }
        return true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldDelegate?.didBeginEditing(textField: textField)
    }
}

// MARK: CardIOProxyDelegate
extension CardFormView: CardIOProxyDelegate {
    public func didCancel(in proxy: CardIOProxy) {
        cardFormProperties.ocrButton.isHidden = !CardIOProxy.isCardIOAvailable()
    }

    public func cardIOProxy(_ proxy: CardIOProxy, didFinishWith cardParams: CardIOCardParams) {
        updateCardNumberInput(input: cardParams.number, separator: cardFormProperties.cardNumberSeparator)
        updateExpirationInput(input: expirationFormatter.string(month: cardParams.expiryMonth?.intValue,
                                                                year: cardParams.expiryYear?.intValue))
        updateCvcInput(input: cardParams.cvc)

        notifyIsValidChanged()
    }
}

extension CardFormView: CardFormViewModelDelegate {

    func startScanner() {
        if let viewController = parentViewController, CardIOProxy.canReadCardWithCamera() {
            cardIOProxy.presentCardIO(from: viewController)
        }
    }

    func showPermissionAlert() {
        showCameraPermissionAlert()
    }
}

extension CardFormView: FormTextFieldDelegate {

    func didDeleteBackward(_ textField: FormTextField) {
        textFieldDelegate?.didDeleteBackward(textField: textField)
    }
}

// swiftlint:enable type_body_length file_length
