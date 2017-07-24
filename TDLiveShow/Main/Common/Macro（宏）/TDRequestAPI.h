//
//  TDRequestAPI.h
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#ifndef TDRequestAPI_h
#define TDRequestAPI_h

//系统配置appid与appkey 用于接口参数
#define TDAppid @"tuandai_ios"
#define TDAppkey @"Q&iGMFmekT%Zn&q*"

//密钥 3DES
#define _3DES_KEY @"i^FgWOB8IsN47zja^^&eSBup"
//偏移量
#define gIv             @"lhy"


//1、主播登录
#define push_login @"push/login"
//2、接入im获取签名
#define push_getUserSig @"push/get-user-signature"
//3、开始直播
#define push_starPush @"push/start"
//4、结束直播
#define push_endPush @"push/stop"
//5、礼物列表
#define giftList @"live/get-present-list"

#endif /* TDRequestAPI_h */
