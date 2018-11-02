//
//  NavigationController.m
//  ByRongInvestment
//
//  Created by Wayne on 16/6/30.
//  Copyright © 2016年 Hangzhou Byrong Investment Management Co., Ltd. All
//  rights reserved.
//

#import "NavigationController.h"
#import "ViewController.h"


@interface NavigationController ()

@end


@implementation NavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.topViewController.preferredStatusBarStyle;
}
@end
