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

  if (indexPath.row == 3) {
    // customize card form
    //        UIColor *color = RGB(0, 122, 255);
    //        PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:color
    //                                                                    inputTextColor:color
    //                                                                    errorTextColor:nil
    //                                                                         tintColor:color
    //                                                         inputFieldBackgroundColor:nil
    //                                                                 submitButtonColor:color];
    // push
    PAYCardFormViewController *cardFormVc = [PAYCardFormViewController
        createCardFormViewControllerWithStyle:PAYCardFormStyle.defaultStyle
                                     tenantId:nil
                                     delegate:self
                                     viewType:CardFormViewTypeLabelStyled];
    [self.navigationController pushViewController:cardFormVc animated:YES];

    // modal
    //                PAYCardFormViewController *cardFormVc =
    //                    [PAYCardFormViewController
    //                    createCardFormViewControllerWithStyle:PAYCardFormStyle.defaultStyle
    //                                                                            tenantId:nil
    //                                                                            delegate:self];
    //                UINavigationController *naviVc =
    //                    [UINavigationController.new initWithRootViewController:cardFormVc];
    //                naviVc.presentationController.delegate = cardFormVc;
    //                [self presentViewController:naviVc animated:true completion:nil];
  }

  if (indexPath.row == 4) {
    PAYCardFormViewController *cardFormVc = [PAYCardFormViewController
        createCardFormViewControllerWithStyle:PAYCardFormStyle.defaultStyle
                                     tenantId:nil
                                     viewType:CardFormViewTypeCardDisplay];
    cardFormVc.delegate = self;
    [self.navigationController pushViewController:cardFormVc animated:YES];
  }
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
          [wself showToken:wself.token];
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
