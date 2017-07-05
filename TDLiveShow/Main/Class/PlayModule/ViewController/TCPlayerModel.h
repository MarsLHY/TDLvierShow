//
//  TCPlayerModel.h
//  TCLVBIMDemo
//
//  Created by felixlin on 16/8/3.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCLiveListModel.h"

@interface TCGroupMemberInfo : NSObject
@property NSString *userid;
@property NSString *nickname;
@property NSString *headpic;

@end

/**
 * 播放端逻辑层相关代码，主要是与业务Server进行协议通信
 */

typedef void (^PlayerMgrCompleteHandler)(int errCode);

typedef void (^GetUserInfoHandler)(int result, TCLiveInfo* userInfo);

typedef void (^GetPlayUrlWithSignatureHandler)(int errCode, NSString* strPlayUrl);

typedef NS_ENUM(NSInteger, TCLiveListItemType)
{
    TCLiveListItemType_Live             = 0,
    TCLiveListItemType_Record           = 1,
    TCLiveListItemType_UGC              = 2,
};

@interface TCPlayerModel : NSObject
{
}

+ (instancetype)sharedInstance;

/**
 *  通知业务Server有人点赞，业务Server的该视频点赞数+1
 *
 *  @param userId
 *  @param handler 完成时回调
 */
- (void)giveLike:(NSString*)userId handler:(PlayerMgrCompleteHandler)handler;

/**
 *  获取主播详细信息
 *
 *  @param type    直播/点播
 *  @param userId
 *  @param fileId  文件id，直播时填nil，点播时填拉列表所返回的fileId
 *  @param handler 完成时回调
 *  此接口目前只要用于更新在线人数和点赞数量，由于后台的视频的在线人数和点赞数量一直在变化，所以需要在用户点击播放按钮后，调用此接口
 *  查询最新的数据后，调用TCLiveListMgr中的update接口更新在线人数和点赞数量
 */
- (void)getUserInfo:(TCLiveListItemType)type userId:(NSString*)userId fileId:(NSString*)fileId handler:(GetUserInfoHandler)handler;

/**
 *  举报主播
 *
 *  @param userId     被举报人的用户id
 *  @param hostUserId 举报人的用户id
 *  @param handler    完成时回调
 */
- (void)reportUser:(NSString*)userId hostUserId:(NSString*)hostUserId handler:(PlayerMgrCompleteHandler)handler;

/**
 *  通知业务服务器有群成员进入（由于imsdk的群列表功能无法实现定制化的功能，如按等级排序，故由业务服务器维护群成员列表）
 *
 */
- (void)enterGroup:(NSString*)userId type:(int)type liveUserId:(NSString*)liveUserId groupId:(NSString*)groupId nickName:(NSString*)nickName headPic:(NSString*)headPic handler:(PlayerMgrCompleteHandler)handler;

/**
 *  通知业务服务器有群成员退出（由于imsdk的群列表功能无法实现定制化的功能，如按等级排序，故由业务服务器维护群成员列表）
 *
 */
- (void)quitGroup:(NSString*)userId type:(int)type liveUserId:(NSString*)liveUserId groupId:(NSString*)groupId handler:(PlayerMgrCompleteHandler)handler;

/**
 *  从业务服务器拉取群成员列表（由于imsdk的群列表功能无法实现定制化的功能，如按等级排序，故由业务服务器维护群成员列表）
 *
 */
- (void)fetchGroupMemberList:(NSString*)liveUserId groupId:(NSString*)groupId handler:(void(^)(int errCode, int memberCount, NSArray* memberList))handler;

/**
 * 获取带防盗链签名的拉流地址：主播和连麦观众在拉取对方的视频流时，必须带上防盗链签名
 * @param userId 用户ID
 * @param strPlayUrl 原始拉流地址（未带防盗链签名）
 */
- (void)getPlayUrlWithSignature: (NSString*)userID originPlayUrl:(NSString*) strPlayUrl handler:(GetPlayUrlWithSignatureHandler)handler;
@end
