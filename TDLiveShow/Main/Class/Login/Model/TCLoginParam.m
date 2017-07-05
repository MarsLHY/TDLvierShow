//
//  TCLoginParam.m
//  TCLVBIMDemo
//
//  Created by dackli on 16/8/4.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCLoginParam.h"
#import "TCUtil.h"
#import "TCConstants.h"

@implementation TCLoginParam

#define kIMLoginParamKey     @"kIMLoginParamKey"

- (instancetype)init {
    if (self = [super init]) {
        self.appidAt3rd = kTCIMSDKAppId;
        self.sdkAppId = [kTCIMSDKAppId intValue];
        self.accountType = kTCIMSDKAccountType;
    }
    return self;
}

+ (instancetype)loadFromLocal {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    if (defaults == nil) {
        defaults = [NSUserDefaults standardUserDefaults];
    }
    NSString *useridKey = [defaults objectForKey:kIMLoginParamKey];
    if (useridKey) {
        NSString *strLoginParam = [defaults objectForKey:useridKey];
        NSDictionary *dic = [TCUtil jsonData2Dictionary: strLoginParam];
        if (dic) {
            TCLoginParam *param = [[TCLoginParam alloc] init];
            param.tokenTime = [[dic objectForKey:@"tokenTime"] longValue];
            param.accountType = [dic objectForKey:@"accountType"];
            param.identifier = [dic objectForKey:@"identifier"];
            param.userSig = [dic objectForKey:@"userSig"];
            param.appidAt3rd = [dic objectForKey:@"appidAt3rd"];
            param.sdkAppId = [[dic objectForKey:@"sdkAppId"] intValue];
            param.isLastAppExt = [[dic objectForKey:@"isLastAppExt"] intValue];
            
            // 可能存在没有卸载却更换了appid的情况
            if (param.sdkAppId != [kTCIMSDKAppId intValue]) {
                return [[TCLoginParam alloc] init];
            } else {
                return param;
            }
        }
    }
    
    return [[TCLoginParam alloc] init];
}

- (void)saveToLocal {
    if (self.tokenTime == 0) {
        self.tokenTime = [[NSDate date] timeIntervalSince1970];
    }
    
    if (![self isValid]) {
        return;
    }
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    [dic setObject:@(self.tokenTime) forKey:@"tokenTime"];
    [dic setObject:self.accountType forKey:@"accountType"];
    [dic setObject:self.identifier forKey:@"identifier"];
    [dic setObject:self.userSig forKey:@"userSig"];
    [dic setObject:self.appidAt3rd forKey:@"appidAt3rd"];
    [dic setObject:@(self.sdkAppId) forKey:@"sdkAppId"];
#if APP_EXT
    [dic setObject:@(1) forKey:@"isLastAppExt"];
#else
    [dic setObject:@(0) forKey:@"isLastAppExt"];
#endif
    
    NSData *data = [TCUtil dictionary2JsonData: dic];
    NSString *strLoginParam = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *useridKey = [NSString stringWithFormat:@"%@_LoginParam", self.identifier];
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    if (defaults == nil) {
        defaults = [NSUserDefaults standardUserDefaults];
    }
    
    [defaults setObject:useridKey forKey:kIMLoginParamKey];
    
    // save login param
    [defaults setObject:strLoginParam forKey:useridKey];
    [defaults synchronize];
}

- (BOOL)isExpired {
    time_t curTime = [[NSDate date] timeIntervalSince1970];
    if (curTime - self.tokenTime > 10 * 24 * 3600) {
        return YES;
    }
    return NO;
}

- (BOOL)isValid {
    if (self.identifier == nil || self.identifier.length == 0) {
        return NO;
    }
    if (self.userSig == nil || self.userSig.length == 0) {
        return NO;
    }
    if ([self isExpired]) {
        return NO;
    }
    return YES;
}

@end
