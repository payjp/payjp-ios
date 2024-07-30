//
//  BrandImageCell.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/11/22.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import UIKit

class BrandImageCell: UICollectionViewCell {

    @IBOutlet weak var brandImage: UIImageView!

    func setup(brand: CardBrand) {
        brandImage.image = brand.logoImage
    }
}
