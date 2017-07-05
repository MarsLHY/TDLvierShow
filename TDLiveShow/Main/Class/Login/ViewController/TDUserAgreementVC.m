//
//  TDUserAgreementVC.m
//  TDLiveShow
//
//  Created by TD on 2017/7/4.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "TDUserAgreementVC.h"
#import "TCLoginModel.h"
#import "AppDelegate.h"

@interface TDUserAgreementVC ()
{
    UIWebView *_webView;
}
@end

@implementation TDUserAgreementVC

-(instancetype)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"用户协议";
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - 50)];
    [self.view addSubview:_webView];
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    NSString * htmlPath = [[NSBundle mainBundle] pathForResource:@"UserProtocol"
                                                          ofType:@"html"];
    NSString * htmlCont = [NSString stringWithContentsOfFile:htmlPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    [_webView loadHTMLString:htmlCont baseURL:baseURL];
    
    UIView *lineView1 = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 50, self.view.width, 0.5)];
    lineView1.backgroundColor = [UIColor grayColor];
    [self.view addSubview:lineView1];
    
    UIView *lineView2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.width/2,lineView1.bottom, 0.5, 49)];
    lineView2.backgroundColor = [UIColor grayColor];
    [self.view addSubview:lineView2];
    
    //同意
    UIButton *unAgreeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    unAgreeBtn.frame = CGRectMake(0,lineView1.bottom, self.view.width/2, 49);
    [unAgreeBtn setTitle:@"不同意" forState:UIControlStateNormal];
    [unAgreeBtn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
    [unAgreeBtn addTarget:self action:@selector(unAgree) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:unAgreeBtn];
    
    //不同意
    UIButton *agreeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    agreeBtn.frame = CGRectMake(self.view.width/2 + 1, lineView1.bottom, self.view.width/2, 49);
    [agreeBtn setTitle:@"同意" forState:UIControlStateNormal];
    [agreeBtn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
    [agreeBtn addTarget:self action:@selector(agree) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:agreeBtn];
}

-(void)unAgree{
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    [[TCLoginModel sharedInstance] logout:^{
        [app enterLoginUI];
    } fail:^(int code, NSString *msg) {
        [app enterLoginUI];
    }];
}

-(void)agree{
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:TDUserAgreement];
    [[AppDelegate sharedAppDelegate] enterMainUI];
}

@end
