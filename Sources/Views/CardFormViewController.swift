//
//  CardFormViewController.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/11/15.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation
import SafariServices

/// View type of CardFormView.
@objc public enum CardFormViewType: Int {
    /// CardFormTableStyledView.
    case tableStyled = 0
    /// CardFormLabelStyledView.
    case labelStyled = 1
    /// CardFormDisplayStyledView.
    case displayStyled = 2

    func createView(frame: CGRect) -> CardFormView & CardFormStylable {
        switch self {
        case .tableStyled:
            return CardFormTableStyledView(frame: frame)
        case .labelStyled:
            return CardFormLabelStyledView(frame: frame)
        case .displayStyled:
            return CardFormDisplayStyledView(frame: frame)
        }
    }

    var name: String {
        switch self {
        case .tableStyled: return "tableStyled"
        case .labelStyled: return "labelStyled"
        case .displayStyled: return "cardDisplay"
        }
    }
}

/// CardFormViewController show card form.
@objcMembers @objc(PAYCardFormViewController)
public class CardFormViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var submitButton: ActionButton!
    @IBOutlet weak var brandsView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorView: ErrorView!
    @IBOutlet weak var brandsLayout: UIView!
    @IBOutlet weak var formContentView: UIView!

    private var formStyle: FormStyle?
    private var tenantId: String?
    private var useThreeDSecure: Bool = false
    private var cardFormViewType: CardFormViewType?
    private var accptedBrands: [CardBrand]?
    private var accessorySubmitButton: ActionButton!
    private var cardFormView: CardFormView!
    private var presenter: CardFormScreenPresenterType?
    private let errorTranslator = ErrorTranslator.shared
    private var extraAttributes: [ExtraAttribute] = [ExtraAttributeEmail(), ExtraAttributePhone()]

    /// CardFormViewController delegate.
    private weak var delegate: CardFormViewControllerDelegate?

    /// CardFormViewController factory method.
    ///
    /// - Parameters:
    ///   - style: formStyle
    ///   - tenantId: identifier of tenant
    ///   - delegate: delegate of CardFormViewControllerDelegate
    ///   - viewType: card form type
    ///   - extraAttributes: extra attributes for 3-D Secure
    ///   - useThreeDSecure: whether use 3-D secure or not
    /// - Returns: CardFormViewController
    @objc(createCardFormViewControllerWithStyle: tenantId: delegate: viewType: extraAttributes:useThreeDSecure:)
    public static func createCardFormViewController(
        style: FormStyle = .defaultStyle,
        tenantId: String? = nil,
        delegate: CardFormViewControllerDelegate,
        viewType: CardFormViewType = .labelStyled,
        extraAttributes: [ExtraAttribute] = [ExtraAttributeEmail(), ExtraAttributePhone()],
        useThreeDSecure: Bool = false
    ) -> CardFormViewController {

        let stotyboard = UIStoryboard(name: "CardForm", bundle: .payjpBundle)
        let naviVc = stotyboard.instantiateInitialViewController() as? UINavigationController
        guard
            let cardFormVc = naviVc?.topViewController as? CardFormViewController
        else { fatalError("Couldn't instantiate CardFormViewController") }
        cardFormVc.formStyle = style
        cardFormVc.tenantId = tenantId
        cardFormVc.delegate = delegate
        cardFormVc.cardFormViewType = viewType
        cardFormVc.extraAttributes = extraAttributes
        cardFormVc.useThreeDSecure = useThreeDSecure
        return cardFormVc
    }

    @IBAction func registerCardTapped(_ sender: Any) {
        createToken()
    }

    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.didCompleteCardForm(with: .cancel)
        }
    }

    // MARK: Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        presenter = CardFormScreenPresenter(delegate: self)

        setupCardFormView()

        brandsView.delegate = self
        brandsView.dataSource = self
        errorView.delegate = self

        // if not modal, hide cancel button
        if !isModal {
            navigationItem.leftBarButtonItem = nil
        }

        navigationItem.title = "payjp_card_form_screen_title".localized
        submitButton.setTitle("payjp_card_form_screen_submit_button".localized, for: .normal)

        brandsView.register(UINib(nibName: "BrandImageCell", bundle: .payjpBundle),
                            forCellWithReuseIdentifier: "BrandCell")
        brandsView.backgroundColor = Style.Color.groupedBackground

        setupKeyboardNotification()
        setupKeyboardDismiss()
        fetchAccpetedBrands()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleTokenOperationStatusChange),
                                               name: .payjpTokenOperationStatusChanged,
                                               object: nil)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PAYJPSDK.clientInfo.cardFormType = self.cardFormViewType?.name
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PAYJPSDK.clientInfo.cardFormType = nil
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent && presenter?.cardFormResultSuccess == false {
            didCompleteCardForm(with: .cancel)
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        brandsView.collectionViewLayout.invalidateLayout()
    }

    // MARK: Selector

    @objc private func submitTapped(sender: UIButton) {
        self.view.endEditing(true)
        createToken()
    }

    @objc private func handleKeyboardShow(notification: Notification) {
        submitButton.isHidden = true
    }

    @objc private func handleKeyboardHide(notification: Notification) {
        submitButton.isHidden = false
    }

    @objc private func keyboardWillChangeFrame(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)

        let viewBottom = view.bounds.height
        let keyboardY = max(0, viewBottom - keyboardFrameInView.origin.y)

        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardY
        scrollView.contentInset = contentInset

        scrollView.showsVerticalScrollIndicator = false
        var scrollIndicatorInsets = scrollView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = keyboardY
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets
        scrollView.showsVerticalScrollIndicator = true

        // アクティブなテキストフィールドに自動スクロール
        guard keyboardY > 0, let activeField = findFirstResponder(in: scrollView) else { return }

        // displayStyledは内部に横スクロールを持つため、別処理
        if cardFormViewType == .displayStyled {
            scrollToVisibleForDisplayStyled(activeField: activeField, keyboardHeight: keyboardY)
        } else {
            scrollToVisibleTextField(activeField, keyboardHeight: keyboardY)
        }
    }

    @objc private func handleTokenOperationStatusChange(notification: Notification) {
        if let value = notification.userInfo?[PAYNotificationKey.newTokenOperationStatus] as? Int,
           let newStatus = TokenOperationStatus.init(rawValue: value) {
            self.presenter?.tokenOperationStatusDidUpdate(status: newStatus)
        }
    }

    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        for subview in view.subviews {
            if let firstResponder = findFirstResponder(in: subview) {
                return firstResponder
            }
        }
        return nil
    }

    private func scrollToVisibleTextField(_ textField: UIView, keyboardHeight: CGFloat) {
        let textFieldFrame = scrollView.convert(textField.bounds, from: textField)
        let visibleHeight = scrollView.bounds.height - keyboardHeight

        let padding: CGFloat = 20
        let maxY = textFieldFrame.maxY + padding

        // キーボードで隠れていない場合はスクロールしない
        guard maxY > scrollView.contentOffset.y + visibleHeight else { return }

        let targetY = textFieldFrame.origin.y - padding
        let newOffsetY = max(0, min(targetY, scrollView.contentSize.height - visibleHeight))
        scrollView.setContentOffset(CGPoint(x: 0, y: newOffsetY), animated: true)
    }

    /// displayStyled専用: 内部に横スクロールがあるため、cardFormViewを基準にスクロール
    private func scrollToVisibleForDisplayStyled(activeField: UIView, keyboardHeight: CGFloat) {
        let visibleHeight = scrollView.bounds.height - keyboardHeight
        let padding: CGFloat = 20

        // activeFieldの実際の位置で判定（view座標系で取得してscrollViewに変換）
        let activeFieldFrameInView = activeField.convert(activeField.bounds, to: view)
        let keyboardTop = view.bounds.height - keyboardHeight

        // キーボードで隠れていない場合はスクロールしない
        guard activeFieldFrameInView.maxY + padding > keyboardTop else { return }

        // スクロール先はcardFormViewを基準に計算（横スクロールの影響を避ける）
        let cardFormFrame = scrollView.convert(cardFormView.bounds, from: cardFormView)
        let relativeY = cardFormView.convert(activeField.bounds, from: activeField).origin.y
        let activeFieldBottomY = cardFormFrame.origin.y + relativeY + activeField.bounds.height + padding

        let targetY = activeFieldBottomY - visibleHeight
        let newOffsetY = max(0, min(targetY, scrollView.contentSize.height - visibleHeight))
        scrollView.setContentOffset(CGPoint(x: 0, y: newOffsetY), animated: true)
    }

    // MARK: Private

    private func setupKeyboardNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }

    private func setupKeyboardDismiss() {
        scrollView.keyboardDismissMode = .onDrag

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func createToken() {
        cardFormView.cardFormInput { result in
            switch result {
            case .success(let formInput):
                presenter?.createToken(tenantId: tenantId, useThreeDSecure: useThreeDSecure, formInput: formInput)
            case .failure(let error):
                showError(message: error.localizedDescription)
            }
        }
    }

    private func fetchAccpetedBrands() {
        presenter?.fetchBrands(tenantId: tenantId)
    }

    private func setupCardFormView() {
        // show submit button on top of keyboard
        let buttonFrame = CGRect.init(x: 0,
                                      y: 0,
                                      width: (UIScreen.main.bounds.size.width),
                                      height: 44)
        let buttonView = UIView(frame: buttonFrame)
        accessorySubmitButton = ActionButton(frame: buttonFrame)
        accessorySubmitButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        accessorySubmitButton.setTitle("payjp_card_form_screen_submit_button".localized, for: .normal)
        accessorySubmitButton.addTarget(self,
                                        action: #selector(submitTapped(sender:)),
                                        for: .touchUpInside)
        accessorySubmitButton.isEnabled = false
        accessorySubmitButton.cornerRadius = Style.Radius.none
        buttonView.addSubview(accessorySubmitButton)

        let x = self.formContentView.bounds.origin.x
        let y = self.formContentView.bounds.origin.y
        let width  = self.formContentView.bounds.width
        let height = self.formContentView.bounds.height
        let viewFrame = CGRect(x: x, y: y, width: width, height: height)

        initCardFormView(viewFrame: viewFrame, accessoryView: buttonView)
    }

    /// タイプ別で判定してCardFormViewを生成する
    private func initCardFormView(viewFrame: CGRect, accessoryView: UIView) {

        if let cardFormView = cardFormViewType?.createView(frame: viewFrame) {
            cardFormView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cardFormView.delegate = self
            cardFormView.setupInputAccessoryView(view: accessoryView)
            cardFormView.apply(extraAttributes: extraAttributes)
            if let formStyle = formStyle {
                cardFormView.apply(style: formStyle)
                submitButton.normalBackgroundColor = formStyle.submitButtonColor
                accessorySubmitButton.normalBackgroundColor = formStyle.submitButtonColor
            }
            self.formContentView.addSubview(cardFormView)
            self.cardFormView = cardFormView
        }
    }
}

// MARK: CardFormScreenDelegate
extension CardFormViewController: CardFormScreenDelegate {

    func reloadBrands(brands: [CardBrand]) {
        accptedBrands = brands
        cardFormView.setAcceptedBrands(brands)
        brandsView.reloadData()
    }

    func showIndicator() {
        activityIndicator.startAnimating()
    }

    func dismissIndicator() {
        activityIndicator.stopAnimating()
    }

    func enableSubmitButton() {
        submitButton.isEnabled = true
    }

    func disableSubmitButton() {
        submitButton.isEnabled = false
    }

    func showErrorView(message: String, buttonHidden: Bool) {
        errorView.show(message: message, reloadButtonHidden: buttonHidden)
    }

    func dismissErrorView() {
        errorView.dismiss()
    }

    func showErrorAlert(message: String) {
        showError(message: message)
    }

    func presentVerificationScreen(token: Token) {
        ThreeDSecureProcessHandler.shared.startThreeDSecureProcess(viewController: self,
                                                                   delegate: self,
                                                                   resourceId: token.identifer)
    }

    func didCompleteCardForm(with result: CardFormResult) {
        delegate?.cardFormViewController(self, didCompleteWith: result)
    }

    func didProduced(with token: Token, completionHandler: @escaping (Error?) -> Void) {
        delegate?.cardFormViewController(self, didProduced: token, completionHandler: completionHandler)
    }
}

// MARK: CardFormViewDelegate
extension CardFormViewController: CardFormViewDelegate {

    public func formInputValidated(in cardFormView: UIView, isValid: Bool) {
        submitButton.isEnabled = isValid
        accessorySubmitButton.isEnabled = isValid
    }

    public func formInputDoneTapped(in cardFormView: UIView) {
        createToken()
    }
}

// MARK: UICollectionViewDataSource
extension CardFormViewController: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return accptedBrands?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BrandCell", for: indexPath)

        if let cell = cell as? BrandImageCell {
            if let brand = accptedBrands?[indexPath.row] {
                cell.setup(brand: brand)
            }
        }

        return cell
    }
}

// MARK: ErrorViewDelegate
extension CardFormViewController: ErrorViewDelegate {
    func reload() {
        fetchAccpetedBrands()
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension CardFormViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            let cellWidth = Int(flowLayout.itemSize.width)
            let cellSpacing = Int(flowLayout.minimumInteritemSpacing)
            let cellCount = accptedBrands?.count ?? 0

            let totalCellWidth = cellWidth * cellCount
            let totalSpacingWidth = cellSpacing * (cellCount - 1)

            let inset = (collectionView.bounds.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2

            return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        }
        return .zero
    }
}

// MARK: UIAdaptivePresentationControllerDelegate
extension CardFormViewController: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didCompleteCardForm(with: .cancel)
    }
}

// MARK: ThreeDSecureProcessHandlerDelegate
extension CardFormViewController: ThreeDSecureProcessHandlerDelegate {

    public func threeDSecureProcessHandlerDidFinish(_ handler: ThreeDSecureProcessHandler,
                                                    status: ThreeDSecureProcessStatus) {
        switch status {
        case .completed:
            presenter?.completeTokenTds()
        case .canceled:
            dismissIndicator()
            enableSubmitButton()
        default:
            break
        }
    }
}

// MARK: UIGestureRecognizerDelegate
extension CardFormViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let v = view {
            if v is UITextField {
                return false
            }
            view = v.superview
        }
        return true
    }
}
