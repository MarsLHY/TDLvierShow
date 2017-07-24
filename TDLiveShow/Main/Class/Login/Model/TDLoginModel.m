//
//  TDLoginModel.m
//  TDLiveShow
//
//  Created by TD on 2017/7/19.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "TDLoginModel.h"
#import "ImSDK/TIMManager.h"
#import "AppDelegate.h"


#define kEachKickErrorCode    6208   //互踢下线错误码

@interface TDLoginModel()
{
    TIMLoginParam *_loginParam;
}
@end

@implementation TDLoginModel

+ (instancetype)sharedInstance{
    static TDLoginModel *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[TDLoginModel alloc] init];
    });
    return _sharedInstance;
}

- (void)initIMSDK{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //设置腾讯优先级
        [[TIMManager sharedInstance] setLogLevel:TIM_LOG_ERROR];
        [[TIMManager sharedInstance] setEnv:0]; //0:正式环境 1：测试环境
        [[TIMManager sharedInstance] setUserStatusListener:self];
        [[TIMManager sharedInstance] initSdk:[kTCIMSDKAppId intValue] accountType:kTCIMSDKAccountType];
    });
}

//登陆
- (void)login:(TIMLoginParam *)param succ:(TIMLoginSucc)succ fail:(TIMFail)fail{
    if (!param) {
        return;
    }
    
    //检测网络状态，如果不通直接跳转登录页面
    if ([[TIMManager sharedInstance] networkStatus] == TIM_NETWORK_STATUS_DISCONNECTED) {
        if (fail) {
            dispatch_async(dispatch_get_main_queue(), ^{
                fail(-20001,@"网络超时,请重试");
            });
        }
        return;
    }
    
    _loginParam = param;
    __weak TDLoginModel *weakSelf = self;
    [[TIMManager sharedInstance] login:param succ:^{
        //1、登录成功拉去用户资料存储
        
        //
        if (succ) {
            succ();
        }
    } fail:^(int code, NSString *msg) {
#ifdef APP_EXT
        if (fail) {
            fail(code, msg);
        }
#else
        if (code == kEachKickErrorCode) {
            [weakSelf offlineKicked:param succ:succ fail:fail];
        }
        else {
            if (fail) {
                fail(code, msg);
            }
        }
#endif
    }];
}

//退出登录
- (void)logout:(TIMLoginSucc)succ fail:(TIMFail)fail{
    __weak TDLoginModel *weakSelf = self;
    
    [[TIMManager sharedInstance] logout:^{
        if (succ) {
            succ();
        }
    } fail:^(int code, NSString *msg) {
        if (fail) {
            fail(code, msg);
        }
    }];
}

//离线被踢
//用户离线时，在其它终端登录过，再次在本设备登录时，会提示被踢下线，需要重新登录
- (void)offlineKicked:(TIMLoginParam *)param succ:(TIMLoginSucc)succ fail:(TIMFail)fail {

}

@end
