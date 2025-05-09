//
//  ExampleHostViewController.swift
//  example-swift
//
//  Created by Tadashi Wakayanagi on 2019/11/19.
//

import UIKit
import PAYJP

class ExampleHostViewController: UITableViewController {

    private var token: Token?

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                presentTdsAttributeOptions(viewType: .tableStyled, pushNavigation: true)
            case 1:
                presentTdsAttributeOptions(viewType: .labelStyled, pushNavigation: false)
            case 2:
                presentTdsAttributeOptions(viewType: .displayStyled, pushNavigation: true)
            default:
                break
            }
        }
    }

    private func presentTdsAttributeOptions(viewType: CardFormViewType, pushNavigation: Bool) {
        func showCardForm(attributes: [ExtraAttribute]) {
            let cardForm = CardFormViewController.createCardFormViewController(delegate: self, viewType: viewType, extraAttributes: attributes, useThreeDSecure: true)
            if pushNavigation {
                self.navigationController?.pushViewController(cardForm, animated: true)
            } else {
                let naviVc = UINavigationController(rootViewController: cardForm)
                naviVc.presentationController?.delegate = cardForm
                self.present(naviVc, animated: true, completion: nil)
            }
        }
        let options: [(label: String, attributes: [ExtraAttribute])] = [
            ("email and phone", [ExtraAttributeEmail(), ExtraAttributePhone()]),
            ("email", [ExtraAttributeEmail()]),
            ("phone", [ExtraAttributePhone()]),
            ("email (preset)", [ExtraAttributeEmail(preset: "test@example.com")]),
            // You can pass preset phone number,
            // by either an international phone number format (e.g. `+819012345678`)
            // or a local number format (e.g. `09012345678`).
            ("phone (preset)", [ExtraAttributePhone(presetNumber: "+819012345678", presetRegion: "JP")]),
            ("none", [])
        ]
        let sheet = UIAlertController(title: "Select Extra Attributes", message: nil, preferredStyle: .actionSheet)
        options.forEach { (label, attrs) in
            let action = UIAlertAction(title: label, style: .default) { _ in
                showCardForm(attributes: attrs)
            }
            sheet.addAction(action)
        }
        sheet.addAction(.init(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}

extension ExampleHostViewController: CardFormViewControllerDelegate {

    func cardFormViewController(_: CardFormViewController, didCompleteWith result: CardFormResult) {
        switch result {
        case .cancel:
            print("CardFormResult.cancel")
        case .success:
            print("CardFormResult.success")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // pop
                self.navigationController?.popViewController(animated: true)
                if let token = self.token {
                    self.navigationController?.dismiss(animated: true, completion: { [weak self] in
                        self?.navigationController?.showToken(token: token)
                    })
                }

                // dismiss
                //                                self?.dismiss(animated: true, completion: nil)
            }
        }
    }

    func cardFormViewController(_: CardFormViewController,
                                didProduced token: Token,
                                completionHandler: @escaping (Error?) -> Void) {
        print("token = \(token.display)")
        self.token = token

        // サーバにトークンを送信
        SampleService.shared.saveCard(withToken: token.identifer) { (error) in
            if let error = error {
                print("Failed save card. error = \(error)")
                completionHandler(error)
            } else {
                print("Success save card.")
                completionHandler(nil)
            }
        }
    }
}
