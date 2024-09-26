//
//  CardFormScreenPresenter.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/12/04.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation

protocol CardFormScreenDelegate: AnyObject {
    // update view
    func reloadBrands(brands: [CardBrand])
    func showIndicator()
    func dismissIndicator()
    func enableSubmitButton()
    func disableSubmitButton()
    func showErrorView(message: String, buttonHidden: Bool)
    func dismissErrorView()
    func showErrorAlert(message: String)
    func presentVerificationScreen(token: Token)
    // callback
    func didCompleteCardForm(with result: CardFormResult)
    func didProduced(with token: Token,
                     completionHandler: @escaping (Error?) -> Void)
}

protocol CardFormScreenPresenterType {
    var cardFormResultSuccess: Bool { get }

    func createToken(tenantId: String?, useThreeDSecure: Bool, formInput: CardFormInput)
    func completeTokenTds()
    func fetchBrands(tenantId: String?)
    func tokenOperationStatusDidUpdate(status: TokenOperationStatus)
}

class CardFormScreenPresenter: CardFormScreenPresenterType {
    var cardFormResultSuccess: Bool = false
    var incompletedToken: Token?

    private weak var delegate: CardFormScreenDelegate?
    private var tokenOperationStatus: TokenOperationStatus
    private var tokenizeProgressing: Bool = false

    private let accountsService: AccountsServiceType
    private let tokenService: TokenServiceType
    private let errorTranslator: ErrorTranslatorType
    private let dispatchQueue: DispatchQueue

    init(delegate: CardFormScreenDelegate,
         accountsService: AccountsServiceType = AccountsService.shared,
         tokenService: TokenServiceType = TokenService.shared,
         errorTranslator: ErrorTranslatorType = ErrorTranslator.shared,
         dispatchQueue: DispatchQueue = DispatchQueue.main) {
        self.delegate = delegate
        self.accountsService = accountsService
        self.tokenService = tokenService
        self.errorTranslator = errorTranslator
        self.dispatchQueue = dispatchQueue
        self.tokenOperationStatus = tokenService.tokenOperationObserver.status
    }

    func createToken(tenantId: String?, useThreeDSecure: Bool, formInput: CardFormInput) {
        tokenizeProgressing = true
        updateIndicatingUI()
        tokenService.createToken(cardNumber: formInput.cardNumber,
                                 cvc: formInput.cvc,
                                 expirationMonth: formInput.expirationMonth,
                                 expirationYear: formInput.expirationYear,
                                 name: formInput.cardHolder,
                                 tenantId: tenantId,
                                 email: formInput.email,
                                 phone: formInput.phoneNumber,
                                 threeDSecure: useThreeDSecure
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                if let status = token.card.threeDSecureStatus, status == .unverified {
                    self.incompletedToken = token
                    self.dispatchQueue.async { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.presentVerificationScreen(token: token)
                    }
                } else {
                    self.creatingTokenCompleted(token: token)
                }
            case .failure(let error):
                self.showErrorAlert(message: self.errorTranslator.translate(error: error))
            }
        }
    }

    func fetchBrands(tenantId: String?) {
        delegate?.showIndicator()
        delegate?.dismissErrorView()
        accountsService.getAcceptedBrands(tenantId: tenantId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let brands):
                self.dispatchQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.dismissIndicator()
                    self.delegate?.dismissErrorView()
                    self.delegate?.reloadBrands(brands: brands)
                }
            case .failure(let error):
                self.dispatchQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.dismissIndicator()
                    let message = self.errorTranslator.translate(error: error)
                    let buttonHidden: Bool = {
                        switch error {
                        case .systemError:
                            return false
                        default:
                            return true
                        }
                    }()
                    self.delegate?.showErrorView(message: message, buttonHidden: buttonHidden)
                }
            }
        }
    }

    func completeTokenTds() {
        let tokenCompletion: (Result<Token, APIError>) -> Void = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                self.creatingTokenCompleted(token: token)
            case .failure(let error):
                self.showErrorAlert(message: self.errorTranslator.translate(error: error))
            }
        }
        if let incompletedToken = incompletedToken {
            tokenService.finishTokenThreeDSecure(tokenId: incompletedToken.identifer,
                                                 completion: tokenCompletion)
        }
    }

    func tokenOperationStatusDidUpdate(status: TokenOperationStatus) {
        self.tokenOperationStatus = status
        updateIndicatingUI()
    }

    private func creatingTokenCompleted(token: Token) {
        delegate?.didProduced(with: token) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showErrorAlert(message: error.localizedDescription)
            } else {
                self.dispatchQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.cardFormResultSuccess = true
                    self.tokenizeProgressing = false
                    self.updateIndicatingUI()
                    self.delegate?.didCompleteCardForm(with: .success)
                }
            }
        }
    }

    private func updateIndicatingUI() {
        if self.cardFormResultSuccess || self.tokenizeProgressing || self.tokenOperationStatus != .acceptable {
            delegate?.showIndicator()
            delegate?.disableSubmitButton()
        } else {
            delegate?.dismissIndicator()
            delegate?.enableSubmitButton()
        }
    }

    private func showErrorAlert(message: String) {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.tokenizeProgressing = false
            self.updateIndicatingUI()
            self.delegate?.showErrorAlert(message: message)
        }
    }
}
