//
//  TDLoginParam.h
//  TDLiveShow
//
//  Created by TD on 2017/7/19.
//  Copyright © 2017年 TD. All rights reserved.
//

#import <ImSDK/ImSDK.h>

@interface TDLoginParam : TIMLoginParam

@property (nonatomic, assign) NSInteger tokenTime;

+ (instancetype)loadFromLocal;

- (void)saveToLocal;


@end
