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

typedef void (^TDUserInfoSaveHandle)(int errCode,NSString *strMsg);

@interface TDUserInfoMgr : NSObject

+ (instancetype)sharedInstance;

//根据ID从服务器获取用户信息
- (void)setIdentifier:(NSString *)identifier;

//缓存服务器获取的用户信息
- (void)cacheUserInfo:(TDUserInfoModel *)userinfo;

//从本地加载用户信息
- (TDUserInfoModel *)loadCacheUserInfo;

//以下为更新个人信息接口(暂无接口、未实现)
- (void)saveUserCover:(NSString*)IMUserCover handler:(TDUserInfoSaveHandle)handle;

- (void)saveUserNickName:(NSString*)nickName handler:(TDUserInfoSaveHandle)handle;

- (void)saveUserFace:(NSString*)faceURL handler:(TDUserInfoSaveHandle)handle;

- (void)saveUserGender:(int)sex handler:(TDUserInfoSaveHandle)handle;

@end
