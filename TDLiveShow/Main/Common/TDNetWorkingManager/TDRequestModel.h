//
//  TDRequestModel.h
//  TuanDaiV4
//
//  Created by AndreaArlex on 16/12/17.
//  Copyright © 2016年 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDDomainManager.h"

@interface TDRequestModel : NSObject

@property (nonatomic, strong) NSString *methodName;
@property (nonatomic, strong) NSDictionary *param;
/**
 * 1、团贷网请求渠道
   TDTuandaiSourceType,
 * 2、定期理财请求渠道
   TDRegularFinancialSourceType,
 * 3、业务运营
   TDOperationSourceType
 */
@property (nonatomic,assign)TDRequstSourceType requestType;  //请求类型

@end
