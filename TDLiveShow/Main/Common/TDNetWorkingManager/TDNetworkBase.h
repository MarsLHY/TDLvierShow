//
//  TDNetworkingHelper2.h
//  TuanDaiV4
//
//  Created by Arlexovincy on 16/3/10.
//  Copyright © 2016年 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TDResponeModel;

typedef void (^TDNetworkingSuccessed)(id json);
typedef void (^TDNetworkingFailed)(NSError *error);

@interface TDNetworkBase : NSObject

/**
 *  @author AndreaArlex, 16-03-10 14:03:00
 *
 *  单例
 *
 *  @return 本类对象
 */
+ (instancetype)sharedInstane;


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
                                   whenFailed:(TDNetworkingFailed)failedBlock;

/**
 *  @author AndreaArlex, 16-09-19 09:09:57
 *
 *  上传图片
 *
 *  @param imageArray     图片内容 UIImage
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
                           whenFailed:(TDNetworkingFailed)failedBlock;

/**
 *  @author AndreaArlex, 16-03-10 14:03:25
 *
 *  取消在请求队列中的请求
 *
 *  @param operationMethodString 被取消的方法
 */
- (void)cancelOpeartionFromMethod:(NSString*)operationMethodString;


/**
 AF同步请求方法实现

 @param path           请求路径
 @param parameter      请求参数
 @param successedBlock 成功的处理
 @param failedBlock    失败的处理

 @return post任务对象
 */
- (void)synchronousPostWithPath:(NSString *)path
                      parameter:(NSDictionary *)parameter
                  whenSuccessed:(TDNetworkingSuccessed)successedBlock
                     whenFailed:(TDNetworkingFailed)failedBlock;
@end
