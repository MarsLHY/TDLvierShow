//
//  TDLoginModel.h
//  TDLiveShow
//
//  Created by TD on 2017/7/19.
//  Copyright © 2017年 TD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImSDK/ImSDK.h"
/**
 *  ImSDK登录相关接口封装
 */
@interface TDLoginModel : NSObject<TIMUserStatusListener>

+ (instancetype)sharedInstance;

//初始化IMSDK
- (void)initIMSDK;

//登陆IMSDK，调用该接口前需要先完成TLS登陆
- (void)login:(TIMLoginParam *)param succ:(TIMLoginSucc)succ fail:(TIMFail)fail;

//退出IMSDK
- (void)logout:(TIMLoginSucc)succ fail:(TIMFail)fail;

//注册

@end
