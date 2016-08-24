//
//  AlertUtils.m
//  Sample
//
//  Created by Shubhangi Pandya on 29/09/15.
//  Copyright (c) 2015 Shubhangi. All rights reserved.
//

#import "AlertUtils.h"
#import "ErrorHandler.h"
#import "UIAlertController+Blocks.h"


#pragma mark - ErrorWrapper

@interface ErrorWrapper ()

@property (nonatomic, copy) NSError *error;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *cancelTitle;
@property (nonatomic, copy) NSString *okTitle;
@property (nonatomic, copy) void (^action)(NSInteger buttonIndex);

@end

@implementation ErrorWrapper

#pragma mark - Init & Dealloc

- (id)initWithError:(NSError *)error title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle okTitle:(NSString *)okTitle action:(void(^)(NSInteger buttonIndex))action {
    self = [super init];
    if (self) {
        self.error = error;
        self.title = title;
        self.message = message;
        self.cancelTitle = cancelTitle;
        self.okTitle = okTitle;
        self.action = action;
    }
    return self;
}

+ (instancetype)errorWrapperWithError:(NSError *)error title:(NSString *)title action:(void(^)(NSInteger buttonIndex))completion {
    return [[self alloc] initWithError:error title:title message:nil cancelTitle:nil okTitle:nil action:completion];
}

+ (instancetype)errorWrapperWithError:(NSError *)error title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle okTitle:(NSString *)okTitle action:(void(^)(NSInteger buttonIndex))action {
    return [[self alloc] initWithError:error title:title message:message cancelTitle:cancelTitle okTitle:okTitle action:action];
}

+ (instancetype)errorWrapperWithError:(NSError *)error action:(void(^)(NSInteger buttonIndex))action {
    return [[self alloc] initWithError:error title:nil message:nil cancelTitle:nil okTitle:nil action:action];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@: title = %@, message = %@", [super description], self.title, self.message];
}

@end

#pragma mark - AlertViewBlockDelegate

@interface AlertViewBlockDelegate ()

@property (nonatomic, copy) void (^completion)(NSInteger);

@end

@implementation AlertViewBlockDelegate

@synthesize errorWrapper;

#pragma mark - Init & Dealloc

- (id)  initWithTitle:(NSString *)title
              message:(NSString *)message
           completion:( void (^)(NSInteger buttonIndex) )completion
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSString *)otherButtonTitles, ...{
    self.completion = completion;
    
    return [super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles, nil];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.completion) {
        self.completion(buttonIndex);
    }
}

- (void)dismissAsCanceled
{
    // this will make the delegate callback which will call the completion block.
    [self dismissWithClickedButtonIndex:self.cancelButtonIndex animated:NO];
}

@end

#pragma mark - AlertUtils

@interface AlertUtils ()

@property (atomic, strong) NSMutableArray *errorQueue;

@property (nonatomic, weak) id<AlertUtilsAlertProtocol> alertView;

- (void)showErrorOrAddToQueue:(ErrorWrapper *)errorWrapper;

@end

@implementation AlertUtils

#pragma mark - Initialization

+ (instancetype)instance {
    static AlertUtils *alertUtils = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        alertUtils = [[self alloc] init];
    });
    return alertUtils;
}

- (id)init {
    if (self = [super init]) {
        self.errorQueue = [NSMutableArray array];
        
        [self showPendingAlertRepeating];   // tickles the queue for an alert that may have been deferred
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc {
    if ([self.alertView respondsToSelector:@selector(setDelegate:)]) {
        self.alertView.delegate = nil;
    }
}

#pragma mark - Class methods

+ (void)showError:(NSError *)error {
    if (![ErrorHandler isInternalError:error]) {
        ErrorWrapper *errorWrapper = [ErrorWrapper errorWrapperWithError:error action:nil];
        [[self instance] showErrorOrAddToQueue:errorWrapper];
    }
}

+ (void)showError:(NSError *)error title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle okTitle:(NSString *)okTitle dismissAction:(void(^)(NSInteger buttonIndex))dismissAction{
    if (![ErrorHandler isInternalError:error]) {
        ErrorWrapper *errorWrapper = [ErrorWrapper errorWrapperWithError:error title:title message:message cancelTitle:cancelTitle okTitle:okTitle action:dismissAction];
        [[self instance] showErrorOrAddToQueue:errorWrapper];
    }
}


+ (void)showError:(NSError *)error title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    if (![ErrorHandler isInternalError:error]) {
        ErrorWrapper *errorWrapper = [ErrorWrapper errorWrapperWithError:error title:title message:message cancelTitle:cancelTitle okTitle:nil action:nil];
        [[self instance] showErrorOrAddToQueue:errorWrapper];
    }
}

+ (void)showError:(NSError *)error title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle dismissAction:(void(^)(NSInteger buttonIndex))dismissAction {
    if (![ErrorHandler isInternalError:error]) {
        ErrorWrapper *errorWrapper = [ErrorWrapper errorWrapperWithError:error title:title message:message cancelTitle:cancelTitle okTitle:nil action:dismissAction];
        [[self instance] showErrorOrAddToQueue:errorWrapper];
    }
}

+ (BOOL) dismissAlert
{
    return [[self instance] dismissAlert];
}

+ (BOOL) dismissAlertAndClearQueue
{
    return [[self instance] dismissAlertAndClearQueue];
}

#pragma mark - Instance methods

- (BOOL) isAlertActive
{
    return (nil != self.alertView);
}

- (BOOL) dismissAlert
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
    }
    
    BOOL bAlertWasActive = [self isAlertActive];
    
    [self.alertView dismissAsCanceled];
    
    self.alertView = nil;
    
    return bAlertWasActive;
}

- (BOOL) dismissAlertAndClearQueue
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
    }

    BOOL bAlertWasActive = [self dismissAlert];
    
    [self.errorQueue removeAllObjects];
    
    return bAlertWasActive;
}

- (void)showErrorOrAddToQueue:(ErrorWrapper *)errorWrapper {
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:errorWrapper waitUntilDone:YES];
    }
    
    // the queue does not hold the active alert, so account for that here
    NSMutableArray *errorQueuePlusActive = [self.errorQueue mutableCopy];
    id activeWrapper = self.alertView.errorWrapper;
    if (activeWrapper) { [errorQueuePlusActive addObject:activeWrapper]; }
    
    NSError *error = errorWrapper.error;
    BOOL isDuplicate = NO;
    if (error.code != ApplicationErrorGeneric) {
        // If the error is not an application error we need to check for duplicates.
        // Application errors are always added to the queue
        for (ErrorWrapper *item in errorQueuePlusActive) {
            if (item.error.code == error.code) {
                // The error is present already, so don't add, just return
                isDuplicate = YES;
                break;
            }
        }
    }
    
    if (!isDuplicate) {
        [self.errorQueue addObject:errorWrapper];
    }
    
    if (![self isAlertActive]) {
        // There is no alertview shown by AlertUtils, so go ahead and show one
        [self showAlertForErrorInQueue];
    }
}

#pragma mark - Private methods

- (void)showAlertForErrorInQueue {
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
    }
    
    if (self.errorQueue.count > 0 && ![self isAlertActive]) {
        
        UIViewController *topMostViewController = [AlertUtils topMostController];
        
        BOOL canPresent = ((![topMostViewController respondsToSelector:@selector(alertUtilsCanPresentAlert:)]) || ([(id)topMostViewController alertUtilsCanPresentAlert:self]));
        
        ErrorWrapper *errorWrapper = [self.errorQueue objectAtIndex:0];
        NSError *error = errorWrapper.error;
        NSString *message = nil;
        if (errorWrapper.message) {
            message = errorWrapper.message;
        }
        else {
            message = error.localizedDescription;
        }

        if (canPresent) {
            if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) || (nil == topMostViewController)) {
                AlertViewBlockDelegate *alert = [[AlertViewBlockDelegate alloc] initWithTitle:errorWrapper.title
                                                                                      message:message
                                                                                   completion:^(NSInteger buttonIndex) {
                                                                                       if (errorWrapper.action) {
                                                                                           errorWrapper.action(buttonIndex);
                                                                                       }
                                                                                       self.alertView = nil;
                                                                                       [self pumpQueue];
                                                                                   }
                                                                            cancelButtonTitle:errorWrapper.cancelTitle
                                                                            otherButtonTitles:errorWrapper.okTitle,nil];
                alert.errorWrapper = errorWrapper;
                [self.errorQueue removeObjectAtIndex:0];
                [alert show];
                self.alertView = alert;
            }
            else {
                UIAlertController *alertController = [UIAlertController showAlertInViewController:topMostViewController
                                                                                        withTitle:errorWrapper.title
                                                                                          message:errorWrapper.message
                                                                                cancelButtonTitle:errorWrapper.cancelTitle
                                                                           destructiveButtonTitle:errorWrapper.okTitle
                                                                                otherButtonTitles:nil
                                                                                         tapBlock:^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex){
                                                                                             if (errorWrapper.action) {
                                                                                                 errorWrapper.action(buttonIndex);
                                                                                             }
                                                                                            
                                                                                             self.alertView = nil;
                                                                                             [self pumpQueue];
                                                                                         }];
                alertController.errorWrapper = errorWrapper;
                [self.errorQueue removeObjectAtIndex:0];
                self.alertView = alertController;
            }
        } 
    }
}

+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (void)pumpQueue {
    if (self.errorQueue.count > 0) {
        //*** already removed by showAlertForErrorInQueue
//        [self.errorQueue removeObjectAtIndex:0];
        [self showAlertForErrorInQueue];
    }
}

- (void) showPendingAlertRepeating
{
    BOOL isActive = UIApplicationStateActive == [[UIApplication sharedApplication] applicationState];
    
    if (isActive && (nil == self.alertView)) {
        [self pumpQueue];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showPendingAlertRepeating];
    });
}

@end
