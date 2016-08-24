//
//  ErrorHandler.m
//  Sample
//
//  Created by Shubhangi Pandya on 29/09/15.
//  Copyright (c) 2015 Shubhangi. All rights reserved.
//

#import "ErrorHandler.h"

@implementation ErrorHandler
+ (BOOL)isInternalError:(NSError *)error {
    if (NoError > error.code && error.code > InternalErrorMax) {
        return YES;
    }
    return NO;
}
@end
