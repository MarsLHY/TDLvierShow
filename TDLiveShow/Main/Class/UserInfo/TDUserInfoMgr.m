//
//  TDUserInfoMgr.m
//  TuanDaiLive
//
//  Created by TD on 2017/6/19.
//  Copyright © 2017年 tuandai. All rights reserved.
//

#import "TDUserInfoMgr.h"

static TDUserInfoMgr *_sharedInstance = nil;
@implementation TDUserInfoModel
- (instancetype)init{
    if (self == [super init]) {
        
    }
    return self;
}

+(NSDictionary *)mj_replacedKeyFromPropertyName
{
    // 实现这个方法的目的：告诉MJExtension框架模型中的属性名对应着字典的哪个key
    return @{
             @"descriptions" : @"description",
             };
}

@end


@interface TDUserInfoMgr()
{
    NSString *_identifier;
}
@end

@implementation TDUserInfoMgr

- (instancetype)init{
    if (self == [super init]) {

    
    }
    return self;
}

+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[TDUserInfoMgr alloc] init];
    });
    return _sharedInstance;
}

//存储用户信息
- (void)cacheUserInfo:(TDUserInfoModel *)userinfo{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:userinfo.age forKey:@"age"];
    [dic setObject:userinfo.descriptions forKey:@"descriptions"];
    [dic setObject:userinfo.district forKey:@"district"];
    [dic setObject:userinfo.head forKey:@"head"];
    [dic setObject:userinfo.nickname forKey:@"nickname"];
    [dic setObject:userinfo.sex forKey:@"sex"];
    [dic setObject:userinfo.user_id forKey:@"user_id"];
    [dic setObject:userinfo.xingzuo forKey:@"xingzuo"];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:dic forKey:UserInfoDic];
}

//从本地缓存加载用户信息
- (TDUserInfoModel *)loadCacheUserInfo{
    TDUserInfoModel *userInfo = [[TDUserInfoModel alloc] init];
    //从本地缓存获取用户信息
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [ud objectForKey:UserInfoDic];
    
    //赋值
    userInfo.age         = [dic objectForKey:@"age"];
    userInfo.descriptions = [dic objectForKey:@"descriptions"];
    userInfo.district    = [dic objectForKey:@"district"];
    userInfo.head        = [dic objectForKey:@"head"];
    userInfo.nickname    = [dic objectForKey:@"nickname"];
    userInfo.sex         = [dic objectForKey:@"sex"];
    userInfo.user_id     = [dic objectForKey:@"user_id"];
    userInfo.xingzuo     = [dic objectForKey:@"xingzuo"];
    
    return userInfo;
}

/**
 *  保存用户ID信息,并且注册回调通知,当收到登陆成功通知后拉取用户信息
 *  数据拉取成功后存入 userInfo  结构当中
 *
 *  @param identifier  用户ID信息
 */
- (void)setIdentifier:(NSString *)identifier
{
    _identifier = identifier;
    
    [self fetchUserInfo];
}

#pragma mark 从服务器上拉取信息
/**
 *  通过id信息从服务器上拉取用户信息
 */
-(void)fetchUserInfo
{
    DebugLog(@"开始通过用户id拉取用户资料信息");
    /*
    NSArray *arr = [NSArray arrayWithObject:_identifier];
    [[TIMFriendshipManager sharedInstance] GetUsersProfile:arr succ:^(NSArray *friends)
     {
         DebugLog(@"从服务器上拉取用户资料信息成功 count = %lu ", (unsigned long)friends.count);
         if (friends.count)
         {
             [self setUserProfile:friends[0]];
         }
     }
                                                      fail:^(int code, NSString *msg)
     {
         DebugLog(@"从服务器上拉取用户资料信息失败 errCode = %d, errMsg = %@", code, msg);
     }];
     */
}

@end

