//
//  AlertUtils.h
//  Sample
//
//  Created by Shubhangi Pandya on 29/09/15.
//  Copyright (c) 2015 Shubhangi. All rights reserved.
//

@class AlertUtils;

/**
 This protocol is used by the AlertUtils class to query a view controller as to whether an alert can be presented.
 
 @see AlertUtils
 */
@protocol AlertUtilsPresentingProtocol <NSObject>

@optional
/**
 This method is invoked by the AlertUtils class to determine whether an
 alert can be presented.
 @param alertUtils The AlertUtils instance that wishes to present an alert.
 @return YES if an alert can be presented.
 */
- (BOOL) alertUtilsCanPresentAlert:(AlertUtils *)alertUtils;

@end


@interface ErrorWrapper : NSObject

@end


@protocol AlertUtilsAlertProtocol <NSObject>

@property (strong) ErrorWrapper *errorWrapper;

- (void)dismissAsCanceled;

@optional
@property (weak) id delegate;

@end


@interface AlertViewBlockDelegate : UIAlertView<UIAlertViewDelegate, AlertUtilsAlertProtocol>

- (id)  initWithTitle:(NSString *)title
              message:(NSString *)message
           completion:( void (^)(NSInteger buttonIndex) )completion
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSString *)otherButtonTitles, ...NS_REQUIRES_NIL_TERMINATION;

- (void)dismissAsCanceled;

@end

@interface AlertUtils : NSObject

+ (instancetype)instance;
+ (void)showError:(NSError *)error;
+ (void)showError:(NSError *)error title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle;
+ (void)showError:(NSError *)error title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle dismissAction:(void(^)(NSInteger buttonIndex))dismissAction ;
+ (void)showError:(NSError *)error title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle okTitle:(NSString *)okTitle dismissAction:(void(^)(NSInteger buttonIndex))dismissAction;

/**
 This method dismisses as canceled any current alert, and flushes the error queue.
 
 @return YES if an alert was on-screen through this class.
 */
+ (BOOL) dismissAlertAndClearQueue;

/**
 This method dismisses as canceled any current alert. The error queue is left intact.
 */
+ (BOOL) dismissAlert;

@end
