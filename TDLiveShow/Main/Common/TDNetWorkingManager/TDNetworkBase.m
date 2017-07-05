
//
//  TDNetworkingHelper2.m
//  TuanDaiV4
//
//  Created by Arlexovincy on 16/3/10.
//  Copyright © 2016年 Dee. All rights reserved.
//

#import "TDNetworkBase.h"
#import "TDAFHTTPSessionManager.h"

@implementation TDNetworkBase

#pragma mark- public methord
/**
 *  @author AndreaArlex, 16-03-10 14:03:00
 *
 *  单例
 *
 *  @return 本类对象
 */
+ (instancetype)sharedInstane {

    static TDNetworkBase *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[TDNetworkBase alloc] init];
        
    });
    
    return manager;
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

/**
 *  @author AndreaArlex, 16-09-19 09:09:57
 *
 *  上传图片
 *
 *  @param imageArray     图片内容 NSData
 *  @param path           上传路径
 *  @param parameter      上传参数
 *  @param successedBlock 成功的处理
 *  @param failedBlock    失败的处理
 *
 *  @return 上传的任务对象
 */
- (NSURLSessionDataTask *)uploadImage:(NSArray *)imageArray
                                 path:(NSString*)path
                            parameter:(NSDictionary*)parameter
                        whenSuccessed:(TDNetworkingSuccessed)successedBlock
                           whenFailed:(TDNetworkingFailed)failedBlock {
    TDAFHTTPSessionManager *manager = [TDAFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://bbs5.tuandai.com/mobile/index.html#!/home"]];
    
    NSHTTPCookieStorage *storage = [[NSHTTPCookieStorage alloc] init];
    
    for (NSHTTPCookie *cookie in cookies) {
        
        if ([cookie.domain isEqualToString:@".tuandai.com"]) {
            
            [storage setCookie:cookie];
        }
        
        
    }
    
    manager.session.configuration.HTTPShouldSetCookies = YES;
    manager.session.configuration.HTTPCookieStorage = storage;
    
    NSURLSessionDataTask *task = [manager POST:path parameters:parameter constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (UIImage *image in imageArray) {
            
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssms";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString stringWithFormat:@"%@.jpg", str];
            
            [formData appendPartWithFileData:imageData name:@"Filedata" fileName:fileName mimeType:@"image/jpeg"];
        }
        
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
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

- (void)synchronousPostWithPath:(NSString *)path
                      parameter:(NSDictionary *)parameter
                  whenSuccessed:(TDNetworkingSuccessed)successedBlock
                     whenFailed:(TDNetworkingFailed)failedBlock {
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:6];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameter options:NSJSONWritingPrettyPrinted error:nil]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error && successedBlock) {
            successedBlock([data mj_JSONObject]);
        }else {
            if (error) {
                failedBlock(error);
            }
        }
    }] resume];
}



/**
 *  @author AndreaArlex, 16-03-10 14:03:25
 *
 *  取消在请求队列中的请求
 *
 *  @param operationMethodString 被取消的方法
 */
- (void)cancelOpeartionFromMethod:(NSString*)operationMethodString {

     //有待思考
    NSArray *taskArray = [TDAFHTTPSessionManager manager].tasks;

    for (NSURLSessionDataTask *task in taskArray) {

        if ([task.taskDescription isEqualToString:operationMethodString]) {

            [task cancel];
        }
    }
}

@end
