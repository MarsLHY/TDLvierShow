//
//  TCUtil.m
//  TCLVBIMDemo
//
//  Created by felixlin on 16/8/2.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCUtil.h"
#import "TCConstants.h"

@implementation TCUtil

+ (NSData *)dictionary2JsonData:(NSDictionary *)dict
{
    // 转成Json数据
    if ([NSJSONSerialization isValidJSONObject:dict])
    {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        if(error)
        {
            DebugLog(@"[%@] Post Json Error", [self class]);
        }
        return data;
    }
    else
    {
        DebugLog(@"[%@] Post Json is not valid", [self class]);
    }
    return nil;
}

+ (NSDictionary *)jsonData2Dictionary:(NSString *)jsonData
{
    if (jsonData == nil) {
        return nil;
    }
    NSData *data = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        DebugLog(@"Json parse failed: %@", jsonData);
        return nil;
    }
    return dic;
}

+ (NSString *)getFileCachePath:(NSString *)fileName
{
    if (nil == fileName)
    {
        return nil;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    
    NSString *fileFullPath = [cacheDirectory stringByAppendingPathComponent:fileName];
    return fileFullPath;
}


//通过分别计算中文和其他字符来计算长度
+ (NSUInteger)getContentLength:(NSString*)content
{
    size_t length = 0;
    for (int i = 0; i < [content length]; i++)
    {
        unichar ch = [content characterAtIndex:i];
        if (0x4e00 < ch  && ch < 0x9fff)
        {
            length += 2;
        }
        else
        {
            length++;
        }
    }
    
    return length;
}

+ (void)asyncSendHttpRequest:(NSDictionary*)param handler:(void (^)(int result, NSDictionary* resultDict))handler
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData* data = [TCUtil dictionary2JsonData:param];
        if (data == nil)
        {
            DebugLog(@"sendHttpRequest failed，参数转成json格式失败");
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(kError_ConvertJsonFailed, nil);
            });
            return;
        }
        
        NSMutableString *strUrl = [[NSMutableString alloc] initWithString:kHttpServerAddr];
        
        NSURL *URL = [NSURL URLWithString:strUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        
        if (data)
        {
            [request setValue:[NSString stringWithFormat:@"%ld",(long)[data length]] forHTTPHeaderField:@"Content-Length"];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
            [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
            
            [request setHTTPBody:data];
        }
        
        [request setTimeoutInterval:kHttpTimeout];
        
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != nil)
            {
                DebugLog(@"internalSendRequest failed，NSURLSessionDataTask return error code:%d, des:%@", [error code], [error description]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(kError_HttpError, nil);
                });
            }
            else
            {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary* resultDict = [TCUtil jsonData2Dictionary:responseString];
                int errCode = -1;
                NSDictionary* dataDict = nil;
                if (resultDict)
                {
                    if (resultDict[@"returnValue"])
                        errCode = [resultDict[@"returnValue"] intValue];
                    
                    if (0 == errCode && resultDict[@"returnData"])
                    {
                        dataDict = resultDict[@"returnData"];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(errCode, dataDict);
                });
            }
        }];
        
        [task resume];
    });
}

+ (NSString *)transImageURL2HttpsURL:(NSString *)httpURL
{
    NSString * httpsURL = httpURL;
    if ([httpURL hasPrefix:@"http:"]) {
        httpsURL = [httpURL stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    }
    return httpsURL;
}

+(NSString*) getStreamIDByStreamUrl:(NSString*) strStreamUrl {
    if (strStreamUrl == nil || strStreamUrl.length == 0) {
        return nil;
    }
    
    strStreamUrl = [strStreamUrl lowercaseString];
    
    //推流地址格式：rtmp://8888.livepush.myqcloud.com/live/8888_test_12345_test?txSecret=aaaa&txTime=bbbb
    NSString * strLive = @"/live/";
    NSRange range = [strStreamUrl rangeOfString:strLive];
    if (range.location == NSNotFound) {
        return nil;
    }
    
    NSString * strSubString = [strStreamUrl substringFromIndex:range.location + range.length];
    NSArray * array = [strSubString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?."]];
    if ([array count] > 0) {
        return [array objectAtIndex:0];
    }
    
    return nil;
}

@end


@implementation TCFrequeControl
{
    NSInteger                _countsLimit;
    NSInteger                _curCounts;
    NSTimeInterval           _secondsLimit;
    NSTimeInterval           _preTime;
}

- (instancetype)initWithCounts:(NSInteger)counts andSeconds:(NSTimeInterval)seconds {
    if (self = [super init]) {
        _countsLimit = counts;
        _secondsLimit = seconds;
        _curCounts = 0;
        _preTime = 0;
    }
    return self;
}

- (BOOL)canTrigger {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    if (_preTime == 0 || time - _preTime > _secondsLimit) {
        _preTime = time;
        _curCounts = 0;
    }
    if (_curCounts >= _countsLimit) {
        return NO;
    }
    _curCounts += 1;
        
    return YES;
}

@end



@implementation TCLivePushListenerImpl
-(void) onPushEvent:(int)evtID withParam:(NSDictionary*)param {
    if (self.delegate) {
        [self.delegate onLivePushEvent:self.pushUrl withEvtID:evtID andParam:param];
    }
}

-(void) onNetStatus:(NSDictionary*) param {
    if (self.delegate) {
        [self.delegate onLivePushNetStatus:self.pushUrl withParam:param];
    }
}
@end


@implementation TCLivePlayListenerImpl
-(void) onPlayEvent:(int)evtID withParam:(NSDictionary*)param {
    if (self.delegate) {
        [self.delegate onLivePlayEvent:self.playUrl withEvtID:evtID andParam:param];
    }
}

-(void) onNetStatus:(NSDictionary*) param {
    if (self.delegate) {
        [self.delegate onLivePlayNetStatus:self.playUrl withParam:param];
    }
}
@end

