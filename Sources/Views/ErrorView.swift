//
//  ErrorView.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/11/28.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import UIKit

protocol ErrorViewDelegate: AnyObject {
    func reload()
}

class ErrorView: UIView {

    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var reloadButton: UIButton!

    @IBAction func reloadTapped(_ sender: Any) {
        delegate?.reload()
    }

    private var contentView: UIView!
    weak var delegate: ErrorViewDelegate?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        let nib = UINib(nibName: "ErrorView", bundle: .payjpBundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView

        if let view = view {
            contentView = view
            view.frame = bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(view)
        }
    }

    override public var intrinsicContentSize: CGSize {
        return contentView.intrinsicContentSize
    }

    func show(message: String, reloadButtonHidden: Bool) {
        self.isHidden = false
        errorMessageLabel.text = message
        reloadButton.isHidden = reloadButtonHidden
    }

    func dismiss() {
        self.isHidden = true
    }
}
