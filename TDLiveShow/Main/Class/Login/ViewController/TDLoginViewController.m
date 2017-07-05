//
//  TDLoginViewController.m
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "TDLoginViewController.h"
#import "TDRegisterViewController.h"
#import "FirstViewController.h"
#import "TCLoginParam.h"
#import "TCLoginModel.h"
#import "AppDelegate.h"

@interface TDLoginViewController ()<UITextFieldDelegate>
{
    TCLoginParam *_loginParam;
    
    UIView *_bgView;
    
    UITextField    *_accountTextField;  // 用户名/手机号
    UITextField    *_pwdTextField;      // 密码/验证码
    UIButton       *_loginBtn;          // 登录
    UIButton       *_regBtn;            // 注册
    
    UIView         *_lineView1;
    UIView         *_lineView2;
}
@end

@implementation TDLoginViewController

- (void)dealloc {
    if (_loginParam) {
        // 持久化param
        [_loginParam saveToLocal];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL isAutoLogin = [TCLoginModel isAutoLogin];
    if (isAutoLogin) {
        _loginParam = [TCLoginParam loadFromLocal];
    } else {
        _loginParam = [[TCLoginParam alloc] init];
    }
    
    //自动登陆前先初始化IMSDK，手动登陆在点击登陆时候初始化
    [[TCLoginModel sharedInstance] initIMSDK];
    
    if (isAutoLogin && [_loginParam isValid]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self autoLogin];
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //1、创建登陆界面
            [self createUI];
        });
    }
    
}

//自动登陆
- (void)autoLogin{
    if ([_loginParam isExpired]) {
        // 刷新票据
        //[[TLSHelper getInstance] TLSRefreshTicket:_loginParam.identifier andTLSRefreshTicketListener:self];
    }
    else {
        [self loginIMSDK];
    }

}

- (void)clickScreen {
    [_accountTextField resignFirstResponder];
    [_pwdTextField resignFirstResponder];
}

//创建UI
- (void)createUI{
    UITapGestureRecognizer *tag = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickScreen)];
    [self.view addGestureRecognizer:tag];
    
    UIImage *image = [UIImage imageNamed:@"loginBG.jpg"];
    self.view.layer.contents = (id)image.CGImage;
    
    //1、存放所有控件的背景view
    _bgView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, kScreenWidth, kScreenHeight)];
    _bgView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_bgView];
    
    _accountTextField = [[UITextField alloc] init];
    _accountTextField.font = [UIFont systemFontOfSize:14];
    _accountTextField.textColor = [UIColor colorWithWhite:1 alpha:1];
    _accountTextField.returnKeyType = UIReturnKeyDone;
    _accountTextField.delegate = self;
    
    _pwdTextField = [[UITextField alloc] init];
    _pwdTextField.font = [UIFont systemFontOfSize:14];
    _pwdTextField.textColor = [UIColor colorWithWhite:1 alpha:1];
    _pwdTextField.returnKeyType = UIReturnKeyDone;
    _pwdTextField.delegate = self;
    
    _lineView1 = [[UIView alloc] init];
    [_lineView1 setBackgroundColor:[UIColor whiteColor]];
    
    _lineView2 = [[UIView alloc] init];
    [_lineView2 setBackgroundColor:[UIColor whiteColor]];
    
    _loginBtn = [[UIButton alloc] init];
    _loginBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [_loginBtn setTitle:@"登录" forState:UIControlStateNormal];
    [_loginBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_loginBtn setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal];
    [_loginBtn setBackgroundImage:[UIImage imageNamed:@"button_pressed"] forState:UIControlStateSelected];
    [_loginBtn addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    
    _regBtn = [[UIButton alloc] init];
    _regBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [_regBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
    [_regBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    [_regBtn setTitle:@"注册新用户" forState:UIControlStateNormal];
    [_regBtn addTarget:self action:@selector(reg:) forControlEvents:UIControlEventTouchUpInside];
    
    [_bgView addSubview:_accountTextField];
    [_bgView addSubview:_lineView1];
    [_bgView addSubview:_pwdTextField];
    [_bgView addSubview:_lineView2];
    [_bgView addSubview:_loginBtn];
    [_bgView addSubview:_regBtn];
    
    [self relayout];
}

//添加约束
- (void)relayout {
    [_accountTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(30);
        make.top.equalTo(self.view.mas_top).offset(100);
        make.right.equalTo(self.view.mas_right).offset(-30);
        make.height.mas_equalTo(40);
    }];
    
    [_lineView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_accountTextField.mas_left);
        make.top.equalTo(_accountTextField.mas_bottom);
        make.width.equalTo(_accountTextField.mas_width);
        make.height.mas_equalTo(1);
    }];
    
    [_pwdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_accountTextField.mas_left);
        make.top.equalTo(_lineView1.mas_bottom);
        make.width.equalTo(_accountTextField.mas_width);
        make.height.equalTo(_accountTextField.mas_height);
    }];
    
    [_lineView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_accountTextField.mas_left);
        make.top.equalTo(_pwdTextField.mas_bottom);
        make.width.equalTo(_pwdTextField.mas_width);
        make.height.mas_equalTo(1);
    }];
    
    [_loginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_lineView2.mas_left);
        make.top.equalTo(_lineView2.mas_bottom).offset(40);
        make.width.equalTo(_lineView2.mas_width);
        make.height.mas_equalTo(30);
    }];
    
    [_regBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_loginBtn.mas_right);
        make.top.equalTo(_loginBtn.mas_bottom).offset(10);
        make.height.equalTo(_loginBtn.mas_height);
    }];
    
    [_accountTextField setPlaceholder:@"输入用户名"];
    [_accountTextField setText:@"lhy111"];
    _accountTextField.keyboardType = UIKeyboardTypeDefault;
    [_pwdTextField setPlaceholder:@"输入密码"];
    [_pwdTextField setText:@"123456"];
    
    _pwdTextField.secureTextEntry = YES;
    
    _accountTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_accountTextField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.5]}];
    _pwdTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_pwdTextField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.5]}];
}

#pragma mark - delegate<TCTLSLoginListener>
- (void)TLSUILoginOK:(TLSUserInfo *)userinfo {
    [self loginWith:userinfo];
}

- (void)loginWith:(TLSUserInfo *)userInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (userInfo) {
            _loginParam.identifier = userInfo.identifier;
            _loginParam.userSig = [[TLSHelper getInstance] getTLSUserSig:userInfo.identifier];
            _loginParam.tokenTime = [[NSDate date] timeIntervalSince1970];
            
            [self loginIMSDK];
        }
    });
}

#pragma mark - 登陆IMSDK
- (void)loginIMSDK {
    __weak TDLoginViewController *weakSelf = self;
    
    [[TCLoginModel sharedInstance] login:_loginParam succ:^{
        // 持久化param
        [_loginParam saveToLocal];
        // 进入主界面
        
        [[AppDelegate sharedAppDelegate] enterMainUI];
        
    } fail:^(int code, NSString *msg) {
        [weakSelf createUI];
    }];
}

#pragma mark - 点击事件
- (void)login:(UIButton *)button{
    NSString *userName = _accountTextField.text;
    if (userName == nil || [userName length] == 0) {
        [SVProgressHUD showWithStatus:@"用户名不能为空"];
        [SVProgressHUD dismissWithDelay:.8];
        return;
    }
    NSString *pwd = _pwdTextField.text;
    if (pwd == nil || [pwd length] == 0) {
        [SVProgressHUD showWithStatus:@"密码不能为空"];
        [SVProgressHUD dismissWithDelay:.8];
        return;
    }
    
    // 用户名密码登录
    __weak typeof(self) weakSelf = self;
    int ret = [[TCTLSPlatform sharedInstance] pwdLogin:userName andPassword:pwd succ:^(TLSUserInfo *userInfo) {
        id listener = weakSelf;
        [listener TLSUILoginOK:userInfo];
        
    } fail:^(TLSErrInfo *errInfo) {
        [SVProgressHUD showWithStatus:errInfo.sErrorMsg];
        [SVProgressHUD dismissWithDelay:.8];
        NSLog(@"%s %d %@", __func__, errInfo.dwErrorCode, errInfo.sExtraMsg);
    }];
    if (ret != 0) {
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%d", ret]];
        [SVProgressHUD dismissWithDelay:.8];
    }
}

- (void)reg:(UIButton *)button{
    TDRegisterViewController *registerVC = [[TDRegisterViewController alloc] init];
    [self.navigationController pushViewController:registerVC animated:YES];
}

#pragma mark - 刷新票据代理
- (void)OnRefreshTicketSuccess:(TLSUserInfo *)userInfo {
    NSLog(@"OnRefreshTicketSuccess");
    [self loginWith:userInfo];
}

- (void)OnRefreshTicketFail:(TLSErrInfo *)errInfo {
    NSLog(@"OnRefreshTicketFail");
    _loginParam.tokenTime = 0;
    [self createUI];
}

- (void)OnRefreshTicketTimeout:(TLSErrInfo *)errInfo {
    NSLog(@"OnRefreshTicketTimeout");
    [self OnRefreshTicketFail:errInfo];
}

@end
