//
//  CardFormViewScrollViewConstroller.h
//  example-objc
//
//  Created by Tadashi Wakayanagi on 2019/08/28.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@import PAYJP;

NS_ASSUME_NONNULL_BEGIN

@interface CardFormViewScrollViewController
    : UIViewController <PAYCardFormViewDelegate,
                        PAYJPThreeDSecureProcessHandlerDelegate,
                        UIPickerViewDelegate,
                        UIPickerViewDataSource,
                        UITextFieldDelegate>

@end

NS_ASSUME_NONNULL_END
