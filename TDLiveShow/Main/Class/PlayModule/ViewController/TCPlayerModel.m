//
//  TCPlayerModel.m
//  TCLVBIMDemo
//
//  Created by felixlin on 16/8/3.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCPlayerModel.h"
#import "ImSDK/TIMGroupManager.h"
#import "TCUtil.h"
#import <MJExtension/MJExtension.h>

@implementation TCGroupMemberInfo

@end

@implementation TCPlayerModel

static TCPlayerModel *_sharedInstance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _sharedInstance = [[TCPlayerModel alloc] init];
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

- (void)giveLike:(NSString*)userId handler:(PlayerMgrCompleteHandler)handler
{
    [self internalSendRequest:userId type:1 optype:0 flag:0 fileid:nil handler:handler];
}

- (void)getUserInfo:(TCLiveListItemType)type userId:(NSString *)userId fileId:(NSString *)fileId handler:(GetUserInfoHandler)handler
{
    NSDictionary* dictParam = @{@"Action" : @"GetUserInfo", @"userid" : TC_PROTECT_STR(userId), @"type" : @(type), @"fileid" : TC_PROTECT_STR(fileId)};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        if (0 != result)
        {
            handler(result, nil);
        }
        else
        {
            TCLiveInfo* info = [TCLiveInfo mj_objectWithKeyValues:resultDict];
            handler(result, info);
        }
    }];
}

- (void)reportUser:(NSString *)userId hostUserId:(NSString *)hostUserId handler:(PlayerMgrCompleteHandler)handler
{
    NSDictionary* dictParam = @{@"Action" : @"ReportUser", @"userid" : TC_PROTECT_STR(userId), @"hostuserid" : TC_PROTECT_STR(hostUserId)};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        handler(result);
    }];
}

- (void)internalSendRequest:(NSString*)userId type:(int)type optype:(int)optype flag:(int)flag fileid:(NSString*)fileId handler:(PlayerMgrCompleteHandler)handler
{
    NSDictionary* dictParam = @{@"Action" : @"ChangeCount", @"userid" : TC_PROTECT_STR(userId), @"type" : @(type), @"optype" : @(optype), @"flag" : @(flag), @"fileid" : TC_PROTECT_STR(fileId)};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        handler(result);
    }];
}

- (void)enterGroup:(NSString*)userId type:(int)type liveUserId:(NSString*)liveUserId groupId:(NSString*)groupId nickName:(NSString*)nickName headPic:(NSString*)headPic handler:(PlayerMgrCompleteHandler)handler
{
    NSDictionary* dictParam = @{@"Action" : @"EnterGroup", @"userid" : TC_PROTECT_STR(userId), @"flag" : @(type), @"liveuserid" : TC_PROTECT_STR(liveUserId), @"groupid" : TC_PROTECT_STR(groupId), @"nickname" : TC_PROTECT_STR(nickName), @"headpic" : TC_PROTECT_STR(headPic)};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        DebugLog(@"TCPlayerModel, notify enter group result:%d", result);
        handler(result);
    }];
}

- (void)quitGroup:(NSString *)userId type:(int)type liveUserId:(NSString *)liveUserId groupId:(NSString *)groupId handler:(PlayerMgrCompleteHandler)handler
{
    NSDictionary* dictParam = @{@"Action" : @"QuitGroup", @"userid" : TC_PROTECT_STR(userId), @"flag" : @(type), @"liveuserid" : TC_PROTECT_STR(liveUserId), @"groupid" : TC_PROTECT_STR(groupId)};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        DebugLog(@"TCPlayerModel, notify quit group result:%d", result);
        handler(result);
    }];
}

- (void)fetchGroupMemberList:(NSString *)liveUserId groupId:(NSString *)groupId handler:(void (^)(int, int, NSArray *))handler
{
    NSDictionary* dictParam = @{@"Action" : @"FetchGroupMemberList", @"liveuserid" : TC_PROTECT_STR(liveUserId), @"groupid" : TC_PROTECT_STR(groupId), @"pageno" : @1, @"pagesize" : @20};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        NSArray* memList = nil;
        int memCount = 0;
        if (0 == result)
        {
            memCount = [resultDict[@"totalcount"] intValue];
            if (memCount > 0)
            {
                memList = [TCGroupMemberInfo mj_objectArrayWithKeyValuesArray:resultDict[@"memberlist"]];
            }
        }
        DebugLog(@"TCPlayerModel, fetch group memberlist result:%d, count:%d", result, memCount);
        handler(result, memCount, memList);
    }];
}

- (void)getPlayUrlWithSignature: (NSString*)userID originPlayUrl:(NSString*) strPlayUrl handler:(GetPlayUrlWithSignatureHandler)handler {
    NSDictionary* dictParam = @{@"Action" : @"RequestPlayUrlWithSignForLinkMic", @"userid" : TC_PROTECT_STR(userID), @"originStreamUrl" : TC_PROTECT_STR(strPlayUrl)};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        DebugLog(@"TCPlayerModel, getPlayUrlWithSignature result:%d", result);
        if (resultDict) {
            handler(result, resultDict[@"streamUrlWithSignature"]);
        }
        else {
            handler(-1, nil);
        }
    }];
}
@end
