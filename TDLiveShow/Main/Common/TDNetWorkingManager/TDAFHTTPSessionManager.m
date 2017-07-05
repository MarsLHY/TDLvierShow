//
//  TDAFHTTPSessionManager.m
//  TuanDaiV4
//
//  Created by WuSiJun on 16/8/17.
//  Copyright © 2016年 Dee. All rights reserved.
//

#import "TDAFHTTPSessionManager.h"

@implementation TDAFHTTPSessionManager

+ (instancetype)manager {

    static TDAFHTTPSessionManager *sharedManager;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initWithBaseURL:nil];
    });

    return sharedManager;
}

@end
