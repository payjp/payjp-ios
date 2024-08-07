//
//  CardFormViewExampleViewController.swift
//  example-swift
//
//  Created by Tadashi Wakayanagi on 2019/09/10.
//

import UIKit
import PAYJP

class CardFormVieExampleViewController: UITableViewController, CardFormViewDelegate,
                                        UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    @IBOutlet private weak var formContentView: UIView!
    @IBOutlet private weak var createTokenCell: UITableViewCell!
    @IBOutlet private weak var validateAndCreateTokenCell: UITableViewCell!
    @IBOutlet private weak var tokenIdLabel: UILabel!
    @IBOutlet private weak var selectColorField: UITextField!

    private var cardFormView: CardFormTableStyledView!
    private var tokenOperationStatus: TokenOperationStatus = .acceptable

    private let list: [ColorTheme] = [.Normal, .Red, .Blue, .Dark]
    private var pickerView: UIPickerView!

    override func viewDidLoad() {

        let x: CGFloat = self.formContentView.bounds.origin.x
        let y: CGFloat = self.formContentView.bounds.origin.y

        let width: CGFloat = self.formContentView.bounds.width
        let height: CGFloat = self.formContentView.bounds.height

        let frame: CGRect = CGRect(x: x, y: y, width: width, height: height)
        cardFormView = CardFormTableStyledView(frame: frame)
        cardFormView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cardFormView.delegate = self

        self.formContentView.addSubview(cardFormView)
        self.toggleCellStyle(cell: self.createTokenCell, isEnabled: false)

        self.pickerView = UIPickerView()
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        self.pickerView.showsSelectionIndicator = true
        self.selectColorField.delegate = self

        let toolbar = UIToolbar()
        let spaceItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
            target: nil,
            action: nil)
        let doneItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.done,
            target: self,
            action: #selector(colorSelected(_:)))
        toolbar.setItems([spaceItem, doneItem], animated: true)
        toolbar.sizeToFit()

        self.selectColorField.inputView = self.pickerView
        self.selectColorField.inputAccessoryView = toolbar

        self.fetchBrands()

        // processing to adjust the cell height of CardFormView when OS version is lower than 10
        self.tableView.layoutIfNeeded()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleTokenOperationStatusChange(notification:)),
                                               name: .payjpTokenOperationStatusChanged,
                                               object: nil)
    }

    @objc private func colorSelected(_ sender: UIButton) {
        self.selectColorField.endEditing(true)
        let theme = self.list[self.pickerView.selectedRow(inComponent: 0)]
        self.selectColorField.text = theme.rawValue

        switch theme {
        case .Red:
            let red = UIColor(255, 69, 0)
            let style = FormStyle(inputTextColor: red, tintColor: red)
            self.cardFormView.apply(style: style)
            self.cardFormView.backgroundColor = .clear
        case .Blue:
            let blue = UIColor(0, 103, 187)
            let style = FormStyle(inputTextColor: blue, tintColor: blue)
            self.cardFormView.apply(style: style)
            self.cardFormView.backgroundColor = .clear
        case .Dark:
            let darkGray = UIColor(61, 61, 61)
            let style = FormStyle(inputTextColor: .white, tintColor: .white)
            self.cardFormView.apply(style: style)
            self.cardFormView.backgroundColor = darkGray
        default:
            let defaultBlue = UIColor(0, 122, 255)
            let style = FormStyle(inputTextColor: .black, tintColor: defaultBlue)
            self.cardFormView.apply(style: style)
            self.cardFormView.backgroundColor = .clear
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionName: String?
        switch section {
        case 0:
            sectionName = NSLocalizedString("example_card_information_section", tableName: nil, comment: "")
        case 2:
            sectionName = NSLocalizedString("example_token_id_section", tableName: nil, comment: "")
        default:
            break
        }
        return sectionName
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Create Token
        if indexPath.section == 1 && indexPath.row == 1 {
            if !self.cardFormView.isValid {
                return
            }
            createToken()
        }
        // Valdate and Create Token
        if indexPath.section == 1 && indexPath.row == 2 {
            let isValid = self.cardFormView.validateCardForm()
            if isValid {
                createToken()
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.list.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.list[row].rawValue
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return false
    }

    func formInputValidated(in cardFormView: UIView, isValid: Bool) {
        updateButtonEnabled()
    }

    func formInputDoneTapped(in cardFormView: UIView) {
        self.createToken()
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
        self.toggleCellStyle(cell: self.createTokenCell, isEnabled: isAcceptable && self.cardFormView.isValid)
        self.toggleCellStyle(cell: self.validateAndCreateTokenCell, isEnabled: isAcceptable)
        let indexPathCreateToken = IndexPath(row: 1, section: 1)
        let indexPathValidateAndCreateToken = IndexPath(row: 2, section: 1)
        self.tableView.reloadRows(at: [indexPathCreateToken, indexPathValidateAndCreateToken],
                                  with: .none)
    }

    private func toggleCellStyle(cell: UITableViewCell, isEnabled: Bool) {
        cell.isUserInteractionEnabled = isEnabled
        cell.selectionStyle = isEnabled ? .default : .none
        cell.contentView.alpha = isEnabled ? 1.0 : 0.5
    }

    func createToken() {
        self.cardFormView.createToken(tenantId: "tenant_id") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                DispatchQueue.main.async {
                    self.tokenIdLabel.text = token.identifer
                    self.tableView.reloadData()
                    self.showToken(token: token)
                }
            case .failure(let error):
                if let apiError = error as? APIError, let payError = apiError.payError {
                    print("[errorResponse] \(payError.description)")
                }

                DispatchQueue.main.async {
                    self.tokenIdLabel.text = nil
                    self.showError(error: error)
                }
            }
        }
    }

    func fetchBrands() {
        self.cardFormView.fetchBrands(tenantId: "tenant_id") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let brands):
                print("card brands => \(brands)")
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
