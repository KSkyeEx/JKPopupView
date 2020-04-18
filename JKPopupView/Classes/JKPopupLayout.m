//
//  JKPopupLayout.m
//  JKPopupView
//
//  Created by byRong on 2018/11/19.
//  Copyright © 2018 byRong. All rights reserved.
//

#import "JKPopupLayout.h"

@implementation JKPopupLayout
+ (JKPopupLayout *)JKPopupLayoutMakeHorizontal:(JKPopupHorizontalLayout)horizontal vertical:(JKPopupVerticalLayout)vertical {
    JKPopupLayout *layout = [[JKPopupLayout alloc] init];
    layout.horizontal = horizontal;
    layout.vertical = vertical;
    return layout;
}

+ (JKPopupLayout *)JKPopupLayoutCenter {
    JKPopupLayout *layout = [[JKPopupLayout alloc] init];
    layout.horizontal = JKPopupHorizontalLayoutCenter;
    layout.vertical = JKPopupVerticalLayoutCenter;
    return layout;
}
@end
