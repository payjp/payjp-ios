//
//  ThreeDSecureExampleViewController.m
//  example-objc
//

#import "ThreeDSecureExampleViewController.h"
#import "UIViewController+Alert.h"

@interface ThreeDSecureExampleViewController ()

@property(weak, nonatomic) IBOutlet UIButton *startButton;
@property(weak, nonatomic) IBOutlet UITextField *textField;
@property(weak, nonatomic) IBOutlet UILabel *resultLabel;
@property(strong, nonatomic) NSString *pendingResourceId;

@end

@implementation ThreeDSecureExampleViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (IBAction)startThreeDSecure:(id)sender {
  if (self.textField.text.length == 0) {
    self.resultLabel.text = @"";
    self.resultLabel.hidden = YES;
    return;
  }

  self.pendingResourceId = self.textField.text;
  [[PAYJPThreeDSecureProcessHandler sharedHandler]
      startThreeDSecureProcessWithViewController:self
                                        delegate:self
                                      resourceId:self.textField.text];
}

#pragma mark - PAYJPThreeDSecureProcessHandlerDelegate

- (void)threeDSecureProcessHandlerDidFinish:(PAYJPThreeDSecureProcessHandler *)handler
                                     status:(enum ThreeDSecureProcessStatus)status {
  switch (status) {
    case ThreeDSecureProcessStatusCompleted:
      self.resultLabel.text =
          @"3Dセキュア認証が終了しました。\nこの結果をサーバーサイドに伝え、完了処理や結果のハンド"
          @"リングを行なってください。\n後続処理の実装方法に関してはドキュメントをご参照ください。";
      self.resultLabel.textColor = UIColor.blackColor;
      self.resultLabel.hidden = NO;
      break;
    case ThreeDSecureProcessStatusCanceled:
      self.resultLabel.text = @"3Dセキュア認証がキャンセルされました。";
      self.resultLabel.textColor = UIColor.redColor;
      self.resultLabel.hidden = NO;
      break;
    default:
      break;
  }
}

@end
