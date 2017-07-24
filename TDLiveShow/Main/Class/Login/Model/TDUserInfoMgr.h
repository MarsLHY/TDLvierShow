//
//  TDUserInfoMgr.h
//  TuanDaiLive
//
//  Created by TD on 2017/6/19.
//  Copyright © 2017年 tuandai. All rights reserved.
//

#import <Foundation/Foundation.h>

//缓存用户信息的modle
@interface TDUserInfoModel : NSObject
{
    
}
@property (nonatomic,copy) NSString *age;
@property (nonatomic,copy) NSString *descriptions;
@property (nonatomic,copy) NSString *district;
@property (nonatomic,copy) NSString *head;
@property (nonatomic,copy) NSString *nickname;
@property (nonatomic,copy) NSString *sex;
@property (nonatomic,copy) NSString *user_id;
@property (nonatomic,copy) NSString *xingzuo;

@end

@interface TDUserInfoMgr : NSObject

+ (instancetype)sharedInstance;

//缓存服务器获取的用户信息
- (void)cacheUserInfo:(TDUserInfoModel *)userinfo;

//从本地加载用户信息
- (TDUserInfoModel *)loadCacheUserInfo;

@end
