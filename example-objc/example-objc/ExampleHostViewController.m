//
//  ExampleHostViewController.m
//  example-objc
//
//  Created by Tadashi Wakayanagi on 2019/11/18.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

#import "ExampleHostViewController.h"
#import "ColorTheme.h"
#import "SampleService.h"
#import "UIViewController+Alert.h"
@import PAYJP;

@interface ExampleHostViewController ()

@property(nonatomic) PAYToken *token;

@end

@implementation ExampleHostViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:true];

  if (indexPath.section == 0) {
    if (indexPath.row == 0) {
      [self pushCardFormWithViewType:CardFormViewTypeTableStyled];
    }

    if (indexPath.row == 1) {
      // customize card form
      //        UIColor *color = RGB(0, 122, 255);
      //        PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:color
      //                                                                    inputTextColor:color
      //                                                                    errorTextColor:nil
      //                                                                         tintColor:color
      //                                                         inputFieldBackgroundColor:nil
      //                                                                 submitButtonColor:color
      //                                                                    highlightColor:nil];
      [self presentCardFormWithViewType:CardFormViewTypeLabelStyled];
    }

    if (indexPath.row == 2) {
      [self pushCardFormWithViewType:CardFormViewTypeDisplayStyled];
    }
  }
}

- (void)pushCardFormWithViewType:(CardFormViewType)viewType {
  PAYExtraAttributeEmail *email = [[PAYExtraAttributeEmail alloc] initWithPreset:nil];
  PAYExtraAttributePhone *phone = [[PAYExtraAttributePhone alloc] initWithPresetNumber:nil
                                                                          presetRegion:nil];
  PAYCardFormViewController *cardFormVc =
      [PAYCardFormViewController createCardFormViewControllerWithStyle:PAYCardFormStyle.defaultStyle
                                                              tenantId:nil
                                                              delegate:self
                                                              viewType:viewType
                                                       extraAttributes:@[ email, phone ]
                                                       useThreeDSecure:YES];
  [self.navigationController pushViewController:cardFormVc animated:YES];
}

- (void)presentCardFormWithViewType:(CardFormViewType)viewType {
  PAYExtraAttributeEmail *email = [[PAYExtraAttributeEmail alloc] initWithPreset:nil];
  PAYExtraAttributePhone *phone = [[PAYExtraAttributePhone alloc] initWithPresetNumber:nil
                                                                          presetRegion:nil];
  PAYCardFormViewController *cardFormVc =
      [PAYCardFormViewController createCardFormViewControllerWithStyle:PAYCardFormStyle.defaultStyle
                                                              tenantId:nil
                                                              delegate:self
                                                              viewType:viewType
                                                       extraAttributes:@[ email, phone ]
                                                       useThreeDSecure:YES];
  UINavigationController *naviVc =
      [UINavigationController.new initWithRootViewController:cardFormVc];
  naviVc.presentationController.delegate = cardFormVc;
  [self presentViewController:naviVc animated:true completion:nil];
}

#pragma MARK : PAYCardFormViewControllerDelegate

- (void)cardFormViewController:(PAYCardFormViewController *_Nonnull)_
               didCompleteWith:(enum CardFormResult)result {
  __weak typeof(self) wself = self;

  switch (result) {
    case CardFormResultCancel:
      NSLog(@"CardFormResultCancel");
      break;
    case CardFormResultSuccess:
      NSLog(@"CardFormResultSuccess");
      dispatch_async(dispatch_get_main_queue(), ^{
        // pop
        [wself.navigationController popViewControllerAnimated:YES];
        if (wself.token != nil) {
          [wself.navigationController
              dismissViewControllerAnimated:YES
                                 completion:^{
                                   [wself.navigationController showToken:wself.token];
                                 }];
        }

        // dismiss
        //                          [wself.navigationController dismissViewControllerAnimated:YES
        //                          completion:nil];
      });
      break;
  }
}

- (void)cardFormViewController:(PAYCardFormViewController *)_
                   didProduced:(PAYToken *)token
             completionHandler:(void (^)(NSError *_Nullable))completionHandler {
  NSLog(@"token = %@", [self displayToken:token]);
  self.token = token;

  // サーバにトークンを送信
  SampleService *service = [SampleService sharedService];
  [service saveCardWithToken:token.identifer
                  completion:^(NSError *error) {
                    if (error != nil) {
                      NSLog(@"Failed save card. error = %@", error);
                      completionHandler(error);
                    } else {
                      NSLog(@"Success save card.");
                      completionHandler(nil);
                    }
                  }];
}

@end
