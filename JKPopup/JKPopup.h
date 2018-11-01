//
//  JKPopup.h
//  ByrongInvestmentTest
//
//  Created by byRong on 2018/11/1.
//  Copyright © 2018 byRong. All rights reserved.
//

#import <UIKit/UIKit.h>

// JKPopupShowType: Controls how the popup will be presented.
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

// JKPopupDismissType: Controls how the popup will be dismissed.
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



// JKPopupHorizontalLayout: Controls where the popup will come to rest horizontally.
typedef NS_ENUM(NSInteger, JKPopupHorizontalLayout) {
    JKPopupHorizontalLayoutCustom = 0,
    JKPopupHorizontalLayoutLeft,
    JKPopupHorizontalLayoutLeftOfCenter,
    JKPopupHorizontalLayoutCenter,
    JKPopupHorizontalLayoutRightOfCenter,
    JKPopupHorizontalLayoutRight,
};

// JKPopupVerticalLayout: Controls where the popup will come to rest vertically.
typedef NS_ENUM(NSInteger, JKPopupVerticalLayout) {
    JKPopupVerticalLayoutCustom = 0,
    JKPopupVerticalLayoutTop,
    JKPopupVerticalLayoutAboveCenter,
    JKPopupVerticalLayoutCenter,
    JKPopupVerticalLayoutBelowCenter,
    JKPopupVerticalLayoutBottom,
};

// JKPopupMaskType
typedef NS_ENUM(NSInteger, JKPopupMaskType) {
    JKPopupMaskTypeNone = 0, // Allow interaction with underlying views.
    JKPopupMaskTypeClear, // Don't allow interaction with underlying views.
    JKPopupMaskTypeDimmed, // Don't allow interaction with underlying views, dim background.
};

// JKPopupLayout structure and maker functions
struct JKPopupLayout {
    JKPopupHorizontalLayout horizontal;
    JKPopupVerticalLayout vertical;
};
typedef struct JKPopupLayout JKPopupLayout;

extern JKPopupLayout JKPopupLayoutMake(JKPopupHorizontalLayout horizontal, JKPopupVerticalLayout vertical);

extern const JKPopupLayout JKPopupLayoutCenter;

@interface JKPopup : UIView
// This is the view that you want to appear in Popup.
// - Must provide contentView before or in willStartShowing.
// - Must set desired size of contentView before or in willStartShowing.
@property (nonatomic, strong) UIView* contentView;

// Animation transition for presenting contentView. default = shrink in
@property (nonatomic, assign) JKPopupShowType showType;

// Animation transition for dismissing contentView. default = shrink out
@property (nonatomic, assign) JKPopupDismissType dismissType;

// Mask prevents background touches from passing to underlying views. default = dimmed.
@property (nonatomic, assign) JKPopupMaskType maskType;

// Overrides alpha value for dimmed background mask. default = 0.5
@property (nonatomic, assign) CGFloat dimmedMaskAlpha;

// If YES, then popup will get dismissed when background is touched. default = YES.
@property (nonatomic, assign) BOOL shouldDismissOnBackgroundTouch;

// If YES, then popup will get dismissed when content view is touched. default = NO.
@property (nonatomic, assign) BOOL shouldDismissOnContentTouch;

// Block gets called after show animation finishes. Be sure to use weak reference for popup within the block to avoid retain cycle.
@property (nonatomic, copy) void (^didFinishShowingCompletion)(void);

// Block gets called when dismiss animation starts. Be sure to use weak reference for popup within the block to avoid retain cycle.
@property (nonatomic, copy) void (^willStartDismissingCompletion)(void);

// Block gets called after dismiss animation finishes. Be sure to use weak reference for popup within the block to avoid retain cycle.
@property (nonatomic, copy) void (^didFinishDismissingCompletion)(void);

// Convenience method for creating popup with default values (mimics UIAlertView).
+ (JKPopup*)popupWithContentView:(UIView*)contentView;

// Convenience method for creating popup with custom values.
+ (JKPopup*)popupWithContentView:(UIView*)contentView
                        showType:(JKPopupShowType)showType
                     dismissType:(JKPopupDismissType)dismissType
                        maskType:(JKPopupMaskType)maskType
        dismissOnBackgroundTouch:(BOOL)shouldDismissOnBackgroundTouch
           dismissOnContentTouch:(BOOL)shouldDismissOnContentTouch;

// Dismisses all the popups in the app. Use as a fail-safe for cleaning up.
+ (void)dismissAllPopups;

// Show popup with center layout. Animation determined by showType.
- (void)show;

// Show with specified layout.
- (void)showWithLayout:(JKPopupLayout)layout;

// Show and then dismiss after duration. 0.0 or less will be considered infinity.
- (void)showWithDuration:(NSTimeInterval)duration;

// Show with layout and dismiss after duration.
- (void)showWithLayout:(JKPopupLayout)layout duration:(NSTimeInterval)duration;

// Show centered at point in view's coordinate system. If view is nil use screen base coordinates.
- (void)showAtCenter:(CGPoint)center inView:(UIView*)view;

// Show centered at point in view's coordinate system, then dismiss after duration.
- (void)showAtCenter:(CGPoint)center inView:(UIView *)view withDuration:(NSTimeInterval)duration;

// Dismiss popup. Uses dismissType if animated is YES.
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


#pragma mark - UIView Category
@interface UIView(JKPopup)
- (void)forEachPopupDoBlock:(void (^)(JKPopup* popup))block;
- (void)dismissPresentingPopup;
@end

