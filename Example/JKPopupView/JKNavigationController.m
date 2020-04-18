//
//  JKNavigationController.m
//  JKPopupView_Example
//
//  Created by weij on 2020/4/18.
//  Copyright © 2020 weij. All rights reserved.
//

#import "JKNavigationController.h"

@interface JKNavigationController ()

@end

@implementation JKNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.topViewController.preferredStatusBarStyle;
}
@end
