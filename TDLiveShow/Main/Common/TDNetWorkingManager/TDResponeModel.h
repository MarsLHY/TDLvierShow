//
//  TDResponeModel.h
//  TuanDaiV4
//
//  Created by AndreaArlex on 16/12/17.
//  Copyright © 2016年 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ErrorType) {
    NormalType = 0, //正常
    ServerErrorType = -2, //服务器异常
    NetworkErrorType = -1, //网络异常
};

@interface TDResponeModel : NSObject

@property (nonatomic, assign) NSInteger code;
@property (nonatomic, strong) id responeData;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) ErrorType errorType;

@end
