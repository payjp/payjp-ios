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

    /// カード名義入力の有効を更新する
    ///
    /// - Parameter isCardHolderEnabled: true 有効にする
    func update(isCardHolderEnabled: Bool)

    /// トークンを生成する
    ///
    /// - Parameters:
    ///   - tenantId: テナントID
    ///   - completion: 取得結果
    func createToken(with tenantId: String?, completion: @escaping (Result<Token, Error>) -> Void)

    /// 利用可能ブランドを取得する
    ///
    /// - Parameters:
    ///   - tenantId: テナントID
    ///   - completion: 取得結果
    func fetchAcceptedBrands(with tenantId: String?, completion: CardBrandsResult?)

    /// フォームの入力値を取得する
    /// - Parameter completion: 取得結果
    func cardFormInput(completion: (Result<CardFormInput, Error>) -> Void)

    /// スキャナ起動をリクエストする
    func requestOcr()
}

protocol CardFormViewModelDelegate: AnyObject {
    /// スキャナ画面を起動する
    func startScanner()
    /// カメラ許可が必要な内容のアラートを表示する
    func showPermissionAlert()
}

class CardFormViewViewModel: CardFormViewViewModelType {

    private let cardNumberFormatter: CardNumberFormatterType
    private let cardNumberValidator: CardNumberValidatorType
    private let expirationFormatter: ExpirationFormatterType
    private let expirationValidator: ExpirationValidatorType
    private let expirationExtractor: ExpirationExtractorType
    private let cvcFormatter: CvcFormatterType
    private let cvcValidator: CvcValidatorType
    private let accountsService: AccountsServiceType
    private let tokenService: TokenServiceType
    private let permissionFetcher: PermissionFetcherType

    private var acceptedCardBrands: [CardBrand]?
    private var monthYear: (month: String, year: String)?
    private var cvc: String?
    private var cardHolder: String?

    private var isCardHolderEnabled: Bool = false

    var isValid: Bool {
        return checkCardNumberValid() &&
            checkExpirationValid() &&
            checkCvcValid() &&
            (!self.isCardHolderEnabled || checkCardHolderValid())
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
                    return .failure(.cardNumberInvalidError(value: cardNumberInput, isInstant: false))
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
        guard let holderInput = cardHolder, let cardHolder = cardHolder, !cardHolder.isEmpty else {
            self.cardHolder = nil
            return .failure(.cardHolderEmptyError(value: nil, isInstant: false))
        }
        self.cardHolder = holderInput

        return .success(holderInput)
    }

    func update(isCardHolderEnabled: Bool) {
        self.isCardHolderEnabled = isCardHolderEnabled
    }

    func createToken(with tenantId: String?, completion: @escaping (Result<Token, Error>) -> Void) {
        if let cardNumberString = cardNumber?.value, let month = monthYear?.month,
           let year = monthYear?.year, let cvc = cvc {
            tokenService.createToken(cardNumber: cardNumberString,
                                     cvc: cvc,
                                     expirationMonth: month,
                                     expirationYear: year,
                                     name: cardHolder,
                                     tenantId: tenantId) { result in
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

    func cardFormInput(completion: (Result<CardFormInput, Error>) -> Void) {
        if let cardNumberString = cardNumber?.value, let month = monthYear?.month,
           let year = monthYear?.year, let cvc = cvc {
            let input = CardFormInput(cardNumber: cardNumberString,
                                      expirationMonth: month,
                                      expirationYear: year,
                                      cvc: cvc,
                                      cardHolder: cardHolder)
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
            return !cardHolder.isEmpty
        }
        return false
    }
}
