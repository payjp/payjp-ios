//
//  PAYJP.h
//  PAYJP
//

#import <Foundation/Foundation.h>
#import "CardIOCardParams.h"
#import "CardIOProxy.h"

FOUNDATION_EXPORT double PAYJPVersionNumber;
FOUNDATION_EXPORT const unsigned char PAYJPVersionString[];

/// PAY.JP API's endpoint.
FOUNDATION_EXPORT NSString *const PAYJPApiEndpoint;

/// PAY.JP SDK related error's main domain.
FOUNDATION_EXPORT NSString *const PAYErrorDomain;

/// The Apple Pay token is invalid.
FOUNDATION_EXPORT NSInteger const PAYErrorInvalidApplePayToken;
/// The system error.
FOUNDATION_EXPORT NSInteger const PAYErrorSystemError;
/// No body data or no response error.
FOUNDATION_EXPORT NSInteger const PAYErrorInvalidResponse;
/// The error came back from server side.
FOUNDATION_EXPORT NSInteger const PAYErrorServiceError;
/// Invalid JSON object.
FOUNDATION_EXPORT NSInteger const PAYErrorInvalidJSON;
/// Form validation error.
FOUNDATION_EXPORT NSInteger const PAYErrorFormInvalid;
/// Too many requests
FOUNDATION_EXPORT NSInteger const PAYErrorRateLimitExceeded;

/// Use this key name to get `PAYErrorInvalidApplePayToken` error's data which is stored in the
/// `userInfo`.
FOUNDATION_EXPORT NSString *const PAYErrorInvalidApplePayTokenObject;
/// Use this key name to get `PAYErrorSystemError` error's data which is stored in the `userInfo`.
FOUNDATION_EXPORT NSString *const PAYErrorSystemErrorObject;
/// Use this key name to get `PAYErrorInvalidResponse` error's data which is stored in the
/// `userInfo`.
FOUNDATION_EXPORT NSString *const PAYErrorInvalidResponseObject;
/// Use this key name to get `PAYErrorServiceError` error's data which is stored in the `userInfo`.
FOUNDATION_EXPORT NSString *const PAYErrorServiceErrorObject;
/// Use this key name to get `PAYErrorInvalidJSON` error's data which is stored in the `userInfo`.
FOUNDATION_EXPORT NSString *const PAYErrorInvalidJSONObject;
FOUNDATION_EXPORT NSString *const PAYErrorInvalidJSONErrorObject;

/// 3DSecure status
typedef NSString *const PAYThreeDSecureStatus NS_STRING_ENUM;
FOUNDATION_EXPORT PAYThreeDSecureStatus PAYThreeDSecureStatusUnverified;
FOUNDATION_EXPORT PAYThreeDSecureStatus PAYThreeDSecureStatusVerified;
FOUNDATION_EXPORT PAYThreeDSecureStatus PAYThreeDSecureStatusFailed;
FOUNDATION_EXPORT PAYThreeDSecureStatus PAYThreeDSecureStatusAttempted;
FOUNDATION_EXPORT PAYThreeDSecureStatus PAYThreeDSecureStatusAborted;
FOUNDATION_EXPORT PAYThreeDSecureStatus PAYThreeDSecureStatusError;
