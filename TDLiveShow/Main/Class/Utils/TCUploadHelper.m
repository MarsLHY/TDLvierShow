//
//  UploadImageHelper.m
//  TCLVBIMDemo
//
//  Created by felixlin on 16/8/2.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCUploadHelper.h"
#import "TCUtil.h"
#import <TXRTMPSDK/COSTask.h>
#import <TXRTMPSDK/COSClient.h>

@interface TCUploadHelper ()
{
    COSClient*                       _cosClient;
}

@end

@implementation TCUploadHelper


static TCUploadHelper *_shareInstance = nil;

+ (instancetype)shareInstance
{
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        _shareInstance = [[TCUploadHelper alloc] init];
    });
    return _shareInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _cosClient = [[COSClient alloc] initWithAppId:kTCCOSAppId withRegion:kTCCOSRegion];
        [_cosClient openHTTPSrequset:YES];
    }
    return self;
}

- (void)upload:(NSString*)userId image:(UIImage *)image completion:(void (^)(int errCode, NSString *imageSaveUrl))completion
{
    if (!image)
    {
        if (completion)
        {
            completion(-30001, nil);
        }
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *imageData = UIImageJPEGRepresentation(image, 0.3);
        
        // 以时间戳为文件名(毫秒为单位，跟Android保持一致)
        NSString *photoName = [[NSString alloc] initWithFormat:@"%.f", [[NSDate date] timeIntervalSince1970] * 1000];
        NSString *pathSave = [TCUtil getFileCachePath:photoName];
        
        BOOL succ = [imageData writeToFile:pathSave atomically:YES];
        if (succ)
        {
            //获取sign
            
            [self getCOSSign:^(int errCode, NSString *strSign) {
                if (0 == errCode)
                {
                    NSString *dire = [NSString stringWithFormat:@"/%@", userId];
                    COSObjectPutTask *task = [[COSObjectPutTask alloc] initWithPath:pathSave sign:strSign bucket:kTCCOSBucket fileName:photoName customAttribute:@".png" uploadDirectory:dire insertOnly:YES];
                    
                    _cosClient.completionHandler = ^(COSTaskRsp *resp, NSDictionary *context){
                        COSObjectUploadTaskRsp *taskResp = (COSObjectUploadTaskRsp *)resp;
                        if (taskResp != nil && taskResp.httpsURL.length)
                        {
                            if (completion)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completion(0, taskResp.httpsURL);
                                });
                            }
                        }
                        else
                        {
                            DebugLog(@"upload image failed, code:%d, msg:%@", taskResp.retCode, taskResp.descMsg);
                            if (completion)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completion(-30004, nil);
                                });
                            }
                        }
                    };
                    _cosClient.progressHandler = nil;
                    [_cosClient putObject:task];
                }
                else
                {
                    if (completion)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(errCode, nil);
                        });
                    }
                }
            }];
            
            
        }
        else
        {
            if (completion)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(-30002, nil);
                });
            }

        }
    });
    
}

- (void)getCOSSign:(void (^)(int errCode, NSString* strSign))handler
{
    NSDictionary* dictParam = @{@"Action" : @"GetCOSSign"};
    [TCUtil asyncSendHttpRequest:dictParam handler:^(int result, NSDictionary *resultDict) {
        if (result != 0)
        {
            DebugLog(@"getCOSSign failed");
            handler(result, nil);
        }
        else
        {
            NSString* strSign = nil;
            if (resultDict && [resultDict objectForKey:@"sign"])
            {
                strSign = resultDict[@"sign"];
            }
            handler(result, strSign);
        }
    }];
}

@end
