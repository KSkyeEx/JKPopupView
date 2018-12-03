//
//  JKPopupView.m
//  JKPopupView
//
//  Created by byRong on 2018/11/19.
//  Copyright © 2018 byRong. All rights reserved.
//

#import "JKPopupView.h"
/*！
 * 强弱引用转换，用于解决代码块（block）与强引用self之间的循环引用问题
 */
#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) @autoreleasepool{} __weak __typeof__(object) weak##_##object = object
#else
#define weakify(object) @autoreleasepool{} __block __typeof__(object) block##_##object = object
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) @try{} @finally{} {} __weak __typeof__(object) weak##_##object = object
#else
#define weakify(object) @try{} @finally{} {} __block __typeof__(object) block##_##object = object
#endif
#endif
#endif

/*！
 * 强弱引用转换，用于解决代码块（block）与强引用对象之间的循环引用问题
 */
#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) @autoreleasepool{} __typeof__(object) object = weak##_##object
#else
#define strongify(object) @autoreleasepool{} __typeof__(object) object = block##_##object
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) @try{} @finally{} __typeof__(object) object = weak##_##object
#else
#define strongify(object) @try{} @finally{} __typeof__(object) object = block##_##object
#endif
#endif
#endif

static NSInteger const kAnimationOptionCurveIOS7 = (7 << 16);

//全局信号量
dispatch_semaphore_t globalInstancesLock;
//执行QUEUE的Name
char *QUEUE_NAME = "com.alert.queue";
//初始化 -- 借鉴YYWebImage的写法
static void alertViewInitGlobal() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalInstancesLock = dispatch_semaphore_create(1);
    });
}

@interface JKPopupController : UIViewController

@end

@implementation JKPopupController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [UIApplication sharedApplication].statusBarStyle;
}

@end

@interface JKPopupView ()
@property (nonatomic, strong, readwrite) UIView *backgroundView;
@property (nonatomic, strong, readwrite) UIView *containerView;
@property (nonatomic, assign, readwrite) BOOL isBeingShown;
@property (nonatomic, assign, readwrite) BOOL isShowing;
@property (nonatomic, assign, readwrite) BOOL isBeingDismissed;
@property (nonatomic, strong) UIWindow *alertWindow;
@property (nonatomic, weak) UIWindow *keyWindow;
@property (nonatomic, assign) NSTimeInterval duration;
//确定容器的最终位置和必要的autoresizingMask。
@property (nonatomic, assign) UIViewAutoresizing containerAutoresizingMask;
@property (nonatomic, assign) CGRect finalContainerFrame;

@property (nonatomic, copy) void (^showBackgroundAnimationBlock)(void);
@property (nonatomic, copy) void (^showCompletionBlock)(BOOL finished);
@property (nonatomic, copy) void (^dismissBackgroundAnimationBlock)(void);
@property (nonatomic, copy) void (^dismissCompletionBlock)(BOOL finished);

- (void)updateForInterfaceOrientation;
- (void)didChangeStatusBarOrientation:(NSNotification*)notification;
@end

@implementation JKPopupView
- (instancetype)init
{
    self = [self initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self) {
        self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.alertWindow.windowLevel = UIWindowLevelAlert;
        self.alertWindow.rootViewController = [[JKPopupController alloc] init];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        alertViewInitGlobal();
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
        self.duration = 0.0;
        
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
        
        // 注册通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeStatusBarOrientation:)
                                                     name:UIApplicationDidChangeStatusBarFrameNotification
                                                   object:nil];
        [self setupBlock];
    }
    return self;
}

/**
 设置block
 */
- (void)setupBlock
{
    weakify(self);
    self.showBackgroundAnimationBlock = ^{
        strongify(self);
        self.backgroundView.alpha = 1;
    };
    self.showCompletionBlock = ^(BOOL finished) {
        strongify(self);
        self.isBeingShown = NO;
        self.isShowing = YES;
        self.isBeingDismissed = NO;
        [self didFinishShowing];
        if (self.didFinishShowingCompletion != nil) {
            self.didFinishShowingCompletion();
        }
        //如果大于零，则设置为在持续时间后隐藏。
        if (self.duration > 0.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismiss:YES];
            });
        }
    };
    
    self.dismissBackgroundAnimationBlock = ^{
        strongify(self);
        self.backgroundView.alpha = 0.0;
    };
    self.dismissCompletionBlock = ^(BOOL finished) {
        strongify(self);
        [self removeFromSuperview];
        [self.alertWindow resignKeyWindow];
        [self.keyWindow makeKeyAndVisible];
        dispatch_async(dispatch_queue_create(QUEUE_NAME, DISPATCH_QUEUE_SERIAL), ^{
            //Release Lock
            dispatch_semaphore_signal(globalInstancesLock);
        });
        self.isBeingShown = NO;
        self.isShowing = NO;
        self.isBeingDismissed = NO;
        [self didFinishDismissing];
        if (self.didFinishDismissingCompletion != nil) {
            self.didFinishDismissingCompletion();
        }
    };
    
}
#pragma mark - Notification handlers
- (void)didChangeStatusBarOrientation:(NSNotification*)notification
{
    [self updateForInterfaceOrientation];
}

#pragma mark - override
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        //如果设置了backgroundTouch标志，请尝试关闭。
        if (self.shouldDismissOnBackgroundTouch) {
            [self dismiss:YES];
        }
        return hitView;
    } else {
        //如果视图位于容器视图和内容触摸标志设置，则尝试隐藏。
        if ([hitView isDescendantOfView:self.containerView]) {
            if (self.shouldDismissOnContentTouch) {
                [self dismiss:YES];
            }
        }
        return hitView;
    }
}

#pragma mark - Class Public
+ (JKPopupView *)popupWithContentView:(UIView *)contentView
{
    JKPopupView *popupView = [[[self class] alloc] init];
    popupView.contentView = contentView;
    return popupView;
}
+ (JKPopupView *)popupWithContentView:(UIView *)contentView showType:(JKPopupShowType)showType dismissType:(JKPopupDismissType)dismissType maskType:(JKPopupMaskType)maskType dismissOnBackgroundTouch:(BOOL)shouldDismissOnBackgroundTouch dismissOnContentTouch:(BOOL)shouldDismissOnContentTouch
{
    JKPopupView *popupView = [[[self class] alloc] init];
    popupView.contentView = contentView;
    popupView.showType = showType;
    popupView.dismissType = dismissType;
    popupView.maskType = maskType;
    popupView.shouldDismissOnBackgroundTouch = shouldDismissOnBackgroundTouch;
    popupView.shouldDismissOnContentTouch = shouldDismissOnContentTouch;
    return popupView;
}
#pragma mark - Public
- (void)show
{
    [self showWithLayout:[JKPopupLayout JKPopupLayoutCenter]];
}

- (void)showWithLayout:(JKPopupLayout *)layout
{
    [self showWithLayout:layout duration:0.0];
}

- (void)showWithDuration:(NSTimeInterval)duration
{
    [self showWithLayout:[JKPopupLayout JKPopupLayoutCenter] duration:duration];
}

- (void)showWithLayout:(JKPopupLayout *)layout duration:(NSTimeInterval)duration
{
    [self showWithLayout:layout center:CGPointZero inView:nil withDuration:duration];
}

- (void)showAtCenter:(CGPoint)center inView:(UIView  *)view
{
    [self showAtCenter:center inView:view withDuration:0.0];
}

- (void)showAtCenter:(CGPoint)center inView:(UIView *)view withDuration:(NSTimeInterval)duration
{
    [self showWithLayout:nil center:center inView:view withDuration:duration];
}

- (void)dismiss:(BOOL)animated
{
    if (self.isShowing && !self.isBeingDismissed) {
        self.isBeingShown = NO;
        self.isShowing = NO;
        self.isBeingDismissed = YES;
        // cancel previous dismiss requests (i.e. the dismiss after duration call).
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss:) object:nil];
        [self willStartDismissing];
        if (self.willStartDismissingCompletion != nil) {
            self.willStartDismissingCompletion();
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissWithType:self.dismissType animation:animated];
        });
    }
}
- (void)dismissWithType:(JKPopupDismissType)dismissType animation:(BOOL)animated
{
    if (animated) {
        NSTimeInterval bounce1Duration = 0.13;
        NSTimeInterval bounce2Duration = (bounce1Duration * 2.0);
        switch (dismissType) {
            case JKPopupDismissTypeFadeOut:
            {
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.containerView.alpha = 0.0;
                } completion:self.dismissCompletionBlock];
                break;
            }
            case JKPopupDismissTypeGrowOut:
            {
                [UIView animateWithDuration:0.15 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                    self.containerView.alpha = 0.0;
                    self.containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                } completion:self.dismissCompletionBlock];
                break;
            }
            case JKPopupDismissTypeShrinkOut:
            {
                [UIView animateWithDuration:0.15 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                    self.containerView.alpha = 0.0;
                    self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                } completion:self.dismissCompletionBlock];
                break;
            }
            case JKPopupDismissTypeSlideOutToTop:
            {
                [UIView animateWithDuration:0.30 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                    CGRect finalFrame = self.containerView.frame;
                    finalFrame.origin.y = -CGRectGetHeight(finalFrame);
                    self.containerView.frame = finalFrame;
                } completion:self.dismissCompletionBlock];
                break;
            }
            case JKPopupDismissTypeSlideOutToBottom:
            {
                [UIView animateWithDuration:0.30 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                    CGRect finalFrame = self.containerView.frame;
                    finalFrame.origin.y = CGRectGetHeight(self.bounds);
                    self.containerView.frame = finalFrame;
                } completion:self.dismissCompletionBlock];
                break;
            }
            case JKPopupDismissTypeSlideOutToLeft:
            {
                [UIView animateWithDuration:0.30 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                    CGRect finalFrame = self.containerView.frame;
                    finalFrame.origin.x = -CGRectGetWidth(finalFrame);
                    self.containerView.frame = finalFrame;
                } completion:self.dismissCompletionBlock];
                break;
            }
            case JKPopupDismissTypeSlideOutToRight: {
                [UIView animateWithDuration:0.30 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                    CGRect finalFrame = self.containerView.frame;
                    finalFrame.origin.x = CGRectGetWidth(self.bounds);
                    self.containerView.frame = finalFrame;
                } completion:self.dismissCompletionBlock];
                break;
            }
            case JKPopupDismissTypeBounceOut:
            {
                [UIView animateWithDuration:bounce1Duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^(void){
                    self.containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                } completion:^(BOOL finished){
                    [UIView animateWithDuration:bounce2Duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^(void){
                        self.containerView.alpha = 0.0;
                        self.containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    } completion:self.dismissCompletionBlock];
                }];
                break;
            }
            case JKPopupDismissTypeBounceOutToTop:
            {
                [UIView animateWithDuration:bounce1Duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^(void){
                    CGRect finalFrame = self.containerView.frame;
                    finalFrame.origin.y += 40.0;
                    self.containerView.frame = finalFrame;
                } completion:^(BOOL finished){
                    [UIView animateWithDuration:bounce2Duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^(void){
                        CGRect finalFrame = self.containerView.frame;
                        finalFrame.origin.y = -CGRectGetHeight(finalFrame);
                        self.containerView.frame = finalFrame;
                    } completion:self.dismissCompletionBlock];
                }];
                break;
            }
            case JKPopupDismissTypeBounceOutToBottom:
            {
                [UIView animateWithDuration:bounce1Duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^(void){
                    CGRect finalFrame = self.containerView.frame;
                    finalFrame.origin.y -= 40.0;
                    self.containerView.frame = finalFrame;
                } completion:^(BOOL finished){
                    [UIView animateWithDuration:bounce2Duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^(void){
                        CGRect finalFrame = self.containerView.frame;
                        finalFrame.origin.y = CGRectGetHeight(self.bounds);
                        self.containerView.frame = finalFrame;
                    } completion:self.dismissCompletionBlock];
                }];
                break;
            }
            case JKPopupDismissTypeBounceOutToLeft:
            {
                [UIView animateWithDuration:bounce1Duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^(void){
                    CGRect finalFrame = self.containerView.frame;
                    finalFrame.origin.x += 40.0;
                    self.containerView.frame = finalFrame;
                } completion:^(BOOL finished){
                    [UIView animateWithDuration:bounce2Duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^(void){
                        CGRect finalFrame = self.containerView.frame;
                        finalFrame.origin.x = -CGRectGetWidth(finalFrame);
                        self.containerView.frame = finalFrame;
                    } completion:self.dismissCompletionBlock];
                }];
                break;
            }
            case JKPopupDismissTypeBounceOutToRight:
            {
                [UIView animateWithDuration:bounce1Duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^(void){
                    CGRect finalFrame = self.containerView.frame;
                    finalFrame.origin.x -= 40.0;
                    self.containerView.frame = finalFrame;
                } completion:^(BOOL finished){
                    [UIView animateWithDuration:bounce2Duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^(void){
                        CGRect finalFrame = self.containerView.frame;
                        finalFrame.origin.x = CGRectGetWidth(self.bounds);
                        self.containerView.frame = finalFrame;
                    } completion:self.dismissCompletionBlock];
                }];
                break;
            }
            default: {
                self.containerView.alpha = 0.0;
                self.dismissCompletionBlock(YES);
                break;
            }
        }
    } else {
        self.containerView.alpha = 0.0;
        self.dismissCompletionBlock(YES);
    }
}
#pragma mark - Private

- (void)showWithLayout:(JKPopupLayout *)layout center:(CGPoint)center inView:(UIView *)view withDuration:(NSTimeInterval)duration
{
    self.duration = duration;
    if (!self.isBeingShown && !self.isShowing && !self.isBeingDismissed) {
        self.isBeingShown = YES;
        self.isShowing = NO;
        self.isBeingDismissed = NO;
        [self willStartShowing];
        dispatch_async(dispatch_queue_create(QUEUE_NAME, DISPATCH_QUEUE_SERIAL), ^{
            //Lock
            dispatch_semaphore_wait(globalInstancesLock, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupBackgroundView:self.backgroundView maskType:self.maskType showType:self.showType];
                [self addContentView:self.contentView containerView:self.containerView];
                if (!CGPointEqualToPoint(center, CGPointZero)) {
                    [self setupFrameWithFromView:view center:center finalContainerFrame:self.finalContainerFrame containerAutoresizingMask:self.containerAutoresizingMask];
                } else {
                    [self setupFrameWithLayout:layout finalContainerFrame:self.finalContainerFrame containerAutoresizingMask:self.containerAutoresizingMask];
                }
                self.containerView.autoresizingMask = self.containerAutoresizingMask;
                [self showWithType:self.showType containerView:self.containerView finalContainerFrame:self.finalContainerFrame];
            });
        });
    }
}

- (void)setupBackgroundView:(UIView *)backgroundView maskType:(JKPopupMaskType)maskType showType:(JKPopupShowType)showType
{
    if(!self.superview){
        [self.alertWindow.rootViewController.view addSubview:self];
        self.keyWindow = [UIApplication sharedApplication].keyWindow;
        [self.alertWindow makeKeyAndVisible];
    }
    [self updateForInterfaceOrientation];
    self.hidden = NO;
    self.alpha = 1.0;
    backgroundView.alpha = 0.0;
    switch (maskType) {
        case JKPopupMaskTypeNone | JKPopupMaskTypeClear:
        {
            backgroundView.backgroundColor = [UIColor clearColor];
        }
            break;
        case JKPopupMaskTypeDimmed:
        {
            backgroundView.backgroundColor = [UIColor colorWithRed:(0.0/255.0f) green:(0.0/255.0f) blue:(0.0/255.0f) alpha:self.dimmedMaskAlpha];
        }
            break;
        case JKPopupMaskTypeVisualEffect:
        {
            [self.backgroundView removeFromSuperview];
            UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithFrame:self.bounds];
            effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            effectView.userInteractionEnabled = NO;
            effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            effectView.backgroundColor = [UIColor colorWithRed:(0.0/255.0f) green:(0.0/255.0f) blue:(0.0/255.0f) alpha:self.dimmedMaskAlpha];
            self.backgroundView = effectView;
            [self insertSubview:self.backgroundView atIndex:0];
        }
            break;
        default:
        {
            backgroundView.backgroundColor = [UIColor clearColor];
        }
            break;
    }
    if (showType != JKPopupShowTypeNone) {
        // Make fade happen faster than motion. Use linear for fades.
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:self.showBackgroundAnimationBlock completion:NULL];
    } else {
        self.showBackgroundAnimationBlock();
    }
}

- (void)addContentView:(UIView *)contentView containerView:(UIView *)containerView
{
    if (contentView.superview != containerView) {
        [containerView addSubview:contentView];
    }
    //重新布局（如果contentView使用autoLayout，则需要这样做）
    [contentView layoutIfNeeded];
    
    CGRect containerFrame = containerView.frame;
    containerFrame.size = contentView.frame.size;
    containerView.frame = containerFrame;
    //定位contentView来填充它
    CGRect contentViewFrame = contentView.frame;
    contentViewFrame.origin = CGPointZero;
    contentView.frame = contentViewFrame;
    //重置self.containerView视图内容视图使用autolayout时的视图约束。
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
    [containerView removeConstraints:containerView.constraints];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|"
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:views]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|"
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:views]];
    //确定容器的最终位置和必要的autoresizingMask。
    self.finalContainerFrame = containerFrame;
    self.containerAutoresizingMask = UIViewAutoresizingNone;
}

- (void)setupFrameWithFromView:(UIView *)fromView center:(CGPoint)center finalContainerFrame:(CGRect)finalContainerFrame containerAutoresizingMask:(UIViewAutoresizing)containerAutoresizingMask
{
    CGPoint centerInSelf;
    //将坐标从提供的视图转换为self。 否则按原样使用。
    if (fromView != nil) {
        centerInSelf = [self convertPoint:center fromView:fromView];
    } else {
        centerInSelf = center;
    }
    finalContainerFrame.origin.x = (centerInSelf.x - CGRectGetWidth(finalContainerFrame)/2.0);
    finalContainerFrame.origin.y = (centerInSelf.y - CGRectGetHeight(finalContainerFrame)/2.0);
    containerAutoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    self.finalContainerFrame = finalContainerFrame;
    self.containerAutoresizingMask = containerAutoresizingMask;
}

- (void)setupFrameWithLayout:(JKPopupLayout *)layout finalContainerFrame:(CGRect)finalContainerFrame containerAutoresizingMask:(UIViewAutoresizing)containerAutoresizingMask
{
    if (layout == nil) {
        layout = [JKPopupLayout JKPopupLayoutCenter];
    }
    switch (layout.horizontal) {
        case JKPopupHorizontalLayoutLeft:
        {
            finalContainerFrame.origin.x = 0.0;
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleRightMargin;
            break;
        }
        case JKPopupHorizontalLayoutLeftOfCenter:
        {
            finalContainerFrame.origin.x = floorf(CGRectGetWidth(self.bounds)/3.0 - CGRectGetWidth(finalContainerFrame)/2.0);
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        }
        case JKPopupHorizontalLayoutCenter:
        {
            finalContainerFrame.origin.x = floorf((CGRectGetWidth(self.bounds) - CGRectGetWidth(finalContainerFrame))/2.0);
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        }
        case JKPopupHorizontalLayoutRightOfCenter:
        {
            finalContainerFrame.origin.x = floorf(CGRectGetWidth(self.bounds)*2.0/3.0 - CGRectGetWidth(finalContainerFrame)/2.0);
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        }
        case JKPopupHorizontalLayoutRight:
        {
            finalContainerFrame.origin.x = CGRectGetWidth(self.bounds) - CGRectGetWidth(finalContainerFrame);
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleLeftMargin;
            break;
        }
        default:
            break;
    }
    // Vertical
    switch (layout.vertical) {
        case JKPopupVerticalLayoutTop:
        {
            finalContainerFrame.origin.y = 0;
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
            break;
        }
        case JKPopupVerticalLayoutAboveCenter:
        {
            finalContainerFrame.origin.y = floorf(CGRectGetHeight(self.bounds)/3.0 - CGRectGetHeight(finalContainerFrame)/2.0);
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            break;
        }
        case JKPopupVerticalLayoutCenter:
        {
            finalContainerFrame.origin.y = floorf((CGRectGetHeight(self.bounds) - CGRectGetHeight(finalContainerFrame))/2.0);
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            break;
        }
        case JKPopupVerticalLayoutBelowCenter:
        {
            finalContainerFrame.origin.y = floorf(CGRectGetHeight(self.bounds)*2.0/3.0 - CGRectGetHeight(finalContainerFrame)/2.0);
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            break;
        }
        case JKPopupVerticalLayoutBottom:
        {
            finalContainerFrame.origin.y = CGRectGetHeight(self.bounds) - CGRectGetHeight(finalContainerFrame);
            containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin;
            break;
        }
        default:
            break;
    }
    self.finalContainerFrame = finalContainerFrame;
    self.containerAutoresizingMask = containerAutoresizingMask;
}

- (void)showWithType:(JKPopupShowType)showType containerView:(UIView *)containerView finalContainerFrame:(CGRect)finalContainerFrame
{
    switch (showType) {
        case JKPopupShowTypeFadeIn:
        {
            containerView.alpha = 0.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                containerView.alpha = 1.0;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeGrowIn:
        {
            containerView.alpha = 0.0;
            //在变换之前设frame
            CGRect startFrame = finalContainerFrame;
            containerView.frame = startFrame;
            containerView.transform = CGAffineTransformMakeScale(0.85, 0.85);
            //注意：此曲线忽略持续时间
            [UIView animateWithDuration:0.15 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                containerView.alpha = 1.0;
                //在变换之前设frame
                containerView.transform = CGAffineTransformIdentity;
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeShrinkIn:
        {
            containerView.alpha = 0.0;
            CGRect startFrame = finalContainerFrame;
            containerView.frame = startFrame;
            containerView.transform = CGAffineTransformMakeScale(1.25, 1.25);
            [UIView animateWithDuration:0.15 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                containerView.alpha = 1.0;
                containerView.transform = CGAffineTransformIdentity;
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeSlideInFromTop:
        {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            startFrame.origin.y = -CGRectGetHeight(finalContainerFrame);
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.30 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeSlideInFromBottom:
        {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            startFrame.origin.y = CGRectGetHeight(self.bounds);
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.30 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeSlideInFromLeft:
        {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            startFrame.origin.x = -CGRectGetWidth(finalContainerFrame);
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.30 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeSlideInFromRight:
        {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            startFrame.origin.x = CGRectGetWidth(self.bounds);
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.30 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeBounceIn:
        {
            containerView.alpha = 0.0;
            CGRect startFrame = finalContainerFrame;
            containerView.frame = startFrame;
            containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
            [UIView animateWithDuration:0.6 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:15.0 options:0 animations:^{
                containerView.alpha = 1.0;
                containerView.transform = CGAffineTransformIdentity;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeBounceInFromTop:
        {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            startFrame.origin.y = -CGRectGetHeight(finalContainerFrame);
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.6 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:10.0 options:0 animations:^{
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeBounceInFromBottom:
        {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            startFrame.origin.y = CGRectGetHeight(self.bounds);
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.6 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:10.0 options:0 animations:^{
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeBounceInFromLeft:
        {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            startFrame.origin.x = -CGRectGetWidth(finalContainerFrame);
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.6 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:10.0 options:0 animations:^{
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        case JKPopupShowTypeBounceInFromRight:
        {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            CGRect startFrame = finalContainerFrame;
            startFrame.origin.x = CGRectGetWidth(self.bounds);
            containerView.frame = startFrame;
            [UIView animateWithDuration:0.6 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:10.0 options:0 animations:^{
                containerView.frame = finalContainerFrame;
            } completion:self.showCompletionBlock];
            break;
        }
        default: {
            containerView.alpha = 1.0;
            containerView.transform = CGAffineTransformIdentity;
            containerView.frame = finalContainerFrame;
            self.showCompletionBlock(YES);
            break;
        }
    }
}

- (void)updateForInterfaceOrientation
{
    self.frame = self.window.bounds;
}

#pragma mark - Subclassing

- (void)willStartShowing
{
    
}

- (void)didFinishShowing
{
    
}

- (void)willStartDismissing
{
    
}

- (void)didFinishDismissing
{
    
}
@end
