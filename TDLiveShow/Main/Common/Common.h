//
//  Common.h
//  TDLiveShow
//
//  Created by TD on 2017/7/3.
//  Copyright © 2017年 TD. All rights reserved.
//

#ifndef Common_h
#define Common_h

//取得屏幕的宽、高
#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

// RGB颜色转换（16进制->10进制）
#define UIColorFromRGB(rgbValue)\
\
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 \
alpha:1.0]

//类别
#import "UIView+TDAdd.h"
#import "NSDictionary+TDAdd.h"

//宏
#import "TDConfigurationMacros.h"
#import "TDRequestAPI.h"
#import "TDNSUserDefaultMacrso.h"
#import "MJRefresh.h"

// SDK
#import "AFNetworking.h"
#import "MJExtension.h"
#import "SVProgressHUD.h"
#import <Masonry/Masonry.h>

//腾讯framework
#import "TCConstants.h"

//网络请求必用类别
#import "TDRequestModel.h"
#import "TDRequestAPI.h"
#import "TDNetworkManager.h"
#import "MD5And3DES.h"

#endif /* Common_h */
