//
//  JKPopupLayout.h
//  JKPopupView
//
//  Created by byRong on 2018/11/19.
//  Copyright © 2018 byRong. All rights reserved.
//

#import <Foundation/Foundation.h>

// JKPopupHorizontalLayout: 控制弹出窗口水平放置的位置。
typedef NS_ENUM(NSInteger, JKPopupHorizontalLayout) {
    JKPopupHorizontalLayoutCustom = 0,
    JKPopupHorizontalLayoutLeft,
    JKPopupHorizontalLayoutLeftOfCenter,
    JKPopupHorizontalLayoutCenter,
    JKPopupHorizontalLayoutRightOfCenter,
    JKPopupHorizontalLayoutRight,
};

// JKPopupVerticalLayout: 控制弹出窗口垂直放置的位置。
typedef NS_ENUM(NSInteger, JKPopupVerticalLayout) {
    JKPopupVerticalLayoutCustom = 0,
    JKPopupVerticalLayoutTop,
    JKPopupVerticalLayoutAboveCenter,
    JKPopupVerticalLayoutCenter,
    JKPopupVerticalLayoutBelowCenter,
    JKPopupVerticalLayoutBottom,
};

@interface JKPopupLayout : NSObject

@property (nonatomic, assign) JKPopupHorizontalLayout horizontal;

@property (nonatomic, assign) JKPopupVerticalLayout vertical;

+ (JKPopupLayout *)JKPopupLayoutMakeHorizontal:(JKPopupHorizontalLayout)horizontal vertical:(JKPopupVerticalLayout)vertical;

+ (JKPopupLayout *)JKPopupLayoutCenter;

@end
