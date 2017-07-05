//
//  TCLoginModel.h
//  TCLVBIMDemo
//
//  Created by dackli on 16/8/3.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImSDK/ImSDK.h"
#import "ImSDK/TIMComm.h"
#import "ImSDK/TIMCallback.h"
#import "TLSSDK/TLSRefreshTicketListener.h"
#ifndef APP_EXT
#import "TCLoginModel.h"
#endif

#define  logoutNotification  @"logoutNotification"

#import <Foundation/Foundation.h>
#import "TLSSDK/TLSPwdLoginListener.h"
#import "TLSSDK/TLSSmsLoginListener.h"
#import "TLSSDK/TLSGuestLoginListener.h"
#import "TLSSDK/TLSStrAccountRegListener.h"
#import "TLSSDK/TLSUserInfo.h"
#import "TLSSDK/TLSErrInfo.h"
#import "TLSSDK/TLSHelper.h"

typedef void (^TLSSucc)(TLSUserInfo *userInfo);
typedef void (^TLSFail)(TLSErrInfo *errInfo);

/**
 *  TLS注册登录相关接口封装
 *  在TLS注册/登录前 必须先初始化IMSDK：[[TCLoginModel sharedInstance] initIMSDK];
 */
@interface TCTLSPlatform : NSObject <TLSPwdLoginListener, TLSGuestLoginListener, TLSStrAccountRegListener>

+ (instancetype)sharedInstance;

/**  用户名密码注册
 *   返回值：0：接口调用成功
 *         非0：内部错误
 */
- (int)pwdRegister:(NSString *)identifier andPassword:(NSString *)password succ:(TLSSucc)succ fail:(TLSFail)fail;

/**  用户名密码登录
 *   返回值：0：接口调用成功
 *         非0：内部错误
 */
- (int)pwdLogin:(NSString *)identifier andPassword:(NSString *)password succ:(TLSSucc)succ fail:(TLSFail)fail;

/**  游客登录
 *   返回值：0：接口调用成功
 *         非0：内部错误
 */
- (int)guestLogin:(TLSSucc)succ fail:(TLSFail)fail;



@end

@protocol TCTLSLoginListener <NSObject>

/**
 *  TLS帐号登录成功
 *
 *  @param userinfo 登录成功的用户
 */
- (void)TLSUILoginOK:(TLSUserInfo *)userinfo;

@end

/**
 *  ImSDK登录相关接口封装
 */
@interface TCLoginModel : NSObject <TIMUserStatusListener, TLSRefreshTicketListener, TIMGroupAssistantListener>

+ (instancetype)sharedInstance;

+ (BOOL)isAutoLogin;

+ (void)setAutoLogin:(BOOL)autoLogin;

// 初始化IMSDK，传入appid等信息
- (void)initIMSDK;

#ifndef APP_EXT
// 游客登录，调用该接口后可以直接进行IM通信（内部已经完成TLS账号注册登录以及IM登录）
- (void)guestLogin:(TLSSucc)succ fail:(TLSFail)fail;
#endif

// 登录IMSDK，调用该接口前需要先完成TLS登录
- (void)login:(TIMLoginParam *)param succ:(TIMLoginSucc)succ fail:(TIMFail)fail;

// 退出IMSDK
- (void)logout:(TIMLoginSucc)succ fail:(TIMFail)fail;

// 获取login传入的login param参数
- (TIMLoginParam *)getLoginParam;

- (void)onForceOfflineAlert;

- (void)reLogin:(TIMLoginSucc)succ fail:(TIMFail)fail;

@end
