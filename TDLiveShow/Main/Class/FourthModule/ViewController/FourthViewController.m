//
//  FourthViewController.m
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "FourthViewController.h"
#import "TDLoginModel.h"
#import "AppDelegate.h"

@interface FourthViewController ()

@end

@implementation FourthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"个人中心";
    self.view.backgroundColor = [UIColor purpleColor];
    //退出登录button
    UIButton *logOutBtn = [[UIButton alloc] initWithFrame:CGRectMake(150, 230, 80, 80)];
    logOutBtn.backgroundColor = [UIColor blueColor];
    [logOutBtn setTitle:@"退出" forState:UIControlStateNormal];
    logOutBtn.layer.cornerRadius = 40;
    [logOutBtn addTarget:self action:@selector(logoutAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:logOutBtn];
}

- (void)logoutAction:(UIButton *)button{
    AppDelegate *app = [UIApplication sharedApplication].delegate;
   [[TDLoginModel sharedInstance] logout:^{
       [app enterLoginUI];
       TDLog(@"退出登录成功");
   } fail:^(int code, NSString *msg) {
       [app enterLoginUI];
       TDLog(@"退出登录失败 errCode = %d, errMsg = %@", code, msg);
   }];
}

@end
