//
//  JKPopup.m
//  ByrongInvestmentTest
//
//  Created by byRong on 2018/11/1.
//  Copyright © 2018 byRong. All rights reserved.
//

#import "JKPopup.h"

static NSInteger const kAnimationOptionCurveIOS7 = (7 << 16);

JKPopupLayout JKPopupLayoutMake(JKPopupHorizontalLayout horizontal, JKPopupVerticalLayout vertical)
{
    JKPopupLayout layout;
    layout.horizontal = horizontal;
    layout.vertical = vertical;
    return layout;
}

const JKPopupLayout JKPopupLayoutCenter = { JKPopupHorizontalLayoutCenter, JKPopupVerticalLayoutCenter };


@interface NSValue (JKPopupLayout)
+ (NSValue*)valueWithJKPopupLayout:(JKPopupLayout)layout;
- (JKPopupLayout)JKPopupLayoutValue;
@end

@interface JKPopupController : UIViewController

@end

@implementation JKPopupController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [UIApplication sharedApplication].statusBarStyle;
}

@end


@interface JKPopup ()
@property (nonatomic, strong, readwrite) UIView *backgroundView;
@property (nonatomic, strong, readwrite) UIView *containerView;
@property (nonatomic, assign, readwrite) BOOL isBeingShown;
@property (nonatomic, assign, readwrite) BOOL isShowing;
@property (nonatomic, assign, readwrite) BOOL isBeingDismissed;
@property (nonatomic, strong) UIWindow *alertWindow;

- (void)updateForInterfaceOrientation;
- (void)didChangeStatusBarOrientation:(NSNotification*)notification;

// Used for calling dismiss:YES from selector because you can't pass primitives, thanks objc
- (void)dismiss;

@end


@implementation JKPopup

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // stop listening to notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (id)init {
    self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.alertWindow.windowLevel = UIWindowLevelAlert;
    self.alertWindow.rootViewController = [[JKPopupController alloc] init];
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
        
        self.shouldDismissOnBackgroundTouch = YES;
        self.shouldDismissOnContentTouch = NO;
        
        self.showType = JKPopupShowTypeShrinkIn;
        self.dismissType = JKPopupDismissTypeShrinkOut;
        self.maskType = JKPopupMaskTypeDimmed;
        self.dimmedMaskAlpha = 0.5;
        
        self.isBeingShown = NO;
        self.isShowing = NO;
        self.isBeingDismissed = NO;
        
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.backgroundView.userInteractionEnabled = NO;
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundView.frame = self.bounds;
        
        self.containerView = [[UIView alloc] init];
        self.containerView.autoresizesSubviews = NO;
        self.containerView.userInteractionEnabled = YES;
        self.containerView.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.backgroundView];
        [self addSubview:self.containerView];
        
        // register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeStatusBarOrientation:)
                                                     name:UIApplicationDidChangeStatusBarFrameNotification
                                                   object:nil];
    }
    return self;
}


#pragma mark - UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView* hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        
        // Try to dismiss if backgroundTouch flag set.
        if (_shouldDismissOnBackgroundTouch) {
            [self dismiss:YES];
        }
        
        // If no mask, then return nil so touch passes through to underlying views.
        if (self.maskType == JKPopupMaskTypeNone) {
            return nil;
        } else {
            return hitView;
        }
        
    } else {
        
        // If view is within containerView and contentTouch flag set, then try to hide.
        if ([hitView isDescendantOfView:self.containerView]) {
            if (_shouldDismissOnContentTouch) {
                [self dismiss:YES];
            }
        }
        return hitView;
    }
}


#pragma mark - Class Public

+ (JKPopup*)popupWithContentView:(UIView*)contentView
{
    JKPopup* popup = [[[self class] alloc] init];
    popup.contentView = contentView;
    return popup;
}


+ (JKPopup*)popupWithContentView:(UIView*)contentView
                        showType:(JKPopupShowType)showType
                     dismissType:(JKPopupDismissType)dismissType
                        maskType:(JKPopupMaskType)maskType
        dismissOnBackgroundTouch:(BOOL)shouldDismissOnBackgroundTouch
           dismissOnContentTouch:(BOOL)shouldDismissOnContentTouch
{
    JKPopup* popup = [[[self class] alloc] init];
    popup.contentView = contentView;
    popup.showType = showType;
    popup.dismissType = dismissType;
    popup.maskType = maskType;
    popup.shouldDismissOnBackgroundTouch = shouldDismissOnBackgroundTouch;
    popup.shouldDismissOnContentTouch = shouldDismissOnContentTouch;
    return popup;
}


+ (void)dismissAllPopups {
    NSArray* windows = [[UIApplication sharedApplication] windows];
    for (UIWindow* window in windows) {
        if (window.windowLevel == UIWindowLevelAlert) {
            [window forEachPopupDoBlock:^(JKPopup *popup) {
                [popup dismiss:NO];
            }];
        }
    }
}


#pragma mark - Public

- (void)show {
    [self showWithLayout:JKPopupLayoutCenter];
}


- (void)showWithLayout:(JKPopupLayout)layout {
    [self showWithLayout:layout duration:0.0];
}


- (void)showWithDuration:(NSTimeInterval)duration {
    [self showWithLayout:JKPopupLayoutCenter duration:duration];
}


- (void)showWithLayout:(JKPopupLayout)layout duration:(NSTimeInterval)duration {
    NSDictionary* parameters = @{@"layout" : [NSValue valueWithJKPopupLayout:layout],
                                 @"duration" : @(duration)};
    [self showWithParameters:parameters];
}


- (void)showAtCenter:(CGPoint)center inView:(UIView*)view {
    [self showAtCenter:center inView:view withDuration:0.0];
}


- (void)showAtCenter:(CGPoint)center inView:(UIView *)view withDuration:(NSTimeInterval)duration {
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setValue:[NSValue valueWithCGPoint:center] forKey:@"center"];
    [parameters setValue:@(duration) forKey:@"duration"];
    [parameters setValue:view forKey:@"view"];
    [self showWithParameters:[NSDictionary dictionaryWithDictionary:parameters]];
}


- (void)dismiss:(BOOL)animated {
    
    if (self.isShowing && !self.isBeingDismissed) {
        self.isBeingShown = NO;
        self.isShowing = NO;
        self.isBeingDismissed = YES;
        
        // cancel previous dismiss requests (i.e. the dismiss after duration call).
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
        
        [self willStartDismissing];
        
        if (self.willStartDismissingCompletion != nil) {
            self.willStartDismissingCompletion();
        }
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            // Animate background if needed
            void (^backgroundAnimationBlock)(void) = ^(void) {
                self.backgroundView.alpha = 0.0;
            };
            
            if (animated && (self.showType != JKPopupShowTypeNone)) {
                // Make fade happen faster than motion. Use linear for fades.
                [UIView animateWithDuration:0.15
                                      delay:0
                                    options:UIViewAnimationOptionCurveLinear
                                 animations:backgroundAnimationBlock
                                 completion:NULL];
            } else {
                backgroundAnimationBlock();
            }
            
            // Setup completion block
            void (^completionBlock)(BOOL) = ^(BOOL finished) {
                
                [self removeFromSuperview];
                
                self.isBeingShown = NO;
                self.isShowing = NO;
                self.isBeingDismissed = NO;
                
                [self didFinishDismissing];
                
                if (self.didFinishDismissingCompletion != nil) {
                    self.didFinishDismissingCompletion();
                }
            };
            
            NSTimeInterval bounce1Duration = 0.13;
            NSTimeInterval bounce2Duration = (bounce1Duration * 2.0);
            
            // Animate content if needed
            if (animated) {
                switch (self.dismissType) {
                    case JKPopupDismissTypeFadeOut: {
                        [UIView animateWithDuration:0.15
                                              delay:0
                                            options:UIViewAnimationOptionCurveLinear
                                         animations:^{
                                             self.containerView.alpha = 0.0;
                                         } completion:completionBlock];
                        break;
                    }
                        
                    case JKPopupDismissTypeGrowOut: {
                        [UIView animateWithDuration:0.15
                                              delay:0
                                            options:kAnimationOptionCurveIOS7
                                         animations:^{
                                             self.containerView.alpha = 0.0;
                                             self.containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                                         } completion:completionBlock];
                        break;
                    }
                        
                    case JKPopupDismissTypeShrinkOut: {
                        [UIView animateWithDuration:0.15
                                              delay:0
                                            options:kAnimationOptionCurveIOS7
                                         animations:^{
                                             self.containerView.alpha = 0.0;
                                             self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                                         } completion:completionBlock];
                        break;
                    }
                        
                    case JKPopupDismissTypeSlideOutToTop: {
                        [UIView animateWithDuration:0.30
                                              delay:0
                                            options:kAnimationOptionCurveIOS7
                                         animations:^{
                                             CGRect finalFrame = self.containerView.frame;
                                             finalFrame.origin.y = -CGRectGetHeight(finalFrame);
                                             self.containerView.frame = finalFrame;
                                         }
                                         completion:completionBlock];
                        break;
                    }
                        
                    case JKPopupDismissTypeSlideOutToBottom: {
                        [UIView animateWithDuration:0.30
                                              delay:0
                                            options:kAnimationOptionCurveIOS7
                                         animations:^{
                                             CGRect finalFrame = self.containerView.frame;
                                             finalFrame.origin.y = CGRectGetHeight(self.bounds);
                                             self.containerView.frame = finalFrame;
                                         }
                                         completion:completionBlock];
                        break;
                    }
                        
                    case JKPopupDismissTypeSlideOutToLeft: {
                        [UIView animateWithDuration:0.30
                                              delay:0
                                            options:kAnimationOptionCurveIOS7
                                         animations:^{
                                             CGRect finalFrame = self.containerView.frame;
                                             finalFrame.origin.x = -CGRectGetWidth(finalFrame);
                                             self.containerView.frame = finalFrame;
                                         }
                                         completion:completionBlock];
                        break;
                    }
                        
                    case JKPopupDismissTypeSlideOutToRight: {
                        [UIView animateWithDuration:0.30
                                              delay:0
                                            options:kAnimationOptionCurveIOS7
                                         animations:^{
                                             CGRect finalFrame = self.containerView.frame;
                                             finalFrame.origin.x = CGRectGetWidth(self.bounds);
                                             self.containerView.frame = finalFrame;
                                         }
                                         completion:completionBlock];
                        
                        break;
                    }
                        
                    case JKPopupDismissTypeBounceOut: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void){
                                             self.containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                                         }
                                         completion:^(BOOL finished){
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void){
                                                                  self.containerView.alpha = 0.0;
                                                                  self.containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                                                              }
                                                              completion:completionBlock];
                                         }];
                        
                        break;
                    }
                        
                    case JKPopupDismissTypeBounceOutToTop: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void){
                                             CGRect finalFrame = self.containerView.frame;
                                             finalFrame.origin.y += 40.0;
                                             self.containerView.frame = finalFrame;
                                         }
                                         completion:^(BOOL finished){
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void){
                                                                  CGRect finalFrame = self.containerView.frame;
                                                                  finalFrame.origin.y = -CGRectGetHeight(finalFrame);
                                                                  self.containerView.frame = finalFrame;
                                                              }
                                                              completion:completionBlock];
                                         }];
                        
                        break;
                    }
                        
                    case JKPopupDismissTypeBounceOutToBottom: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void){
                                             CGRect finalFrame = self.containerView.frame;
                                             finalFrame.origin.y -= 40.0;
                                             self.containerView.frame = finalFrame;
                                         }
                                         completion:^(BOOL finished){
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void){
                                                                  CGRect finalFrame = self.containerView.frame;
                                                                  finalFrame.origin.y = CGRectGetHeight(self.bounds);
                                                                  self.containerView.frame = finalFrame;
                                                              }
                                                              completion:completionBlock];
                                         }];
                        
                        break;
                    }
                        
                    case JKPopupDismissTypeBounceOutToLeft: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void){
                                             CGRect finalFrame = self.containerView.frame;
                                             finalFrame.origin.x += 40.0;
                                             self.containerView.frame = finalFrame;
                                         }
                                         completion:^(BOOL finished){
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void){
                                                                  CGRect finalFrame = self.containerView.frame;
                                                                  finalFrame.origin.x = -CGRectGetWidth(finalFrame);
                                                                  self.containerView.frame = finalFrame;
                                                              }
                                                              completion:completionBlock];
                                         }];
                        break;
                    }
                        
                    case JKPopupDismissTypeBounceOutToRight: {
                        [UIView animateWithDuration:bounce1Duration
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^(void){
                                             CGRect finalFrame = self.containerView.frame;
                                             finalFrame.origin.x -= 40.0;
                                             self.containerView.frame = finalFrame;
                                         }
                                         completion:^(BOOL finished){
                                             
                                             [UIView animateWithDuration:bounce2Duration
                                                                   delay:0
                                                                 options:UIViewAnimationOptionCurveEaseIn
                                                              animations:^(void){
                                                                  CGRect finalFrame = self.containerView.frame;
                                                                  finalFrame.origin.x = CGRectGetWidth(self.bounds);
                                                                  self.containerView.frame = finalFrame;
                                                              }
                                                              completion:completionBlock];
                                         }];
                        break;
                    }
                        
                    default: {
                        self.containerView.alpha = 0.0;
                        completionBlock(YES);
                        break;
                    }
                }
            } else {
                self.containerView.alpha = 0.0;
                completionBlock(YES);
            }
            
        });
    }
}


#pragma mark - Private

- (void)showWithParameters:(NSDictionary*)parameters {
    
    // If popup can be shown
    if (!self.isBeingShown && !self.isShowing && !self.isBeingDismissed) {
        self.isBeingShown = YES;
        self.isShowing = NO;
        self.isBeingDismissed = NO;
        
        [self willStartShowing];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            // Prepare by adding to the top window.
            if(!self.superview){
                [self.alertWindow.rootViewController.view addSubview:self];
                [self.alertWindow makeKeyAndVisible];
            }
            
            // Before we calculate layout for containerView, make sure we are transformed for current orientation.
            [self updateForInterfaceOrientation];
            
            // Make sure we're not hidden
            self.hidden = NO;
            self.alpha = 1.0;
            
            // Setup background view
            self.backgroundView.alpha = 0.0;
            if (self.maskType == JKPopupMaskTypeDimmed) {
                self.backgroundView.backgroundColor = [UIColor colorWithRed:(0.0/255.0f) green:(0.0/255.0f) blue:(0.0/255.0f) alpha:self.dimmedMaskAlpha];
            } else {
                self.backgroundView.backgroundColor = [UIColor clearColor];
            }
            
            // Animate background if needed
            void (^backgroundAnimationBlock)(void) = ^(void) {
                self.backgroundView.alpha = 1.0;
            };
            
            if (self.showType != JKPopupShowTypeNone) {
                // Make fade happen faster than motion. Use linear for fades.
                [UIView animateWithDuration:0.15
                                      delay:0
                                    options:UIViewAnimationOptionCurveLinear
                                 animations:backgroundAnimationBlock
                                 completion:NULL];
            } else {
                backgroundAnimationBlock();
            }
            
            // Determine duration. Default to 0 if none provided.
            NSTimeInterval duration;
            NSNumber* durationNumber = [parameters valueForKey:@"duration"];
            if (durationNumber != nil) {
                duration = [durationNumber doubleValue];
            } else {
                duration = 0.0;
            }
            
            // Setup completion block
            void (^completionBlock)(BOOL) = ^(BOOL finished) {
                self.isBeingShown = NO;
                self.isShowing = YES;
                self.isBeingDismissed = NO;
                
                [self didFinishShowing];
                
                if (self.didFinishShowingCompletion != nil) {
                    self.didFinishShowingCompletion();
                }
                
                // Set to hide after duration if greater than zero.
                if (duration > 0.0) {
                    [self performSelector:@selector(dismiss) withObject:nil afterDelay:duration];
                }
            };
            
            // Add contentView to container
            if (self.contentView.superview != self.containerView) {
                [self.containerView addSubview:self.contentView];
            }
            
            // Re-layout (this is needed if the contentView is using autoLayout)
            [self.contentView layoutIfNeeded];
            
            // Size container to match contentView
            CGRect containerFrame = self.containerView.frame;
            containerFrame.size = self.contentView.frame.size;
            self.containerView.frame = containerFrame;
            // Position contentView to fill it
            CGRect contentViewFrame = self.contentView.frame;
            contentViewFrame.origin = CGPointZero;
            self.contentView.frame = contentViewFrame;
            
            // Reset self.containerView's constraints in case contentView is uaing autolayout.
            UIView* contentView = self.contentView;
            NSDictionary* views = NSDictionaryOfVariableBindings(contentView);
            
            [self.containerView removeConstraints:self.containerView.constraints];
            [self.containerView addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|"
                                                     options:0
                                                     metrics:nil
                                                       views:views]];
            
            [self.containerView addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|"
                                                     options:0
                                                     metrics:nil
                                                       views:views]];
            
            // Determine final position and necessary autoresizingMask for container.
            CGRect finalContainerFrame = containerFrame;
            UIViewAutoresizing containerAutoresizingMask = UIViewAutoresizingNone;
            
            // Use explicit center coordinates if provided.
            NSValue* centerValue = [parameters valueForKey:@"center"];
            if (centerValue != nil) {
                
                CGPoint centerInView = [centerValue CGPointValue];
                CGPoint centerInSelf;
                
                // Convert coordinates from provided view to self. Otherwise use as-is.
                UIView* fromView = [parameters valueForKey:@"view"];
                if (fromView != nil) {
                    centerInSelf = [self convertPoint:centerInView fromView:fromView];
                } else {
                    centerInSelf = centerInView;
                }
                
                finalContainerFrame.origin.x = (centerInSelf.x - CGRectGetWidth(finalContainerFrame)/2.0);
                finalContainerFrame.origin.y = (centerInSelf.y - CGRectGetHeight(finalContainerFrame)/2.0);
                containerAutoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
            }
            
            // Otherwise use relative layout. Default to center if none provided.
            else {
                
                NSValue* layoutValue = [parameters valueForKey:@"layout"];
                JKPopupLayout layout;
                if (layoutValue != nil) {
                    layout = [layoutValue JKPopupLayoutValue];
                } else {
                    layout = JKPopupLayoutCenter;
                }
                
                switch (layout.horizontal) {
                        
                    case JKPopupHorizontalLayoutLeft: {
                        finalContainerFrame.origin.x = 0.0;
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleRightMargin;
                        break;
                    }
                        
                    case JKPopupHorizontalLayoutLeftOfCenter: {
                        finalContainerFrame.origin.x = floorf(CGRectGetWidth(self.bounds)/3.0 - CGRectGetWidth(containerFrame)/2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                        break;
                    }
                        
                    case JKPopupHorizontalLayoutCenter: {
                        finalContainerFrame.origin.x = floorf((CGRectGetWidth(self.bounds) - CGRectGetWidth(containerFrame))/2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                        break;
                    }
                        
                    case JKPopupHorizontalLayoutRightOfCenter: {
                        finalContainerFrame.origin.x = floorf(CGRectGetWidth(self.bounds)*2.0/3.0 - CGRectGetWidth(containerFrame)/2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                        break;
                    }
                        
                    case JKPopupHorizontalLayoutRight: {
                        finalContainerFrame.origin.x = CGRectGetWidth(self.bounds) - CGRectGetWidth(containerFrame);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin;
                        break;
                    }
                        
                    default:
                        break;
                }
                
                // Vertical
                switch (layout.vertical) {
                        
                    case JKPopupVerticalLayoutTop: {
                        finalContainerFrame.origin.y = 0;
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
                        break;
                    }
                        
                    case JKPopupVerticalLayoutAboveCenter: {
                        finalContainerFrame.origin.y = floorf(CGRectGetHeight(self.bounds)/3.0 - CGRectGetHeight(containerFrame)/2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                        break;
                    }
                        
                    case JKPopupVerticalLayoutCenter: {
                        finalContainerFrame.origin.y = floorf((CGRectGetHeight(self.bounds) - CGRectGetHeight(containerFrame))/2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                        break;
                    }
                        
                    case JKPopupVerticalLayoutBelowCenter: {
                        finalContainerFrame.origin.y = floorf(CGRectGetHeight(self.bounds)*2.0/3.0 - CGRectGetHeight(containerFrame)/2.0);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                        break;
                    }
                        
                    case JKPopupVerticalLayoutBottom: {
                        finalContainerFrame.origin.y = CGRectGetHeight(self.bounds) - CGRectGetHeight(containerFrame);
                        containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin;
                        break;
                    }
                        
                    default:
                        break;
                }
            }
            
            self.containerView.autoresizingMask = containerAutoresizingMask;
            
            // Animate content if needed
            switch (self.showType) {
                case JKPopupShowTypeFadeIn: {
                    
                    self.containerView.alpha = 0.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.15
                                          delay:0
                                        options:UIViewAnimationOptionCurveLinear
                                     animations:^{
                                         self.containerView.alpha = 1.0;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case JKPopupShowTypeGrowIn: {
                    
                    self.containerView.alpha = 0.0;
                    // set frame before transform here...
                    CGRect startFrame = finalContainerFrame;
                    self.containerView.frame = startFrame;
                    self.containerView.transform = CGAffineTransformMakeScale(0.85, 0.85);
                    
                    [UIView animateWithDuration:0.15
                                          delay:0
                                        options:kAnimationOptionCurveIOS7 // note: this curve ignores durations
                                     animations:^{
                                         self.containerView.alpha = 1.0;
                                         // set transform before frame here...
                                         self.containerView.transform = CGAffineTransformIdentity;
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    
                    break;
                }
                    
                case JKPopupShowTypeShrinkIn: {
                    self.containerView.alpha = 0.0;
                    // set frame before transform here...
                    CGRect startFrame = finalContainerFrame;
                    self.containerView.frame = startFrame;
                    self.containerView.transform = CGAffineTransformMakeScale(1.25, 1.25);
                    
                    [UIView animateWithDuration:0.15
                                          delay:0
                                        options:kAnimationOptionCurveIOS7 // note: this curve ignores durations
                                     animations:^{
                                         self.containerView.alpha = 1.0;
                                         // set transform before frame here...
                                         self.containerView.transform = CGAffineTransformIdentity;
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case JKPopupShowTypeSlideInFromTop: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.y = -CGRectGetHeight(finalContainerFrame);
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.30
                                          delay:0
                                        options:kAnimationOptionCurveIOS7 // note: this curve ignores durations
                                     animations:^{
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case JKPopupShowTypeSlideInFromBottom: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.y = CGRectGetHeight(self.bounds);
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.30
                                          delay:0
                                        options:kAnimationOptionCurveIOS7 // note: this curve ignores durations
                                     animations:^{
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case JKPopupShowTypeSlideInFromLeft: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.x = -CGRectGetWidth(finalContainerFrame);
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.30
                                          delay:0
                                        options:kAnimationOptionCurveIOS7 // note: this curve ignores durations
                                     animations:^{
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case JKPopupShowTypeSlideInFromRight: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.x = CGRectGetWidth(self.bounds);
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.30
                                          delay:0
                                        options:kAnimationOptionCurveIOS7 // note: this curve ignores durations
                                     animations:^{
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    
                    break;
                }
                    
                case JKPopupShowTypeBounceIn: {
                    self.containerView.alpha = 0.0;
                    // set frame before transform here...
                    CGRect startFrame = finalContainerFrame;
                    self.containerView.frame = startFrame;
                    self.containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:15.0
                                        options:0
                                     animations:^{
                                         self.containerView.alpha = 1.0;
                                         self.containerView.transform = CGAffineTransformIdentity;
                                     }
                                     completion:completionBlock];
                    
                    break;
                }
                    
                case JKPopupShowTypeBounceInFromTop: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.y = -CGRectGetHeight(finalContainerFrame);
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:10.0
                                        options:0
                                     animations:^{
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case JKPopupShowTypeBounceInFromBottom: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.y = CGRectGetHeight(self.bounds);
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:10.0
                                        options:0
                                     animations:^{
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case JKPopupShowTypeBounceInFromLeft: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.x = -CGRectGetWidth(finalContainerFrame);
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:10.0
                                        options:0
                                     animations:^{
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                case JKPopupShowTypeBounceInFromRight: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    CGRect startFrame = finalContainerFrame;
                    startFrame.origin.x = CGRectGetWidth(self.bounds);
                    self.containerView.frame = startFrame;
                    
                    [UIView animateWithDuration:0.6
                                          delay:0.0
                         usingSpringWithDamping:0.8
                          initialSpringVelocity:10.0
                                        options:0
                                     animations:^{
                                         self.containerView.frame = finalContainerFrame;
                                     }
                                     completion:completionBlock];
                    break;
                }
                    
                default: {
                    self.containerView.alpha = 1.0;
                    self.containerView.transform = CGAffineTransformIdentity;
                    self.containerView.frame = finalContainerFrame;
                    
                    completionBlock(YES);
                    
                    break;
                }
            }
            
        });
    }
}


- (void)dismiss {
    [self dismiss:YES];
}


- (void)updateForInterfaceOrientation {
    
    // We must manually fix orientation prior to iOS 8
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        CGFloat angle;
        
        switch (orientation) {
            case UIInterfaceOrientationPortraitUpsideDown:
                angle = M_PI;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                angle = -M_PI/2.0f;;
                
                break;
            case UIInterfaceOrientationLandscapeRight:
                angle = M_PI/2.0f;
                
                break;
            default: // as UIInterfaceOrientationPortrait
                angle = 0.0;
                break;
        }
        
        self.transform = CGAffineTransformMakeRotation(angle);
    }
    
    self.frame = self.window.bounds;
}


#pragma mark - Notification handlers

- (void)didChangeStatusBarOrientation:(NSNotification*)notification {
    [self updateForInterfaceOrientation];
}


#pragma mark - Subclassing

- (void)willStartShowing {
    
}


- (void)didFinishShowing {
    
}


- (void)willStartDismissing {
    
}


- (void)didFinishDismissing {
    
}

@end




#pragma mark - Categories

@implementation UIView(JKPopup)


- (void)forEachPopupDoBlock:(void (^)(JKPopup* popup))block {
    for (UIView *subview in self.subviews)
    {
        if ([subview isKindOfClass:[JKPopup class]])
        {
            block((JKPopup *)subview);
        } else {
            [subview forEachPopupDoBlock:block];
        }
    }
}


- (void)dismissPresentingPopup {
    
    // Iterate over superviews until you find a JKPopup and dismiss it, then gtfo
    UIView* view = self;
    while (view != nil) {
        if ([view isKindOfClass:[JKPopup class]]) {
            [(JKPopup*)view dismiss:YES];
            break;
        }
        view = [view superview];
    }
}

@end




@implementation NSValue (JKPopupLayout)

+ (NSValue *)valueWithJKPopupLayout:(JKPopupLayout)layout
{
    return [NSValue valueWithBytes:&layout objCType:@encode(JKPopupLayout)];
}

- (JKPopupLayout)JKPopupLayoutValue
{
    JKPopupLayout layout;
    
    [self getValue:&layout];
    
    return layout;
}
@end
