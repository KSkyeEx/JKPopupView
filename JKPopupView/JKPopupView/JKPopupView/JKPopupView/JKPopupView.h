//
//  JKPopupView.h
//  JKPopupView
//
//  Created by byRong on 2018/11/19.
//  Copyright © 2018 byRong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKPopupLayout.h"

// JKPopupShowType: 控制弹出窗口的显示方式。
typedef NS_ENUM(NSInteger, JKPopupShowType) {
    JKPopupShowTypeNone = 0,
    JKPopupShowTypeFadeIn,
    JKPopupShowTypeGrowIn,
    JKPopupShowTypeShrinkIn,
    JKPopupShowTypeSlideInFromTop,
    JKPopupShowTypeSlideInFromBottom,
    JKPopupShowTypeSlideInFromLeft,
    JKPopupShowTypeSlideInFromRight,
    JKPopupShowTypeBounceIn,
    JKPopupShowTypeBounceInFromTop,
    JKPopupShowTypeBounceInFromBottom,
    JKPopupShowTypeBounceInFromLeft,
    JKPopupShowTypeBounceInFromRight,
};

// JKPopupDismissType: 控制如何关闭弹出窗口。
typedef NS_ENUM(NSInteger, JKPopupDismissType) {
    JKPopupDismissTypeNone = 0,
    JKPopupDismissTypeFadeOut,
    JKPopupDismissTypeGrowOut,
    JKPopupDismissTypeShrinkOut,
    JKPopupDismissTypeSlideOutToTop,
    JKPopupDismissTypeSlideOutToBottom,
    JKPopupDismissTypeSlideOutToLeft,
    JKPopupDismissTypeSlideOutToRight,
    JKPopupDismissTypeBounceOut,
    JKPopupDismissTypeBounceOutToTop,
    JKPopupDismissTypeBounceOutToBottom,
    JKPopupDismissTypeBounceOutToLeft,
    JKPopupDismissTypeBounceOutToRight,
};

// JKPopupMaskType
typedef NS_ENUM(NSInteger, JKPopupMaskType) {
    JKPopupMaskTypeNone = 0, // 不允许与底层视图交互。
    JKPopupMaskTypeClear = JKPopupMaskTypeNone, // 不允许与底层视图交互。
    JKPopupMaskTypeDimmed, // 不允许与底层视图交互，暗淡背景。
    JKPopupMaskTypeVisualEffect //毛玻璃效果
};

@interface JKPopupView : UIView
/**
 这是您要在Popup中显示的视图。必须在willStartShowing之前或之中提供contentView。必须在willStartShowing之前或之中设置所需的contentView大小。
 */
@property (nonatomic, strong) UIView *contentView;
/**
 用于呈现contentView的动画转换。 default = shrink in
 */
@property (nonatomic, assign) JKPopupShowType showType;
/**
 用于隐藏contentView的动画转换。 default = shrink out
 */
@property (nonatomic, assign) JKPopupDismissType dismissType;
/**
 蒙版可防止背景触摸传递到基础视图。 默认=暗淡。
 */
@property (nonatomic, assign) JKPopupMaskType maskType;
/**
 覆盖灰色背景蒙版的alpha值。 默认= 0.5
 */
@property (nonatomic, assign) CGFloat dimmedMaskAlpha;
/**
 如果YES，则触摸背景时弹出窗口将被取消。 默认= YES。
 */
@property (nonatomic, assign) BOOL shouldDismissOnBackgroundTouch;
/**
 如果YES，则在触摸内容视图时弹出窗口将被取消。 默认= NO。
 */
@property (nonatomic, assign) BOOL shouldDismissOnContentTouch;
/**
 在节目动画结束后调用块。 确保在块内使用弱引用以避免保留周期。
 */
@property (nonatomic, copy) void (^didFinishShowingCompletion)(void);
/**
 在关闭动画开始时调用块。 确保在块内使用弱引用以避免保留周期。
 */
@property (nonatomic, copy) void (^willStartDismissingCompletion)(void);
/**
 在关闭动画结束后调用块。 确保在块内使用弱引用以避免保留周期。
 */
@property (nonatomic, copy) void (^didFinishDismissingCompletion)(void);
/**
 使用默认值创建弹出窗口的便捷方法（模仿UIAlertView）。
 */
+ (JKPopupView *)popupWithContentView:(UIView *)contentView;
/**
 使用自定义值创建弹出窗口的便捷方法。
 */
+ (JKPopupView *)popupWithContentView:(UIView*)contentView
                             showType:(JKPopupShowType)showType
                          dismissType:(JKPopupDismissType)dismissType
                             maskType:(JKPopupMaskType)maskType
             dismissOnBackgroundTouch:(BOOL)shouldDismissOnBackgroundTouch
                dismissOnContentTouch:(BOOL)shouldDismissOnContentTouch;
/**
 显示具有中心布局的弹出窗口 动画由showType决定。
 */
- (void)show;
/**
 显示指定的布局。
 */
- (void)showWithLayout:(JKPopupLayout *)layout;
/**
 显示然后在持续时间后解雇。 0.0或更小将被视为无穷大。
 */
- (void)showWithDuration:(NSTimeInterval)duration;
/**
 显示布局并在持续时间后消失。
 */
- (void)showWithLayout:(JKPopupLayout *)layout duration:(NSTimeInterval)duration;
/**
 以视图坐标系中的点为中心显示。 如果视图为nil，则使用屏幕基准坐标。
 */
- (void)showAtCenter:(CGPoint)center inView:(UIView *)view;
/**
 显示以视图坐标系中的点为中心，然后在持续时间后关闭。
 */
- (void)showAtCenter:(CGPoint)center inView:(UIView *)view withDuration:(NSTimeInterval)duration;
/**
 关闭弹出窗口。 如果动画为YES，则使用dismissType。
 */
- (void)dismiss:(BOOL)animated;


#pragma mark Subclassing
@property (nonatomic, strong, readonly) UIView *backgroundView;
@property (nonatomic, strong, readonly) UIView *containerView;
@property (nonatomic, assign, readonly) BOOL isBeingShown;
@property (nonatomic, assign, readonly) BOOL isShowing;
@property (nonatomic, assign, readonly) BOOL isBeingDismissed;

- (void)willStartShowing;
- (void)didFinishShowing;
- (void)willStartDismissing;
- (void)didFinishDismissing;
@end


