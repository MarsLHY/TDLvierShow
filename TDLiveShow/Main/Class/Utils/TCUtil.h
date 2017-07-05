//
//  TCUtil.h
//  TCLVBIMDemo
//
//  Created by felixlin on 16/8/2.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCLog.h"
#import "TCConstants.h"
#import "TXRTMPSDK/TXLivePush.h"
#import "TXRTMPSDK/TXLivePlayer.h"

@interface TCUtil : NSObject

+ (NSData *)dictionary2JsonData:(NSDictionary *)dict;

+ (NSDictionary *)jsonData2Dictionary:(NSString *)jsonData;

+ (NSString *)getFileCachePath:(NSString *)fileName;

+ (NSUInteger)getContentLength:(NSString*)string;

+ (void)asyncSendHttpRequest:(NSDictionary*)param handler:(void (^)(int result, NSDictionary* resultDict))handler;

+ (NSString *)transImageURL2HttpsURL:(NSString *)httpURL;

+(NSString*) getStreamIDByStreamUrl:(NSString*) strStreamUrl;
@end


// 频率控制类，如果频率没有超过 nCounts次/nSeconds秒，canTrigger将返回true
@interface TCFrequeControl : NSObject

- (instancetype)initWithCounts:(NSInteger)counts andSeconds:(NSTimeInterval)seconds;
- (BOOL)canTrigger;

@end


// 日志
#ifdef DEBUG

#ifndef DebugLog
//#define DebugLog(fmt, ...) NSLog((@"[%s Line %d]" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define DebugLog(fmt, ...) [[TCLog shareInstance] log:fmt, ##__VA_ARGS__]
#endif

#else

#ifndef DebugLog
#define DebugLog(fmt, ...)  [[TCLog shareInstance] log:fmt, ##__VA_ARGS__]
#endif
#endif

#ifndef TC_PROTECT_STR
#define TC_PROTECT_STR(x) (x == nil ? @"" : x)
#endif


// ITCLivePushListener
@protocol ITCLivePushListener <NSObject>
@optional
-(void)onLivePushEvent:(NSString*) pushUrl withEvtID:(int)evtID andParam:(NSDictionary*)param;

@optional
-(void)onLivePushNetStatus:(NSString*) pushUrl withParam: (NSDictionary*) param;
@end


// TXLivePushListenerImpl
@interface TCLivePushListenerImpl: NSObject<TXLivePushListener>
@property (nonatomic, strong) NSString*   pushUrl;
@property (nonatomic, weak) id<ITCLivePushListener> delegate;
@end



// ITCLivePlayListener
@protocol ITCLivePlayListener <NSObject>
@optional
-(void)onLivePlayEvent:(NSString*) playUrl withEvtID:(int)evtID andParam:(NSDictionary*)param;

@optional
-(void)onLivePlayNetStatus:(NSString*) playUrl withParam: (NSDictionary*) param;
@end



// TXLivePlayListenerImpl
@interface TCLivePlayListenerImpl: NSObject<TXLivePlayListener>
@property (nonatomic, strong) NSString*   playUrl;
@property (nonatomic, weak) id<ITCLivePlayListener> delegate;
@end
