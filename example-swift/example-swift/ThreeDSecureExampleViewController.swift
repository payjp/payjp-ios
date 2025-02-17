//
//  ThreeDSecureExampleViewController.swift
//  example-swift
//

import UIKit
import PAYJP

class ThreeDSecureExampleViewController: UIViewController {
    @IBOutlet private var startButton: UIButton!
    
    @IBOutlet private var textField: UITextField!
    
    @IBOutlet private var resultLabel: UILabel!
    
    private var pendingResourceId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction private func startThreeDSecure(_ sender: Any) {
        guard let resourceId = textField.text, !resourceId.isEmpty else {
            self.resultLabel.text = ""
            self.resultLabel.isHidden = true
            return
        }
        
        pendingResourceId = resourceId
        ThreeDSecureProcessHandler.shared.startThreeDSecureProcess(viewController: self, delegate: self, resourceId: resourceId)
    }
}

// MARK: - ThreeDSecureProcessHandlerDelegate

extension ThreeDSecureExampleViewController: ThreeDSecureProcessHandlerDelegate {
    func threeDSecureProcessHandlerDidFinish(_ handler: ThreeDSecureProcessHandler, status: ThreeDSecureProcessStatus) {
        switch status {
        case .completed:
            DispatchQueue.main.async {
                self.resultLabel.text = "3Dセキュア認証が終了しました。\nこの結果をサーバーサイドに伝え、完了処理や結果のハンドリングを行なってください。\n後続処理の実装方法に関してはドキュメントをご参照ください。"
                self.resultLabel.textColor = .black
                self.resultLabel.isHidden = false
            }
        case .canceled:
            DispatchQueue.main.async {
                self.resultLabel.text = "3Dセキュア認証がキャンセルされました。"
                self.resultLabel.textColor = .red
                self.resultLabel.isHidden = false
            }
        }
    }
}
