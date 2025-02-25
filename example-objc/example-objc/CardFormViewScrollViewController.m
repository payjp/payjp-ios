//
//  CardFormViewScrollViewController.m
//  example-objc
//
//  Created by Tadashi Wakayanagi on 2019/08/28.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

#import "CardFormViewScrollViewController.h"
#import "ColorTheme.h"
#import "UIViewController+Alert.h"
@import PAYJP;

@interface CardFormViewScrollViewController ()

@property(weak, nonatomic) IBOutlet PAYCardFormLabelStyledView *cardFormView;
@property(weak, nonatomic) IBOutlet UIButton *createTokenButton;
@property(weak, nonatomic) IBOutlet UIButton *validateAndCreateTokenButton;
@property(weak, nonatomic) IBOutlet UITextField *selectColorField;
@property(weak, nonatomic) IBOutlet UILabel *tokenIdLabel;

- (IBAction)createToken:(id)sender;
- (IBAction)validateAndCreateToken:(id)sender;

@property(strong, nonatomic) NSArray *list;
@property(strong, nonatomic) UIPickerView *pickerView;
@property(assign, nonatomic) PAYTokenOperationStatus tokenOperationStatus;
@property(nonatomic, strong) PAYToken *pendingToken;

@end

@implementation CardFormViewScrollViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.cardFormView.delegate = self;
  [self fetchBrands];

  self.list = @[ @"Normal", @"Red", @"Blue", @"Dark" ];
  self.pickerView = [[UIPickerView alloc] init];
  self.pickerView.delegate = self;
  self.pickerView.dataSource = self;
  self.pickerView.showsSelectionIndicator = YES;
  self.selectColorField.delegate = self;

  UIToolbar *toolbar = [[UIToolbar alloc] init];
  UIBarButtonItem *spaceItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                    target:self
                                                    action:nil];
  UIBarButtonItem *doneItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                    target:self
                                                    action:@selector(colorSelected:)];
  [toolbar setItems:@[ spaceItem, doneItem ]];
  [toolbar sizeToFit];

  self.selectColorField.inputView = self.pickerView;
  self.selectColorField.inputAccessoryView = toolbar;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleTokenOperationStatusChange:)
                                               name:NSNotification.payjpTokenOperationStatusChanged
                                             object:nil];
}

- (void)colorSelected:(id)sender {
  [self.selectColorField endEditing:YES];
  NSString *selected = self.list[[self.pickerView selectedRowInComponent:0]];
  self.selectColorField.text = selected;
  ColorTheme theme = GetColorTheme(selected);

  switch (theme) {
    case Red: {
      UIColor *red = RGB(255, 69, 0);
      PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:red
                                                                  inputTextColor:red
                                                                  errorTextColor:nil
                                                                       tintColor:red
                                                       inputFieldBackgroundColor:nil
                                                               submitButtonColor:nil
                                                                  highlightColor:nil];
      [self.cardFormView applyWithStyle:style];
      self.cardFormView.backgroundColor = UIColor.clearColor;
      break;
    }
    case Blue: {
      UIColor *blue = RGB(0, 103, 187);
      PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:blue
                                                                  inputTextColor:blue
                                                                  errorTextColor:nil
                                                                       tintColor:blue
                                                       inputFieldBackgroundColor:nil
                                                               submitButtonColor:nil
                                                                  highlightColor:nil];
      [self.cardFormView applyWithStyle:style];
      self.cardFormView.backgroundColor = UIColor.clearColor;
      break;
    }
    case Dark: {
      UIColor *white = UIColor.whiteColor;
      UIColor *darkGray = RGB(61, 61, 61);
      UIColor *lightGray = RGB(80, 80, 80);
      PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:white
                                                                  inputTextColor:white
                                                                  errorTextColor:nil
                                                                       tintColor:white
                                                       inputFieldBackgroundColor:lightGray
                                                               submitButtonColor:nil
                                                                  highlightColor:nil];
      [self.cardFormView applyWithStyle:style];
      self.cardFormView.backgroundColor = darkGray;
      break;
    }
    default: {
      UIColor *black = UIColor.blackColor;
      UIColor *defaultBlue = RGB(0, 122, 255);
      PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:black
                                                                  inputTextColor:black
                                                                  errorTextColor:nil
                                                                       tintColor:defaultBlue
                                                       inputFieldBackgroundColor:nil
                                                               submitButtonColor:nil
                                                                  highlightColor:nil];
      [self.cardFormView applyWithStyle:style];
      self.cardFormView.backgroundColor = UIColor.clearColor;
      break;
    }
  }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return self.list.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  return self.list[row];
}

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string {
  return NO;
}

- (void)formInputValidatedIn:(UIView *)cardFormView isValid:(BOOL)isValid {
  [self updateButtonEnabled];
}

- (void)formInputDoneTappedIn:(UIView *)cardFormView {
  [self createToken];
}

- (void)handleTokenOperationStatusChange:(NSNotification *)notification {
  self.tokenOperationStatus =
      [notification.userInfo[PAYNotificationKey.newTokenOperationStatus] integerValue];
  [self updateButtonEnabled];
}

- (void)updateButtonEnabled {
  BOOL isAcceptable = self.tokenOperationStatus == PAYTokenOperationStatusAcceptable;
  self.createTokenButton.enabled = self.cardFormView.isValid && isAcceptable;
  self.validateAndCreateTokenButton.enabled = isAcceptable;
}

- (IBAction)createToken:(id)sender {
  if (!self.cardFormView.isValid) {
    return;
  }
  [self createToken];
}

- (IBAction)validateAndCreateToken:(id)sender {
  BOOL isValid = [self.cardFormView validateCardForm];
  if (isValid) {
    [self createToken];
  }
}

- (void)createToken {
  __weak typeof(self) wself = self;

  [self.cardFormView
      createTokenWith:nil
      useThreeDSecure:YES
           completion:^(PAYToken *token, NSError *error) {
             if (error.domain == PAYErrorDomain && error.code == PAYErrorServiceError) {
               id<PAYErrorResponseType> errorResponse = error.userInfo[PAYErrorServiceErrorObject];
               NSLog(@"[errorResponse] %@", errorResponse.description);
             }

             if (!token) {
               dispatch_async(dispatch_get_main_queue(), ^{
                 wself.tokenIdLabel.text = nil;
                 [wself showError:error];
               });
               return;
             }

             NSLog(@"token = %@", [wself displayToken:token]);
             dispatch_async(dispatch_get_main_queue(), ^{
               if (token.card.threeDSecureStatus == PAYThreeDSecureStatusUnverified) {
                 wself.pendingToken = token;
                 [[PAYJPThreeDSecureProcessHandler sharedHandler]
                     startThreeDSecureProcessWithViewController:wself
                                                       delegate:wself
                                                     resourceId:token.identifer];
                 return;
               }
               wself.tokenIdLabel.text = token.identifer;
               [wself showToken:token];
             });
           }];
}

- (void)fetchBrands {
  __weak typeof(self) wself = self;

  [self.cardFormView
      fetchBrandsWith:@"tenant_id"
           completion:^(NSArray<NSString *> *cardBrands, NSError *error) {
             if (error.domain == PAYErrorDomain && error.code == PAYErrorServiceError) {
               id<PAYErrorResponseType> errorResponse = error.userInfo[PAYErrorServiceErrorObject];
               NSLog(@"[errorResponse] %@", errorResponse.description);
             }

             if (!cardBrands) {
               dispatch_async(dispatch_get_main_queue(), ^{
                 [wself showError:error];
               });
             }
           }];
}

- (void)completeTokenTds {
  if (!self.pendingToken) {
    return;
  }

  __weak typeof(self) wself = self;
  [[PAYAPIClient sharedClient]
      finishTokenThreeDSecureWith:self.pendingToken.identifer
                completionHandler:^(PAYToken *token, NSError *error) {
                  if (error) {
                    if ([error.domain isEqualToString:PAYErrorDomain]) {
                      id<PAYErrorResponseType> errorResponse =
                          error.userInfo[PAYErrorServiceErrorObject];
                      NSLog(@"[errorResponse] %@", errorResponse.description);
                    }

                    dispatch_async(dispatch_get_main_queue(), ^{
                      wself.tokenIdLabel.text = nil;
                      [wself showError:error];
                    });
                    return;
                  }

                  dispatch_async(dispatch_get_main_queue(), ^{
                    wself.pendingToken = nil;
                    wself.tokenIdLabel.text = token.identifer;
                    [wself showToken:token];
                  });
                }];
}

#pragma mark - PAYThreeDSecureProcessHandlerDelegate

- (void)threeDSecureProcessHandlerDidFinish:(PAYJPThreeDSecureProcessHandler *)handler
                                     status:(enum ThreeDSecureProcessStatus)status {
  switch (status) {
    case ThreeDSecureProcessStatusCompleted:
      [self completeTokenTds];
      break;
    case ThreeDSecureProcessStatusCanceled:
      // UI更新など
      break;
    default:
      break;
  }
}

@end
