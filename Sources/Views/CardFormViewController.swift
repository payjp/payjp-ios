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
    /// - Returns: CardFormViewController
    @objc(createCardFormViewControllerWithStyle: tenantId: delegate: viewType: extraAttributes:)
    public static func createCardFormViewController(
        style: FormStyle = .defaultStyle,
        tenantId: String? = nil,
        delegate: CardFormViewControllerDelegate,
        viewType: CardFormViewType = .labelStyled,
        extraAttributes: [ExtraAttribute] = [ExtraAttributeEmail(), ExtraAttributePhone()]
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

    @objc private func keyboardDidChangeFrame(notification: Notification) {
        let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        var keyboardY = scrollView.bounds.height - keyboardRect.origin.y
        if keyboardY < 0 {
            keyboardY = 0
        }

        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardY
        scrollView.contentInset = contentInset

        scrollView.showsVerticalScrollIndicator = false
        var scrollIndicatorInsets = scrollView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = keyboardY
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets
        scrollView.showsVerticalScrollIndicator = true

        // displayStyledのレイアウトで横ScrollViewを使用している影響で
        // 縦スクロールが効かないため、手動でスクロールさせるようにしている
        // 縦スクロールが発生する画面サイズ かつ displayStyled のときのみスクロールさせる
        let diff = scrollView.contentSize.height -
            scrollView.bounds.size.height +
            scrollView.contentInset.bottom
        if keyboardY > 0 && diff > 0 && cardFormViewType == .displayStyled {
            let offset = CGPoint(x: 0, y: diff)
            scrollView.setContentOffset(offset, animated: true)
        }
    }

    @objc private func handleTokenOperationStatusChange(notification: Notification) {
        if let value = notification.userInfo?[PAYNotificationKey.newTokenOperationStatus] as? Int,
           let newStatus = TokenOperationStatus.init(rawValue: value) {
            self.presenter?.tokenOperationStatusDidUpdate(status: newStatus)
        }
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
                                               selector: #selector(keyboardDidChangeFrame),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
    }

    private func createToken() {
        cardFormView.cardFormInput { result in
            switch result {
            case .success(let formInput):
                presenter?.createToken(tenantId: tenantId, formInput: formInput)
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
                                                                   token: token)
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
