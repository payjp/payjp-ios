//
//  CardFormViewExampleViewController.m
//  example-objc
//
//  Created by Li-Hsuan Chen on 2019/07/23.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

#import "CardFormViewExampleViewController.h"
#import "ColorTheme.h"
#import "UIViewController+Alert.h"
@import PAYJP;

@interface CardFormViewExampleViewController ()

@property(weak, nonatomic) IBOutlet PAYCardFormTableStyledView *cardFormView;
@property(weak, nonatomic) IBOutlet UILabel *tokenIdLabel;
@property(weak, nonatomic) IBOutlet UITableViewCell *createTokenCell;
@property(weak, nonatomic) IBOutlet UITableViewCell *validateAndCreateTokenCell;
@property(weak, nonatomic) IBOutlet UITextField *selectColorField;

@property(strong, nonatomic) PAYAPIClient *payjpClient;

@property(strong, nonatomic) NSArray *list;
@property(strong, nonatomic) UIPickerView *pickerView;
@property(assign, nonatomic) PAYTokenOperationStatus tokenOperationStatus;

@end

@implementation CardFormViewExampleViewController

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

  [self toggleCellStyle:self.createTokenCell isEnabled:NO];

  // processing to adjust the cell height of CardFormView when OS version is lower than 10
  [self.tableView layoutIfNeeded];

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
      PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:nil
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
      PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:nil
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
      PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:nil
                                                                  inputTextColor:white
                                                                  errorTextColor:nil
                                                                       tintColor:white
                                                       inputFieldBackgroundColor:nil
                                                               submitButtonColor:nil
                                                                  highlightColor:nil];
      [self.cardFormView applyWithStyle:style];
      self.cardFormView.backgroundColor = darkGray;
      break;
    }
    default: {
      UIColor *black = UIColor.blackColor;
      UIColor *defaultBlue = RGB(0, 122, 255);
      PAYCardFormStyle *style = [[PAYCardFormStyle alloc] initWithLabelTextColor:nil
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  NSString *sectionName;
  switch (section) {
    case 0:
      sectionName = NSLocalizedString(@"example_card_information_section", nil);
      break;
    case 2:
      sectionName = NSLocalizedString(@"example_token_id_section", nil);
      break;
    default:
      break;
  }
  return sectionName;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  // Create Token
  if (indexPath.section == 1 && indexPath.row == 0) {
    if (!self.cardFormView.isValid) {
      return;
    }
    [self createToken];
  }
  // Valdate and Create Token
  if (indexPath.section == 1 && indexPath.row == 1) {
    BOOL isValid = [self.cardFormView validateCardForm];
    if (isValid) {
      [self createToken];
    }
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
               wself.tokenIdLabel.text = token.identifer;
               [wself.tableView reloadData];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
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
  [self toggleCellStyle:self.createTokenCell isEnabled:isAcceptable && self.cardFormView.isValid];
  [self toggleCellStyle:self.validateAndCreateTokenCell isEnabled:isAcceptable];
  NSIndexPath *createButtonRow = [NSIndexPath indexPathForRow:1 inSection:1];
  NSIndexPath *validateAndCreateButtonRow = [NSIndexPath indexPathForRow:2 inSection:1];
  [self.tableView reloadRowsAtIndexPaths:@[ createButtonRow, validateAndCreateButtonRow ]
                        withRowAnimation:UITableViewRowAnimationNone];
}

- (void)toggleCellStyle:(UITableViewCell *)cell isEnabled:(BOOL)isEnabled {
  [cell setUserInteractionEnabled:isEnabled];
  cell.selectionStyle =
      isEnabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
  cell.contentView.alpha = isEnabled ? 1.0 : 0.5;
}

@end
