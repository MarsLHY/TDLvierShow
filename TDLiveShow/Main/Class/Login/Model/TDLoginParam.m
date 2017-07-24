//
//  TDLoginParam.m
//  TDLiveShow
//
//  Created by TD on 2017/7/19.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "TDLoginParam.h"

@implementation TDLoginParam

- (instancetype)init{
    if (self==[super init]) {
        self.appidAt3rd = kTCIMSDKAppId;
        self.sdkAppId = [kTCIMSDKAppId intValue];
        self.accountType = kTCIMSDKAccountType;
    }
    return self;
}

+ (instancetype)loadFromLocal {
    
    return [[TDLoginParam alloc] init];
}

- (void)saveToLocal{

}

@end
