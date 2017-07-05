//
//  TDDomainManager.h
//  TuanDaiV4
//
//  Created by AndreaArlex on 16/11/10.
//  Copyright © 2016年 Dee. All rights reserved.
//

typedef NS_ENUM(NSUInteger, TDRequstSourceType) {
    
    //团贷网请求渠道（直播）
    TDTuandaiSourceType,
    
    //
    TDRegularFinancialSourceType,
    
    //
    TDOperationSourceType
};

#import <Foundation/Foundation.h>
@interface TDDomainManager : NSObject



/**
 域名选择

 @param methodName        请求的方法名称
 @param requestSourceType 请求的来源

 @return 域名
 */
+ (NSString *)domainWithMethodName:(NSString *)methodName
                 requestSourceType:(TDRequstSourceType)requestSourceType;


/**
 此域名时  请求失败

 @param type 请求的来源
 */
//+(void)domainConnectFailWithSourceType:(TDRequstSourceType)type methodName:(NSString *)name;
@end
