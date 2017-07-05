//
//  TCPusherModel.h
//  TCLVBIMDemo
//
//  Created by felixlin on 16/8/2.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TCLiveStatus)
{
    TCLiveStatus_Online              = 0,
    TCLiveStatus_Offline             = 1,
};

typedef void (^RequestPusherUrlHandler)(int errCode, NSString* pusherUrl, NSInteger timestamp);

typedef void (^RequestLinkMicPusherUrlHandler)(int errCode, NSString* pusherUrl, NSInteger timestamp, NSString* playUrl);

typedef void (^PusherMgrCompleteHandler)(int errCode);

/**
 * 推流端逻辑层相关代码，主要是与业务Server进行协议通信
 */
@interface TCPusherModel : NSObject
{
}

@property(nonatomic, copy) NSString* userId;
@property(nonatomic, copy) NSString* groupId;

+ (instancetype)sharedInstance;

/**
 *  向业务Server提交推流端的信息并从业务Server获取推流地址
 *
 *  @param userId   用户id
 *  @param title    推流的标题
 *  @param coverPic 封面url
 *  @param nickName 昵称
 *  @param headPic  头像url
 *  @param location 地理位置
 *  @param handler  完成的回调
 */
- (void) getPusherUrl:(NSString*)userId groupId:(NSString*)groupId title:(NSString*)title coverPic:(NSString*)coverPic nickName:(NSString*)nickName headPic:(NSString*)headPic location:(NSString*)location handler:(RequestPusherUrlHandler)handler;


/**
 *  连麦观众向业务Server提交推流端的信息并从业务Server获取推流地址
 *
 *  @param userId   用户id
 *  @param title    推流的标题
 *  @param coverPic 封面url
 *  @param nickName 昵称
 *  @param headPic  头像url
 *  @param location 地理位置
 *  @param handler  完成的回调
 */
- (void) getPushUrlForLinkMic:(NSString*)userId title:(NSString*)title coverPic:(NSString*)coverPic nickName:(NSString*)nickName headPic:(NSString*)headPic location:(NSString*)location handler:(RequestLinkMicPusherUrlHandler)handler;

/**
 *  修改状态，主播推流成功后（收到推流成功的事件），需要向业务Server发送上线的请求，观众端拉取列表的时候就能拉到该主播；
 *  主播停止推流后，向业务Server发送下线请求，观众端刷新列表时，该主播将不会再出现在live列表中
 *
 *  @param userId  用户id
 *  @param status  上线or下线
 *  @param handler 完成的回调
 */
- (void) changeLiveStatus:(NSString*)userId status:(TCLiveStatus)status handler:(PusherMgrCompleteHandler)handler;


@end
