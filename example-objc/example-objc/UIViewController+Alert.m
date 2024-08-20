//
//  UIViewController+Alert.m
//  example-objc
//
//  Created by Tadashi Wakayanagi on 2019/11/20.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

#import "UIViewController+Alert.h"

@implementation UIViewController (Alert)

- (void)showToken:(PAYToken *)token {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"success"
                                          message:[self displayToken:token]
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert animated:true completion:nil];
}

- (void)showError:(NSError *)error {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"error"
                                          message:error.localizedDescription
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert animated:true completion:nil];
}

- (NSString *)displayToken:(PAYToken *)token {
  return [NSString stringWithFormat:@"id=%@,\ncard.id=%@,\ncard.last4=%@,\ncard.exp=%hhu/"
                                    @"%hu,\ncard.name=%@,\ncard.email=%@,\ncard.phone=%@",
                                    token.identifer, token.card.identifer, token.card.last4Number,
                                    token.card.expirationMonth, token.card.expirationYear,
                                    token.card.name, token.card.email, token.card.phone];
}

@end
