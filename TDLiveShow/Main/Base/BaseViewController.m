//
//  BaseViewController.m
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置返回按钮
    UIBarButtonItem *backIetm = [[UIBarButtonItem alloc] init];
    backIetm.title = @"返回";
    self.navigationItem.backBarButtonItem = backIetm;
}

@end
