//
//  TCLoginParam.h
//  TCLVBIMDemo
//
//  Created by dackli on 16/8/4.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImSDK/ImSDK.h"

/**
 *  用来管理用户的登录信息，如登录信息的缓存、过期判断等
 */
@interface TCLoginParam : TIMLoginParam

@property (nonatomic, assign) NSInteger tokenTime;
@property (nonatomic, assign) BOOL      isLastAppExt;

+ (instancetype)loadFromLocal;

- (void)saveToLocal;

- (BOOL)isExpired;

- (BOOL)isValid;

@end
