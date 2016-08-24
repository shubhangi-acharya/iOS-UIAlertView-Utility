//
//  ErrorHandler.h
//  Sample
//
//  Created by Shubhangi Pandya on 29/09/15.
//  Copyright (c) 2015 Shubhangi. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    NoError = 0,
    // Internal errors, not exposed to the user.
    InternalErrorOperationCancelled = -1,
    InternalErrorMax = -99,
    ApplicationErrorGeneric = -200,
}
ErrorCodes;


@interface ErrorHandler : NSObject
+ (BOOL)isInternalError:(NSError *)error;

@end
