//
//  PAYJPSDKTests.m
//  PAYJPTests
//
//  Created by Li-Hsuan Chen on 2019/07/24.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import PAYJP;

@interface PAYJPSDKTests : XCTestCase
@end

@implementation PAYJPSDKTests

- (void)setUp {
    [super setUp];
    
    PAYJPSDK.publicKey = nil;
    PAYJPSDK.locale = nil;
}

- (void)testValuesSet {
    NSString *mockPublicKey = @"publicKey";
    NSLocale *mockLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"ja"];
    
    PAYJPSDK.publicKey = mockPublicKey;
    PAYJPSDK.locale = mockLocale;
    
    XCTAssertEqual(PAYJPSDK.publicKey, mockPublicKey);
    XCTAssertEqual(PAYJPSDK.locale.localeIdentifier, mockLocale.localeIdentifier);
}

@end
