//
//  TDNetworkManager.m
//  TuanDaiLive
//
//  Created by tuandai on 2017/5/12.
//  Copyright © 2017年 tuandai. All rights reserved.
//

#import "TDNetworkManager.h"
#import "TDDomainManager.h"
#import "TDAFHTTPSessionManager.h"

@implementation TDNetworkManager

/**
 *  @author AndreaArlex, 16-03-10 16:03:50
 *
 *  单例
 *
 *  @return 本类对象
 */
+ (instancetype)sharedInstane {
    
    static TDNetworkManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[TDNetworkManager alloc] init];
    });
    
    return manager;
}



//发起post请求
- (void)postRequestWithRequestModel:(TDRequestModel *)requestModel callBack:(responeModelCallBack)callBack {
    [self requestWithSourceType:requestModel.requestType
                   RequestModel:requestModel
                       callBack:^(TDResponeModel *responeModel) {
                    if (callBack) {
                        callBack(responeModel);
                    }
    }];
    
    
}

- (void)requestWithSourceType:(TDRequstSourceType)type RequestModel:(TDRequestModel *)requestModel callBack:(responeModelCallBack)callBack{
    NSDictionary *dict = [self getMustParamRequestModel:requestModel];
    NSString *domainPath = [TDDomainManager domainWithMethodName:requestModel.methodName requestSourceType:type];
    NSURLSessionDataTask *postTask = [self postRequestWithPath:domainPath parameter:dict whenSuccessed:^(id json) {
        if (callBack) {
            TDResponeModel *responeModel = [[TDResponeModel alloc] init];
            responeModel.code = [json td_IntegerForKey:@"ResultCode"];
            responeModel.responeData = [json td_ObjectForKey:@"Data"];
            responeModel.message = [json td_StringForKey:@"ResultMsg"];
            
            if (responeModel.code != 1) {
                responeModel.errorType = ServerErrorType;
            }
            callBack(responeModel);
        }
        
    } whenFailed:^(NSError *error) {
        //新框架使用的模型回调
        if (callBack) {
            TDResponeModel *responeModel = [[TDResponeModel alloc] init];
            responeModel.code = error.code;
            responeModel.errorType = NetworkErrorType;
            responeModel.message = @"当前网络异常，请稍后重试";
            callBack(responeModel);
        }
    }];
    
    if (requestModel.methodName.length > 0) {
        postTask.taskDescription = requestModel.methodName;
    }
}


/**
 *  @author AndreaArlex, 16-03-10 14:03:56
 *
 *  Post请求任务
 *
 *  @param path           post的路径
 *  @param parameter      post的参数
 *  @param successedBlock 成功后的处理
 *  @param failedBlock    失败后的处理
 *
 *  @return post任务对象
 */
- (NSURLSessionDataTask *)postRequestWithPath:(NSString*)path
                                    parameter:(NSDictionary*)parameter
                                whenSuccessed:(TDNetworkingSuccessed)successedBlock
                                   whenFailed:(TDNetworkingFailed)failedBlock {
    TDAFHTTPSessionManager *manager = [TDAFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 10; //超时设置10秒
    manager.requestSerializer.cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    NSURLSessionDataTask *task = [manager POST:path parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (successedBlock) {
        
            successedBlock(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failedBlock) {
            
            failedBlock(error);
        }
    }];
    
    return task;
    
}


// 添加服务器必要的参数
- (NSDictionary *)getMustParamRequestModel:(TDRequestModel *)requestModel {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:requestModel.param];
    
    return dict;
}

@end
