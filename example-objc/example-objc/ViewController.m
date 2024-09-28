//
//  ViewController.m
//  example-objc
//
//  Created by Tatsuya Kitagawa on 2017/12/08.
//  Copyright © 2017年 PAY, Inc. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+Alert.h"
@import PAYJP;

@interface ViewController ()

@property(nonatomic, weak) IBOutlet UITextField *fieldCardNumber;
@property(nonatomic, weak) IBOutlet UITextField *fieldCardCvc;
@property(nonatomic, weak) IBOutlet UITextField *fieldCardMonth;
@property(nonatomic, weak) IBOutlet UITextField *fieldCardYear;
@property(nonatomic, weak) IBOutlet UITextField *fieldCardName;
@property(nonatomic, weak) IBOutlet UILabel *labelTokenId;

@property(nonatomic, strong) PAYAPIClient *payjpClient;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.payjpClient = PAYAPIClient.sharedClient;
}

#pragma MARK : -UITableView

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 1) {
    [self createToken];
    [tableView deselectRowAtIndexPath:indexPath animated:true];
  } else if (indexPath.section == 2) {
    [self getToken];
    [tableView deselectRowAtIndexPath:indexPath animated:true];
  }
}

#pragma MARK : -fetch

- (void)createToken {
  NSString *number = self.fieldCardNumber.text;
  NSString *cvc = self.fieldCardCvc.text;
  NSString *month = self.fieldCardMonth.text;
  NSString *year = self.fieldCardYear.text;
  NSString *name = self.fieldCardName.text;
  NSLog(@"input number=%@, cvc=%@, month=%@, year=%@ name=%@", number, cvc, month, year, name);
  __weak typeof(self) wself = self;
  [self.payjpClient createTokenWith:number
                                cvc:cvc
                    expirationMonth:month
                     expirationYear:year
                               name:name
                           tenantId:nil
                              email:nil
                              phone:nil
                    useThreeDSecure:NO
                  completionHandler:^(PAYToken *token, NSError *error) {
                    if (error.domain == PAYErrorDomain && error.code == PAYErrorServiceError) {
                      id<PAYErrorResponseType> errorResponse =
                          error.userInfo[PAYErrorServiceErrorObject];
                      NSLog(@"[errorResponse] %@", errorResponse.description);
                    }

                    if (!token) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                        wself.labelTokenId.text = nil;
                        [wself showError:error];
                      });
                      return;
                    }

                    NSLog(@"token = %@", [wself displayToken:token]);
                    dispatch_async(dispatch_get_main_queue(), ^{
                      wself.labelTokenId.text = token.identifer;
                      [wself.tableView reloadData];
                      [wself showToken:token];
                    });
                  }];
}

- (void)getToken {
  NSString *tokenId = self.labelTokenId.text;
  NSLog(@"tokenId=%@", tokenId);
  __weak typeof(self) wself = self;
  [self.payjpClient getTokenWith:tokenId
               completionHandler:^(PAYToken *token, NSError *error) {
                 if (!token) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                     wself.labelTokenId.text = nil;
                     [wself showError:error];
                   });
                   return;
                 }

                 NSLog(@"token = %@", [wself displayToken:token]);
                 dispatch_async(dispatch_get_main_queue(), ^{
                   wself.labelTokenId.text = token.identifer;
                   [wself.tableView reloadData];
                   [wself showToken:token];
                 });
               }];
}

@end
