//
//  TCPusherModel.m
//  TCLVBIMDemo
//
//  Created by felixlin on 16/8/2.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCPusherModel.h"
#import "ImSDK/TIMGroupManager.h"
#import "TCUtil.h"

@implementation TCPusherModel

static TCPusherModel *_sharedInstance = nil;


+ (instancetype)sharedInstance
{
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _sharedInstance = [[TCPusherModel alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
    }
    return self;
}



- (void)getPusherUrl:(NSString *)userId groupId:(NSString*)groupId title:(NSString *)title coverPic:(NSString *)coverPic nickName:(NSString *)nickName headPic:(NSString *)headPic location:(NSString *)location handler:(RequestPusherUrlHandler)handler
{
    self.userId = userId;
    
    //从业务server申请推流地址
    NSDictionary* dictUser = @{@"nickname" : TC_PROTECT_STR(nickName), @"headpic" : TC_PROTECT_STR(headPic), @"frontcover" : TC_PROTECT_STR(coverPic), @"location" : TC_PROTECT_STR(location)};
    NSDictionary* dictParam = @{@"Action" : @"RequestLVBAddr", @"userid" : TC_PROTECT_STR(userId), @"groupid" : TC_PROTECT_STR(groupId), @"title" : TC_PROTECT_STR(title), @"userinfo" : dictUser};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        if (result != 0)
        {
            handler(result, nil, 0);
        }
        else
        {
            NSString* pusherUrl = nil;
            NSInteger timestamp = 0;
            if (resultDict)
            {
                pusherUrl = resultDict[@"pushurl"];
                if ([resultDict[@"timestamp"] isKindOfClass:[NSNumber class]]) {
                    timestamp = [resultDict[@"timestamp"] integerValue];
                }
            }
            handler(result, pusherUrl, timestamp);
        }
    }];
}


- (void) getPushUrlForLinkMic:(NSString*)userId title:(NSString*)title coverPic:(NSString*)coverPic nickName:(NSString*)nickName headPic:(NSString*)headPic location:(NSString*)location handler:(RequestLinkMicPusherUrlHandler)handler {
    self.userId = userId;
    
    //从业务server申请推流地址
    NSDictionary* dictUser = @{@"nickname" : TC_PROTECT_STR(nickName), @"headpic" : TC_PROTECT_STR(headPic), @"frontcover" : TC_PROTECT_STR(coverPic), @"location" : TC_PROTECT_STR(location)};
    NSDictionary* dictParam = @{@"Action" : @"RequestLVBAddrForLinkMic", @"userid" : TC_PROTECT_STR(userId), @"title" : TC_PROTECT_STR(title), @"userinfo" : dictUser};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        if (result != 0)
        {
            handler(result, nil, 0, nil);
        }
        else
        {
            NSString* pusherUrl = nil;
            NSString* playUrl = nil;
            NSInteger timestamp = 0;
            if (resultDict)
            {
                pusherUrl = resultDict[@"pushurl"];
                playUrl = resultDict[@"playurl"];
                if ([resultDict[@"timestamp"] isKindOfClass:[NSNumber class]]) {
                    timestamp = [resultDict[@"timestamp"] integerValue];
                }
            }
            handler(result, pusherUrl, timestamp, playUrl);
        }
    }];
}


- (void) changeLiveStatus:(NSString*)userId status:(TCLiveStatus)status handler:(PusherMgrCompleteHandler)handler
{
    if (userId == nil)
    {
        DebugLog(@"changeLiveStatus failed，userid 为空");
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(kError_InvalidParam);
        });
        return;
    }
    
    NSDictionary* dictParam = @{@"Action" : @"ChangeStatus", @"userid" : TC_PROTECT_STR(userId), @"status" : @(status)};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        handler(result);
    }];
}

@end
