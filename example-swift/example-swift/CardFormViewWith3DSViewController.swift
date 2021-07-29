//
//  CardFormViewWith3DSViewController.swift
//  example-swift
//
//  Created by Tatsuya Kitagawa on 2021/07/28.
//

import UIKit
import PAYJP

class CardFormViewWith3DSViewController: UIViewController {

    @IBOutlet private weak var formContentView: UIView!
    @IBOutlet private weak var createTokenButton: UIButton!
    @IBOutlet private weak var tokenIdLabel: UILabel!

    private var cardFormView: CardFormLabelStyledView!
    private var tokenOperationStatus: TokenOperationStatus = .acceptable
    private var pendingToken: Token?

    override func viewDidLoad() {
        let x: CGFloat = self.formContentView.bounds.origin.x
        let y: CGFloat = self.formContentView.bounds.origin.y

        let width: CGFloat = self.formContentView.bounds.width
        let height: CGFloat = self.formContentView.bounds.height

        let frame: CGRect = CGRect(x: x, y: y, width: width, height: height)
        cardFormView = CardFormLabelStyledView(frame: frame)
        cardFormView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cardFormView.setCardHolderRequired(true)
        cardFormView.delegate = self

        self.formContentView.addSubview(cardFormView)

        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleTokenOperationStatusChange(notification:)),
                                            name: .payjpTokenOperationStatusChanged,
                                            object: nil)
        
    }

    @objc private func handleTokenOperationStatusChange(notification: Notification) {
        if let value = notification.userInfo?[PAYNotificationKey.newTokenOperationStatus] as? Int,
        let newStatus = TokenOperationStatus.init(rawValue: value) {
            self.tokenOperationStatus = newStatus
            self.updateButtonEnabled()
        }
    }

    private func updateButtonEnabled() {
        let isAcceptable = self.tokenOperationStatus == .acceptable
        self.createTokenButton.isEnabled = isAcceptable && self.cardFormView.isValid
    }

    @IBAction func createToken(_ sender: Any) {
        if !self.cardFormView.isValid {
            return
        }
        createToken()
    }

    func createToken() {
        self.cardFormView.createToken { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                DispatchQueue.main.async {
                    if let tdsStatus = token.card.threeDSecureStatus, tdsStatus == .unverified {
                            self.pendingToken = token
                            ThreeDSecureProcessHandler.shared.startThreeDSecureProcess(viewController: self, delegate: self, token: token)
                        return
                    }
                    self.tokenIdLabel.text = token.identifer
                    self.showToken(token: token)
                }
            case .failure(let error):
                if let apiError = error as? APIError, let payError =
                    apiError.payError {
                    print("[errorResponse] \(payError.description)")
                }

                DispatchQueue.main.async {
                    self.tokenIdLabel.text = nil
                    self.showError(error: error)
                }
            }
        }
    }

    func completeTokenTds() {
        guard let pendingToken = pendingToken else {
            return
        }
        APIClient.shared.finishTokenThreeDSecure(with: pendingToken.identifer) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                self.pendingToken = nil
                DispatchQueue.main.async {
                    self.tokenIdLabel.text = token.identifer
                    self.showToken(token: token)
                }
            case .failure(let error):
                if let payError = error.payError {
                    print("[errorResponse] \(payError.description)")
                }

                DispatchQueue.main.async {
                    self.tokenIdLabel.text = nil
                    self.showError(error: error)
                }
            }
        }
    }
 }

// MARK: - CardFormViewDelegate

extension CardFormViewWith3DSViewController: CardFormViewDelegate {
    func formInputValidated(in cardFormView: UIView, isValid: Bool) {
        self.updateButtonEnabled()
    }

    func formInputDoneTapped(in cardFormView: UIView) {
        self.createToken()
    }
}

// MARK: - ThreeDSecureProcessHandlerDelegate

extension CardFormViewWith3DSViewController: ThreeDSecureProcessHandlerDelegate {
    func threeDSecureProcessHandlerDidFinish(_ handler: ThreeDSecureProcessHandler, status: ThreeDSecureProcessStatus) {
        switch status {
        case .completed:
            // 3DSの処理を完了する
            completeTokenTds()
        case .canceled:
            // UI更新など
            break
        default:
            break
        }
    }
}

