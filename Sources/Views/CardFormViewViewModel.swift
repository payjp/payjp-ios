//
//  CardFormViewViewModel.swift
//  PAYJP
//
//  Created by Li-Hsuan Chen on 2019/07/19.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation
import AVFoundation

protocol CardFormViewViewModelType {

    /// バリデーションOKかどうか
    var isValid: Bool { get }

    /// カードブランドが変わったかどうか
    var isCardBrandChanged: Bool { get }

    /// カードブランド
    var cardBrand: CardBrand { get }

    /// カード番号
    var cardNumber: CardNumber? { get }

    /// CardFormViewModelDelegate
    var delegate: CardFormViewModelDelegate? { get set }

    /// カード番号の入力値を更新する
    ///
    /// - Parameters:
    ///   - cardNumber: cardNumber: カード番号
    ///   - separator: separator: 区切り文字
    /// - Returns: 入力結果
    func update(cardNumber: String?, separator: String) -> Result<CardNumber, FormError>

    /// 有効期限の入力値を更新する
    ///
    /// - Parameter expiration: 有効期限
    /// - Returns: 入力結果
    func update(expiration: String?) -> Result<Expiration, FormError>

    /// CVCの入力値を更新する
    ///
    /// - Parameter cvc: CVC
    /// - Returns: 入力結果
    func update(cvc: String?) -> Result<String, FormError>

    /// カード名義の入力値を更新する
    ///
    /// - Parameter cardHolder: カード名義
    /// - Returns: 入力結果
    func update(cardHolder: String?) -> Result<String, FormError>

    /// メールアドレスの入力値を更新する
    ///
    /// - Parameter email: メールアドレス
    /// - Returns: 入力結果
    func update(email: String?) -> Result<String?, FormError>

    /// 電話番号の入力値を更新する
    ///
    /// - Parameter input: 入力値
    /// - Parameter formattedValue: E 164でフォーマットされた値
    /// - Returns: 入力結果
    func updatePhoneNumber(input: String?, formattedValue: String?) -> Result<String?, FormError>

    /// トークンを生成する
    ///
    /// - Parameters:
    ///   - tenantId: テナントID
    ///   - useThreeDSecure: 3-D セキュアを利用するかどうか
    ///   - completion: 取得結果
    func createToken(with tenantId: String?, useThreeDSecure: Bool, completion: @escaping (Result<Token, Error>) -> Void)

    /// 利用可能ブランドを取得する
    ///
    /// - Parameters:
    ///   - tenantId: テナントID
    ///   - completion: 取得結果
    func fetchAcceptedBrands(with tenantId: String?, completion: CardBrandsResult?)

    /// 利用可能ブランドをセットする
    /// - Parameter brands: 利用可能ブランド
    func setAcceptedCardBrands(_ brands: [CardBrand])

    /// フォームの入力値を取得する
    /// - Parameter completion: 取得結果
    func cardFormInput(completion: (Result<CardFormInput, Error>) -> Void)

    /// スキャナ起動をリクエストする
    func requestOcr()

    /// 追加項目の設定を更新する
    func update(extraAttributes: [ExtraAttribute])
}

protocol CardFormViewModelDelegate: AnyObject {
    /// スキャナ画面を起動する
    func startScanner()
    /// カメラ許可が必要な内容のアラートを表示する
    func showPermissionAlert()
    /// 追加項目をUIに反映する
    func updateExtraAttributes(email: ExtraAttributeEmail?, phone: ExtraAttributePhone?)
}

class CardFormViewViewModel: CardFormViewViewModelType {

    private let cardNumberFormatter: CardNumberFormatterType
    private let cardNumberValidator: CardNumberValidatorType
    private let expirationFormatter: ExpirationFormatterType
    private let expirationValidator: ExpirationValidatorType
    private let expirationExtractor: ExpirationExtractorType
    private let cvcFormatter: CvcFormatterType
    private let cvcValidator: CvcValidatorType
    private let cardHolderValidator: CardHolderValidatorType
    private let accountsService: AccountsServiceType
    private let tokenService: TokenServiceType
    private let permissionFetcher: PermissionFetcherType

    private var acceptedCardBrands: [CardBrand]?
    private var monthYear: (month: String, year: String)?
    private var cvc: String?
    private var cardHolder: String?
    private var email: String?
    private var phoneNumber: String?
    private var phoneNumberInput: String? // 未入力かどうかをチェックする
    private var emailEnabled: Bool = true
    private var phoneEnabled: Bool = true

    var isValid: Bool {
        return checkCardNumberValid() &&
            checkExpirationValid() &&
            checkCvcValid() &&
            checkCardHolderValid() &&
            checkExtraAttributesValid()
    }

    var isCardBrandChanged = false
    var cardBrand: CardBrand = .unknown
    var cardNumber: CardNumber?
    weak var delegate: CardFormViewModelDelegate?

    // MARK: - Lifecycle

    init(cardNumberFormatter: CardNumberFormatterType = CardNumberFormatter(),
         cardNumberValidator: CardNumberValidatorType = CardNumberValidator(),
         expirationFormatter: ExpirationFormatterType = ExpirationFormatter(),
         expirationValidator: ExpirationValidatorType = ExpirationValidator(),
         expirationExtractor: ExpirationExtractorType = ExpirationExtractor(),
         cvcFormatter: CvcFormatterType = CvcFormatter(),
         cvcValidator: CvcValidatorType = CvcValidator(),
         cardHolderValidator: CardHolderValidatorType = CardHolderValidator(),
         accountsService: AccountsServiceType = AccountsService.shared,
         tokenService: TokenServiceType = TokenService.shared,
         permissionFetcher: PermissionFetcherType = PermissionFetcher.shared) {
        self.cardNumberFormatter = cardNumberFormatter
        self.cardNumberValidator = cardNumberValidator
        self.expirationFormatter = expirationFormatter
        self.expirationValidator = expirationValidator
        self.expirationExtractor = expirationExtractor
        self.cvcFormatter = cvcFormatter
        self.cvcValidator = cvcValidator
        self.cardHolderValidator = cardHolderValidator
        self.accountsService = accountsService
        self.tokenService = tokenService
        self.permissionFetcher = permissionFetcher
    }

    // MARK: - CardFormViewViewModelType

    func update(cardNumber: String?, separator: String) -> Result<CardNumber, FormError> {
        guard let cardNumberInput = self.cardNumberFormatter.string(from: cardNumber,
                                                                    separator: separator),
              let cardNumber = cardNumber,
              !cardNumber.isEmpty else {
            self.cardBrand = .unknown
            self.cardNumber = nil
            // cvc入力でtrimされてない入力値が表示されるのを回避するためfalseにしている
            self.isCardBrandChanged = false
            return .failure(.cardNumberEmptyError(value: nil, isInstant: false))
        }
        self.isCardBrandChanged = self.cardBrand != cardNumberInput.brand
        self.cardBrand = cardNumberInput.brand
        self.cardNumber = cardNumberInput

        if let cardNumberString = self.cardNumber?.value {
            // 利用可能ブランドのチェック
            if let acceptedCardBrands = self.acceptedCardBrands {
                if cardNumberInput.brand != .unknown && !acceptedCardBrands.contains(cardNumberInput.brand) {
                    return .failure(.cardNumberInvalidBrandError(value: cardNumberInput, isInstant: true))
                }
            }
            // 桁数チェック
            if cardNumberString.count == cardNumberInput.brand.numberLength {
                if !self.cardNumberValidator.isLuhnValid(cardNumber: cardNumberString) {
                    return .failure(.cardNumberInvalidError(value: cardNumberInput, isInstant: true))
                }
            } else if cardNumberString.count > cardNumberInput.brand.numberLength {
                return .failure(.cardNumberInvalidError(value: cardNumberInput, isInstant: true))
            } else {
                return .failure(.cardNumberInvalidError(value: cardNumberInput, isInstant: false))
            }

            if cardNumberInput.brand == .unknown {
                return .failure(.cardNumberInvalidBrandError(value: cardNumberInput, isInstant: false))
            }
        }
        return .success(cardNumberInput)
    }

    func update(expiration: String?) -> Result<Expiration, FormError> {
        guard let expirationInput = self.expirationFormatter.string(from: expiration),
              let expiration = expiration, !expiration.isEmpty else {
            self.monthYear = nil
            return .failure(.expirationEmptyError(value: nil, isInstant: false))
        }

        do {
            self.monthYear = try self.expirationExtractor.extract(expiration: expirationInput.formatted)
        } catch {
            return .failure(.expirationInvalidError(value: expirationInput, isInstant: true))
        }

        if let (month, year) = self.monthYear {
            if !self.expirationValidator.isValid(month: month, year: year) {
                return .failure(.expirationInvalidError(value: expirationInput, isInstant: true))
            }
        } else {
            return .failure(.expirationInvalidError(value: expirationInput, isInstant: false))
        }
        return .success(expirationInput)
    }

    func update(cvc: String?) -> Result<String, FormError> {
        guard var cvcInput = self.cvcFormatter.string(from: cvc, brand: self.cardBrand),
              let cvc = cvc, !cvc.isEmpty else {
            self.cvc = nil
            return .failure(.cvcEmptyError(value: nil, isInstant: false))
        }
        // ブランドが変わった時に入力文字数のままエラー表示にするための処理
        if self.isCardBrandChanged {
            cvcInput = cvc
            self.isCardBrandChanged = false
        }
        self.cvc = cvcInput

        if let cvc = self.cvc {
            let result = self.cvcValidator.isValid(cvc: cvc, brand: self.cardBrand)
            if !result.validated {
                return .failure(.cvcInvalidError(value: cvc, isInstant: result.isInstant))
            }
        }
        return .success(cvcInput)
    }

    func update(cardHolder: String?) -> Result<String, FormError> {
        guard let cardHolder = cardHolder, !cardHolder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.cardHolder = nil
            return .failure(.cardHolderEmptyError(value: cardHolder, isInstant: false))
        }
        self.cardHolder = cardHolder
        switch cardHolderValidator.validate(cardHolder: cardHolder) {
        case .valid:
            return .success(cardHolder)
        case .invalidCardHolderCharacter:
            return .failure(.cardHolderInvalidError(value: cardHolder, isInstant: true))
        case .invalidCardHolderLength:
            return .failure(.cardHolderInvalidLengthError(value: cardHolder, isInstant: true))
        }
    }

    func update(email: String?) -> Result<String?, FormError> {
        guard emailEnabled else {
            self.email = nil
            return .success(nil)
        }
        // 未入力かどうかのみチェックする
        guard let trimmed = email?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            self.email = nil
            // email / phone どちらかが入力できていれば良い
            if phoneEnabled && phoneNumber != nil {
                return .success(nil)
            }
            return .failure(.emailEmptyError(value: nil, isInstant: false))
        }
        self.email = trimmed
        return .success(trimmed)
    }

    func updatePhoneNumber(input: String?, formattedValue: String?) -> Result<String?, FormError> {
        guard phoneEnabled else {
            self.phoneNumber = nil
            return .success(nil)
        }
        self.phoneNumberInput = input
        guard let input, !input.isEmpty else {
            self.phoneNumber = nil
            // email / phone どちらかが入力できていれば良い
            if emailEnabled && email != nil {
                return .success(nil)
            }
            return .failure(.phoneNumberEmptyError(value: nil, isInstant: false))
        }
        guard let formattedValue, !formattedValue.isEmpty else {
            self.phoneNumber = nil
            return .failure(.phoneNumberInvalidError(value: input, isInstant: true))
        }
        self.phoneNumber = formattedValue
        return .success(formattedValue)
    }

    func createToken(with tenantId: String?, useThreeDSecure: Bool, completion: @escaping (Result<Token, any Error>) -> Void) {
        if let cardNumberString = cardNumber?.value, let month = monthYear?.month,
           let year = monthYear?.year, let cvc = cvc, let cardHolder = cardHolder?.trimmingCharacters(in: .whitespacesAndNewlines) {
            tokenService.createToken(cardNumber: cardNumberString,
                                     cvc: cvc,
                                     expirationMonth: month,
                                     expirationYear: year,
                                     name: cardHolder,
                                     tenantId: tenantId,
                                     email: email,
                                     phone: phoneNumber,
                                     threeDSecure: useThreeDSecure
            ) { result in
                switch result {
                case .success(let token): completion(.success(token))
                case .failure(let error): completion(.failure(error))
                }
            }
        } else {
            completion(.failure(LocalError.invalidFormInput))
        }
    }

    func fetchAcceptedBrands(with tenantId: String?, completion: CardBrandsResult?) {
        accountsService.getAcceptedBrands(tenantId: tenantId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let brands):
                self.acceptedCardBrands = brands
                completion?(.success(brands))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func setAcceptedCardBrands(_ brands: [CardBrand]) {
        self.acceptedCardBrands = brands
    }

    func cardFormInput(completion: (Result<CardFormInput, Error>) -> Void) {
        if let cardNumberString = cardNumber?.value, let month = monthYear?.month,
           let year = monthYear?.year, let cvc = cvc {
            let input = CardFormInput(cardNumber: cardNumberString,
                                      expirationMonth: month,
                                      expirationYear: year,
                                      cvc: cvc,
                                      cardHolder: cardHolder,
                                      email: email,
                                      phoneNumber: phoneNumber)
            completion(.success(input))
        } else {
            completion(.failure(LocalError.invalidFormInput))
        }
    }

    func requestOcr() {
        let status = permissionFetcher.checkCamera()
        switch status {
        case .notDetermined:
            permissionFetcher.requestCamera { [weak self] in
                guard let self = self else {return}
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {return}
                    self.delegate?.startScanner()
                }
            }
        case .authorized:
            delegate?.startScanner()
        case .denied:
            delegate?.showPermissionAlert()
        default:
            print("Unsupport camera in your device.")
        }
    }

    func update(extraAttributes: [any ExtraAttribute]) {
        let email = extraAttributes.compactMap({ $0 as? ExtraAttributeEmail }).first
        let phone = extraAttributes.compactMap({ $0 as? ExtraAttributePhone }).first
        emailEnabled = email != nil
        phoneEnabled = phone != nil
        delegate?.updateExtraAttributes(email: email, phone: phone)
    }

    // MARK: - Helpers

    private func checkCardNumberValid() -> Bool {
        if let cardNumberString = cardNumber?.value {
            return self.cardNumberValidator.isValid(cardNumber: cardNumberString, brand: self.cardBrand)
        }
        return false
    }

    private func checkExpirationValid() -> Bool {
        if let (month, year) = self.monthYear {
            return self.expirationValidator.isValid(month: month, year: year)
        }
        return false
    }

    private func checkCvcValid() -> Bool {
        if let cvc = self.cvc {
            let result = self.cvcValidator.isValid(cvc: cvc, brand: self.cardBrand)
            return result.validated
        }
        return false
    }

    private func checkCardHolderValid() -> Bool {
        if let cardHolder = self.cardHolder {
            return self.cardHolderValidator.validate(cardHolder: cardHolder) == .valid
        }
        return false
    }

    private func checkExtraAttributesValid() -> Bool {
        let emailOk = email?.isEmpty == false
        let phoneOk = phoneNumber?.isEmpty == false
        // 電話番号のinputがありvalueがないことから不正な入力とみなす
        let hasInvalidPhoneInput = !phoneOk && phoneNumberInput?.isEmpty == false
        switch (emailEnabled, phoneEnabled) {
        case (true, true):
            // 不正な入力がある場合はinvalid
            guard !hasInvalidPhoneInput else { return false }
            return emailOk || phoneOk
        case (true, _):
            return emailOk
        case (_, true):
            return phoneOk
        case (false, false):
            return true
        }
    }
}
